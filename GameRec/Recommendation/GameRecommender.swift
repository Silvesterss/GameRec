//
//  GameRecommender.swift
//  GameRec
//
//  游戏推荐引擎（第二层推荐）
//

import Foundation

/// 游戏推荐结果
struct GameRecommendation {
    let game: Game
    let score: Double
    let reason: String
    let bestPrice: PriceRecord?  // 最优价格
}

/// 游戏推荐引擎
class GameRecommender {
    
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
    
    /// 推荐指定类别的游戏（TopN）
    func recommendGames(
        inCategory category: GameCategory,
        topN: Int = 8,
        seed: Int = 0
    ) throws -> [GameRecommendation] {
        
        // 1. 加载数据
        let allGames = try gameRepo.getAllGames()
        let userLibrary = try userLibraryRepo.getMergedLibrary()
        let allPrices = try priceRepo.getAllPrices()
        
        // 2. 过滤：该类别 + 未玩过
        let playedGameIds = Set(userLibrary.map { $0.gameId })
        let candidateGames = allGames.filter { game in
            game.categories.contains(category) && !playedGameIds.contains(game.id)
        }
        
        guard !candidateGames.isEmpty else {
            return []
        }
        
        // 3. 对每个候选游戏评分
        var recommendations: [GameRecommendation] = []
        var alreadyScored: [Game] = []
        
        for game in candidateGames {
            let scoreResult = scorer.scoreGameRecommendation(
                game: game,
                userLibrary: userLibrary,
                allGames: allGames,
                prices: allPrices,
                alreadyRecommended: alreadyScored
            )
            
            let bestPrice = try? priceRepo.getBestPrice(forGameId: game.id)
            
            let recommendation = GameRecommendation(
                game: game,
                score: scoreResult.score,
                reason: scoreResult.reason,
                bestPrice: bestPrice
            )
            
            recommendations.append(recommendation)
            alreadyScored.append(game)
        }
        
        // 4. 排序并取TopN
        recommendations.sort { $0.score > $1.score }
        
        // 5. 应用种子偏移（用于"换一批"）
        let offset = seed % max(recommendations.count - topN + 1, 1)
        let endIndex = min(offset + topN, recommendations.count)
        
        return Array(recommendations[offset..<endIndex])
    }
    
    /// 推荐单个游戏
    func recommendGame(inCategory category: GameCategory) throws -> GameRecommendation? {
        return try recommendGames(inCategory: category, topN: 1).first
    }
    
    /// 推荐游戏（不限类别，全局推荐）
    func recommendGamesGlobal(
        topN: Int = 10,
        seed: Int = 0
    ) throws -> [GameRecommendation] {
        
        let allGames = try gameRepo.getAllGames()
        let userLibrary = try userLibraryRepo.getMergedLibrary()
        let allPrices = try priceRepo.getAllPrices()
        
        let playedGameIds = Set(userLibrary.map { $0.gameId })
        let candidateGames = allGames.filter { !playedGameIds.contains($0.id) }
        
        guard !candidateGames.isEmpty else {
            return []
        }
        
        var recommendations: [GameRecommendation] = []
        var alreadyScored: [Game] = []
        
        for game in candidateGames {
            let scoreResult = scorer.scoreGameRecommendation(
                game: game,
                userLibrary: userLibrary,
                allGames: allGames,
                prices: allPrices,
                alreadyRecommended: alreadyScored
            )
            
            let bestPrice = try? priceRepo.getBestPrice(forGameId: game.id)
            
            let recommendation = GameRecommendation(
                game: game,
                score: scoreResult.score,
                reason: scoreResult.reason,
                bestPrice: bestPrice
            )
            
            recommendations.append(recommendation)
            alreadyScored.append(game)
        }
        
        recommendations.sort { $0.score > $1.score }
        
        let offset = seed % max(recommendations.count - topN + 1, 1)
        let endIndex = min(offset + topN, recommendations.count)
        
        return Array(recommendations[offset..<endIndex])
    }
    
    // MARK: - 辅助接口
    
    /// 根据游戏ID批量推荐相似游戏
    func findSimilarGames(
        to gameId: String,
        limit: Int = 10
    ) throws -> [GameRecommendation] {
        
        guard let targetGame = try gameRepo.getGame(by: gameId) else {
            return []
        }
        
        let similarGames = try gameRepo.findSimilarGames(to: targetGame, limit: limit * 2)
        let userLibrary = try userLibraryRepo.getMergedLibrary()
        let allGames = try gameRepo.getAllGames()
        let allPrices = try priceRepo.getAllPrices()
        
        var recommendations: [GameRecommendation] = []
        
        for game in similarGames {
            let scoreResult = scorer.scoreGameRecommendation(
                game: game,
                userLibrary: userLibrary,
                allGames: allGames,
                prices: allPrices
            )
            
            let bestPrice = try? priceRepo.getBestPrice(forGameId: game.id)
            
            let recommendation = GameRecommendation(
                game: game,
                score: scoreResult.score,
                reason: "与《\(targetGame.title)》相似",
                bestPrice: bestPrice
            )
            
            recommendations.append(recommendation)
        }
        
        recommendations.sort { $0.score > $1.score }
        return Array(recommendations.prefix(limit))
    }
    
    /// 推荐打折游戏
    func recommendDiscountedGames(
        topN: Int = 10
    ) throws -> [GameRecommendation] {
        
        let allGames = try gameRepo.getAllGames()
        let userLibrary = try userLibraryRepo.getMergedLibrary()
        let discountPrices = try priceRepo.getOnSalePrices()
        
        let playedGameIds = Set(userLibrary.map { $0.gameId })
        let discountGameIds = Set(discountPrices.map { $0.gameId })
        
        let candidateGames = allGames.filter { game in
            discountGameIds.contains(game.id) && !playedGameIds.contains(game.id)
        }
        
        var recommendations: [GameRecommendation] = []
        
        for game in candidateGames {
            let scoreResult = scorer.scoreGameRecommendation(
                game: game,
                userLibrary: userLibrary,
                allGames: allGames,
                prices: discountPrices
            )
            
            let bestPrice = try? priceRepo.getBestPrice(forGameId: game.id)
            
            let recommendation = GameRecommendation(
                game: game,
                score: scoreResult.score,
                reason: scoreResult.reason,
                bestPrice: bestPrice
            )
            
            recommendations.append(recommendation)
        }
        
        recommendations.sort { $0.score > $1.score }
        return Array(recommendations.prefix(topN))
    }
}
