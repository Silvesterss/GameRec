//
//  FeatureExtractor.swift
//  GameRec
//
//  特征提取器（游戏标签 → 向量特征）
//

import Foundation

/// 特征提取器
class FeatureExtractor {
    
    // MARK: - 标签相似度计算
    
    /// 计算两个游戏之间的Jaccard相似度（基于标签集合）
    static func calculateSimilarity(between game1: Game, and game2: Game) -> Double {
        let tags1 = game1.tagSet
        let tags2 = game2.tagSet
        
        let intersection = tags1.intersection(tags2)
        let union = tags1.union(tags2)
        
        guard !union.isEmpty else { return 0.0 }
        
        return Double(intersection.count) / Double(union.count)
    }
    
    /// 计算游戏与一组游戏的平均相似度
    static func calculateAverageSimilarity(
        game: Game,
        toGames games: [Game],
        weights: [Double]? = nil
    ) -> Double {
        guard !games.isEmpty else { return 0.0 }
        
        if let weights = weights, weights.count == games.count {
            // 加权平均
            var totalSimilarity = 0.0
            var totalWeight = 0.0
            
            for (index, targetGame) in games.enumerated() {
                let similarity = calculateSimilarity(between: game, and: targetGame)
                totalSimilarity += similarity * weights[index]
                totalWeight += weights[index]
            }
            
            return totalWeight > 0 ? totalSimilarity / totalWeight : 0.0
        } else {
            // 简单平均
            let similarities = games.map { calculateSimilarity(between: game, and: $0) }
            return similarities.reduce(0.0, +) / Double(games.count)
        }
    }
    
    // MARK: - 用户偏好提取
    
    /// 从用户游戏记录中提取标签偏好（带权重）
    static func extractUserTagPreferences(
        from userLibrary: [MergedGameRecord],
        games: [Game]
    ) -> [String: Double] {
        var tagScores: [String: Double] = [:]
        
        for record in userLibrary {
            guard let game = games.first(where: { $0.id == record.gameId }) else {
                continue
            }
            
            // 根据投入强度和时长加权
            let weight = record.averageEngagementScore * log(record.totalHoursPlayed + 1)
            
            // 为该游戏的每个标签增加权重
            for tag in game.tags {
                let normalizedTag = tag.lowercased()
                tagScores[normalizedTag, default: 0.0] += weight
            }
        }
        
        return tagScores
    }
    
    /// 提取用户的类别偏好（带权重）
    static func extractCategoryPreferences(
        from userLibrary: [MergedGameRecord],
        games: [Game]
    ) -> [GameCategory: Double] {
        var categoryScores: [GameCategory: Double] = [:]
        
        for record in userLibrary {
            guard let game = games.first(where: { $0.id == record.gameId }) else {
                continue
            }
            
            // 根据投入强度加权
            let weight = record.averageEngagementScore
            
            // 为该游戏的每个类别增加权重
            for category in game.categories {
                categoryScores[category, default: 0.0] += weight
            }
        }
        
        return categoryScores
    }
    
    // MARK: - 类别特征
    
    /// 计算用户对某类别的偏好强度（0-10）
    static func calculateCategoryPreference(
        category: GameCategory,
        userLibrary: [MergedGameRecord],
        games: [Game],
        weights: RecommendationWeights
    ) -> Double {
        // 找出该类别的已玩游戏
        let categoryGameIds = Set(games.filter { $0.categories.contains(category) }.map { $0.id })
        let playedInCategory = userLibrary.filter { categoryGameIds.contains($0.gameId) }
        
        guard !playedInCategory.isEmpty else { return 0.0 }
        
        // 计算偏好强度：基于时长和投入度
        var score = 0.0
        
        for record in playedInCategory {
            var recordScore = record.averageEngagementScore
            
            // 深度游玩加成
            if record.isDeepEngagement {
                recordScore *= weights.deepEngagementBonus
            }
            
            // 已完成加成
            if record.isCompleted {
                recordScore *= weights.completedBonus
            }
            
            score += recordScore
        }
        
        // 归一化到0-10
        return min(score / Double(playedInCategory.count), 10.0)
    }
    
    /// 计算类别的未覆盖度（0-1）
    static func calculateCategoryUncovered(
        category: GameCategory,
        userLibrary: [MergedGameRecord],
        games: [Game]
    ) -> Double {
        let categoryGames = games.filter { $0.categories.contains(category) }
        guard !categoryGames.isEmpty else { return 0.0 }
        
        let playedGameIds = Set(userLibrary.map { $0.gameId })
        let unplayedCount = categoryGames.filter { !playedGameIds.contains($0.id) }.count
        
        return Double(unplayedCount) / Double(categoryGames.count)
    }
}

// MARK: - 多样性计算

extension FeatureExtractor {
    
    /// 计算游戏集合的多样性得分（0-1，越高越多样）
    static func calculateDiversity(games: [Game]) -> Double {
        guard games.count > 1 else { return 1.0 }
        
        // 计算所有游戏对之间的平均相似度
        var totalSimilarity = 0.0
        var pairCount = 0
        
        for i in 0..<games.count {
            for j in (i+1)..<games.count {
                totalSimilarity += calculateSimilarity(between: games[i], and: games[j])
                pairCount += 1
            }
        }
        
        let avgSimilarity = pairCount > 0 ? totalSimilarity / Double(pairCount) : 0.0
        
        // 多样性 = 1 - 相似度
        return 1.0 - avgSimilarity
    }
    
    /// 计算新游戏与已推荐游戏列表的差异度（0-1，越高越不同）
    static func calculateDifference(newGame: Game, from existingGames: [Game]) -> Double {
        guard !existingGames.isEmpty else { return 1.0 }
        
        // 计算与已推荐游戏的平均相似度
        let avgSimilarity = calculateAverageSimilarity(game: newGame, toGames: existingGames)
        
        // 差异度 = 1 - 相似度
        return 1.0 - avgSimilarity
    }
}
