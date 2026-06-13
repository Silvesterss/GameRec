//
//  Scorer.swift
//  GameRec
//
//  评分计算器（实现推荐评分公式）
//

import Foundation

/// 推荐评分结果
struct ScoreResult {
    let score: Double  // 最终得分（0-10）
    let reason: String  // 推荐理由（可解释性）
    let components: ScoreComponents  // 评分组成部分
}

/// 评分组成部分（用于调试和展示）
struct ScoreComponents {
    var preference: Double = 0.0
    var uncovered: Double = 0.0
    var price: Double = 0.0
    var similarity: Double = 0.0
    var diversity: Double = 0.0
}

/// 评分计算器
class Scorer {
    
    private let weights: RecommendationWeights
    
    init(weights: RecommendationWeights = .default) {
        self.weights = weights
    }
    
    // MARK: - 类别评分（第一层）
    
    /// 计算类别推荐评分
    /// score = α·偏好强度 + β·未覆盖度 + γ·价格友好度
    func scoreCategoryRecommendation(
        category: GameCategory,
        userLibrary: [MergedGameRecord],
        games: [Game],
        prices: [PriceRecord]
    ) -> ScoreResult {
        
        // 1. 偏好强度（0-10）
        let preference = FeatureExtractor.calculateCategoryPreference(
            category: category,
            userLibrary: userLibrary,
            games: games,
            weights: weights
        )
        
        // 2. 未覆盖度（0-1）→ 归一化到0-10
        let uncovered = FeatureExtractor.calculateCategoryUncovered(
            category: category,
            userLibrary: userLibrary,
            games: games
        ) * 10.0
        
        // 3. 价格友好度（0-10）
        let categoryGames = games.filter { $0.categories.contains(category) }
        let categoryGameIds = categoryGames.map { $0.id }
        let averagePriceFriendliness = calculateAveragePriceFriendliness(
            forGameIds: categoryGameIds,
            prices: prices
        )
        
        // 加权求和
        let finalScore =
            preference * weights.categoryPreferenceWeight +
            uncovered * weights.categoryUncoveredWeight +
            averagePriceFriendliness * weights.categoryPriceWeight
        
        // 生成推荐理由
        let reason = generateCategoryReason(
            category: category,
            preference: preference,
            uncovered: uncovered,
            price: averagePriceFriendliness
        )
        
        let components = ScoreComponents(
            preference: preference,
            uncovered: uncovered,
            price: averagePriceFriendliness
        )
        
        return ScoreResult(score: finalScore, reason: reason, components: components)
    }
    
    // MARK: - 游戏评分（第二层）
    
    /// 计算游戏推荐评分
    /// score = δ·内容相似度 + ε·价格友好度 + ζ·多样性
    func scoreGameRecommendation(
        game: Game,
        userLibrary: [MergedGameRecord],
        allGames: [Game],
        prices: [PriceRecord],
        alreadyRecommended: [Game] = []
    ) -> ScoreResult {
        
        // 1. 内容相似度（0-1）→ 归一化到0-10
        let userPlayedGames = userLibrary.compactMap { record in
            allGames.first(where: { $0.id == record.gameId })
        }
        
        let similarity = FeatureExtractor.calculateAverageSimilarity(
            game: game,
            toGames: userPlayedGames
        ) * 10.0
        
        // 2. 价格友好度（0-10）
        let bestPrice = prices.first(where: { $0.gameId == game.id })
        let priceFriendliness = bestPrice?.priceFriendlinessScore ?? 5.0
        
        // 3. 多样性（0-1）→ 归一化到0-10
        // 如果已有推荐游戏，计算与它们的差异度；否则给满分
        let diversity: Double
        if !alreadyRecommended.isEmpty {
            diversity = FeatureExtractor.calculateDifference(
                newGame: game,
                from: alreadyRecommended
            ) * 10.0
        } else {
            diversity = 10.0
        }
        
        // 加权求和
        let finalScore =
            similarity * weights.gameSimilarityWeight +
            priceFriendliness * weights.gamePriceWeight +
            diversity * weights.gameDiversityPenalty
        
        // 生成推荐理由
        let reason = generateGameReason(
            game: game,
            similarity: similarity,
            price: priceFriendliness,
            bestPrice: bestPrice,
            userPlayedGames: userPlayedGames
        )
        
        let components = ScoreComponents(
            similarity: similarity,
            price: priceFriendliness,
            diversity: diversity
        )
        
        return ScoreResult(score: finalScore, reason: reason, components: components)
    }
    
