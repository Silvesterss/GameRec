//
//  CategoryRecommender.swift
//  GameRec
//
//  类别推荐引擎（第一层推荐）
//

import Foundation

/// 类别推荐结果
struct CategoryRecommendation {
    let category: GameCategory
    let score: Double
    let reason: String
    let unplayedGameCount: Int  // 该类别下未玩游戏数
}

/// 类别推荐引擎
class CategoryRecommender {
    
    private let scorer: Scorer
    private let gameRepo: GameRepository
    private let userLibraryRepo: UserLibraryRepository
    private let priceRepo: PriceRepository
    
    init(
        weights: RecommendationWeights = .default,
        gameRepo: GameRepository = .shared,
        userLibraryRepo: UserLibraryRepository = .shared,
        priceRepo: PriceRepository = .shared
    ) {
        self.scorer = Scorer(weights: weights)
        self.gameRepo = gameRepo
        self.userLibraryRepo = userLibraryRepo
        self.priceRepo = priceRepo
    }
    
    // MARK: - 主推荐接口
    
    /// 推荐类别（TopN）
    func recommendCategories(
        topN: Int = 5,
        seed: Int = 0
    ) throws -> [CategoryRecommendation] {
        
        // 1. 加载数据
        let allGames = try gameRepo.getAllGames()
        let userLibrary = try userLibraryRepo.getMergedLibrary()
        let allPrices = try priceRepo.getAllPrices()
        
        // 2. 过滤：只推荐有未玩游戏的类别
        let playedGameIds = Set(userLibrary.map { $0.gameId })
        let categoriesWithUnplayed = GameCategory.allCases.filter { category in
            let categoryGames = allGames.filter { $0.categories.contains(category) }
            let unplayedGames = categoryGames.filter { !playedGameIds.contains($0.id) }
            return !unplayedGames.isEmpty
        }
        
        // 3. 对每个类别评分
        var recommendations: [CategoryRecommendation] = []
        
        for category in categoriesWithUnplayed {
            let scoreResult = scorer.scoreCategoryRecommendation(
                category: category,
                userLibrary: userLibrary,
                games: allGames,
                prices: allPrices
            )
            
            let categoryGames = allGames.filter { $0.categories.contains(category) }
            let unplayedCount = categoryGames.filter { !playedGameIds.contains($0.id) }.count
            
            let recommendation = CategoryRecommendation(
                category: category,
                score: scoreResult.score,
                reason: scoreResult.reason,
                unplayedGameCount: unplayedCount
            )
            
            recommendations.append(recommendation)
        }
        
        // 4. 排序并取TopN
        recommendations.sort { $0.score > $1.score }
        
        // 5. 应用种子偏移（用于"换一批"）
        let offset = seed % max(recommendations.count - topN + 1, 1)
        let endIndex = min(offset + topN, recommendations.count)
        
        return Array(recommendations[offset..<endIndex])
    }
    
    /// 推荐单个类别
    func recommendCategory() throws -> CategoryRecommendation? {
        return try recommendCategories(topN: 1).first
    }
    
    /// 获取用户最偏好的类别（不考虑未覆盖度）
    func getUserTopCategories(topN: Int = 5) throws -> [CategoryRecommendation] {
        let allGames = try gameRepo.getAllGames()
        let userLibrary = try userLibraryRepo.getMergedLibrary()
        
        var categoryPreferences: [GameCategory: Double] = [:]
        
        for category in GameCategory.allCases {
            let preference = FeatureExtractor.calculateCategoryPreference(
                category: category,
                userLibrary: userLibrary,
                games: allGames,
                weights: scorer.weights
            )
            
            if preference > 0 {
                categoryPreferences[category] = preference
            }
        }
        
        let sorted = categoryPreferences.sorted { $0.value > $1.value }
        
        return sorted.prefix(topN).map { category, score in
            CategoryRecommendation(
                category: category,
                score: score,
                reason: "你深度游玩过这类游戏",
                unplayedGameCount: 0
            )
        }
    }
}