    // MARK: - 辅助方法
    
    /// 计算游戏列表的平均价格友好度
    private func calculateAveragePriceFriendliness(
        forGameIds gameIds: [String],
        prices: [PriceRecord]
    ) -> Double {
        guard !gameIds.isEmpty else { return 5.0 }
        
        var scores: [Double] = []
        
        for gameId in gameIds {
            // 找到该游戏所有平台的价格，取最优的
            let gamePrices = prices.filter { $0.gameId == gameId }
            if let bestPrice = gamePrices.max(by: { $0.priceFriendlinessScore < $1.priceFriendlinessScore }) {
                scores.append(bestPrice.priceFriendlinessScore)
            }
        }
        
        guard !scores.isEmpty else { return 5.0 }
        return scores.reduce(0.0, +) / Double(scores.count)
    }
    
    // MARK: - 推荐理由生成（可解释性）
    
    /// 生成类别推荐理由
    private func generateCategoryReason(
        category: GameCategory,
        preference: Double,
        uncovered: Double,
        price: Double
    ) -> String {
        var reasons: [String] = []
        
        // 偏好强度
        if preference > 7.0 {
            reasons.append("你深度游玩过这类游戏")
        } else if preference > 3.0 {
            reasons.append("你玩过这类游戏")
        }
        
        // 未覆盖度
        if uncovered > 7.0 {
            reasons.append("还有很多该类游戏未尝试")
        } else if uncovered > 5.0 {
            reasons.append("有不少该类游戏未尝试")
        }
        
        // 价格
        if price > 7.0 {
            reasons.append("该类游戏性价比高")
        } else if price < 3.0 {
            reasons.append("该类游戏价格偏高")
        }
        
        if reasons.isEmpty {
            return "推荐尝试\(category.displayName)类游戏"
        }
        
        return reasons.joined(separator: "，")
    }
    
    /// 生成游戏推荐理由
    private func generateGameReason(
        game: Game,
        similarity: Double,
        price: Double,
        bestPrice: PriceRecord?,
        userPlayedGames: [Game]
    ) -> String {
        var reasons: [String] = []
        
        // 相似度
        if similarity > 7.0 {
            // 找最相似的游戏
            if let mostSimilar = userPlayedGames.max(by: {
                FeatureExtractor.calculateSimilarity(between: game, and: $0) <
                FeatureExtractor.calculateSimilarity(between: game, and: $1)
            }) {
                reasons.append("与你喜欢的《\(mostSimilar.title)》类似")
            } else {
                reasons.append("符合你的游戏偏好")
            }
        }
        
        // 共同标签
        let userTags = Set(userPlayedGames.flatMap { $0.tags.map { $0.lowercased() } })
        let commonTags = game.tagSet.intersection(userTags)
        if commonTags.count >= 3 {
            let tagList = Array(commonTags.prefix(3))
            reasons.append("包含你喜欢的元素：\(tagList.joined(separator: "、"))")
        }
        
        // 价格
        if let bestPrice = bestPrice {
            if bestPrice.isFree {
                reasons.append("免费游戏")
            } else if bestPrice.isOnSale {
                reasons.append("正在打折\(bestPrice.discountPercentage)%")
            } else if price > 7.0 {
                reasons.append("价格实惠")
            }
        }
        
        if reasons.isEmpty {
            return "推荐游戏：\(game.title)"
        }
        
        return reasons.joined(separator: "，")
    }
}
