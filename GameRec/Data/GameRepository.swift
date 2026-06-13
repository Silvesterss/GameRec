//
//  GameRepository.swift
//  GameRec
//
//  游戏库数据访问层
//

import Foundation

/// 游戏库Repository
class GameRepository {
    
    static let shared = GameRepository()
    
    private let dataStore = DataStore.shared
    private let filename = "games"
    
    // MARK: - 缓存
    private var cachedGames: [Game]?
    private var gameCache: [String: Game] = [:]  // 按ID索引
    
    private init() {}
    
    // MARK: - 公共接口
    
    /// 获取所有游戏
    func getAllGames() throws -> [Game] {
        if let cached = cachedGames {
            return cached
        }
        
        let games = try dataStore.loadSeedData([Game].self, filename: filename)
        cachedGames = games
        
        // 建立ID索引
        for game in games {
            gameCache[game.id] = game
        }
        
        return games
    }
    
    /// 根据ID获取单个游戏
    func getGame(by id: String) throws -> Game? {
        // 优先从缓存查找
        if let cached = gameCache[id] {
            return cached
        }
        
        // 缓存未命中，加载所有游戏并重建缓存
        let allGames = try getAllGames()
        return gameCache[id]
    }
    
    /// 根据ID列表批量获取游戏
    func getGames(by ids: [String]) throws -> [Game] {
        let allGames = try getAllGames()
        let idSet = Set(ids)
        return allGames.filter { idSet.contains($0.id) }
    }
    
    /// 根据类别筛选游戏
    func getGames(byCategory category: GameCategory) throws -> [Game] {
        let allGames = try getAllGames()
        return allGames.filter { $0.categories.contains(category) }
    }
    
    /// 根据多个类别筛选游戏（只要包含任一类别）
    func getGames(byCategories categories: [GameCategory]) throws -> [Game] {
        let allGames = try getAllGames()
        let categorySet = Set(categories)
        return allGames.filter { game in
            !Set(game.categories).isDisjoint(with: categorySet)
        }
    }
    
    /// 根据平台筛选游戏
    func getGames(byPlatform platform: Platform) throws -> [Game] {
        let allGames = try getAllGames()
        return allGames.filter { $0.platforms.contains(platform) }
    }
    
    /// 搜索游戏（按标题）
    func searchGames(keyword: String) throws -> [Game] {
        let allGames = try getAllGames()
        let lowercasedKeyword = keyword.lowercased()
        return allGames.filter { $0.title.lowercased().contains(lowercasedKeyword) }
    }
    
    /// 根据标签筛选游戏
    func getGames(byTags tags: [String]) throws -> [Game] {
        let allGames = try getAllGames()
        let tagSet = Set(tags.map { $0.lowercased() })
        
        return allGames.filter { game in
            let gameTags = Set(game.tags.map { $0.lowercased() })
            return !gameTags.isDisjoint(with: tagSet)
        }
    }
    
    /// 获取随机游戏
    func getRandomGames(count: Int) throws -> [Game] {
        let allGames = try getAllGames()
        return Array(allGames.shuffled().prefix(count))
    }
    
    /// 获取指定发行年份范围的游戏
    func getGames(fromYear startYear: Int, toYear endYear: Int) throws -> [Game] {
        let allGames = try getAllGames()
        return allGames.filter { $0.releaseYear >= startYear && $0.releaseYear <= endYear }
    }
    
    // MARK: - 统计信息
    
    /// 获取游戏总数
    func getGameCount() throws -> Int {
        return try getAllGames().count
    }
    
    /// 获取所有类别的游戏数量统计
    func getCategoryStatistics() throws -> [GameCategory: Int] {
        let allGames = try getAllGames()
        var stats: [GameCategory: Int] = [:]
        
        for game in allGames {
            for category in game.categories {
                stats[category, default: 0] += 1
            }
        }
        
        return stats
    }
    
    /// 获取平台游戏数量统计
    func getPlatformStatistics() throws -> [Platform: Int] {
        let allGames = try getAllGames()
        var stats: [Platform: Int] = [:]
        
        for game in allGames {
            for platform in game.platforms {
                stats[platform, default: 0] += 1
            }
        }
        
        return stats
    }
    
    // MARK: - 缓存管理
    
    /// 清空缓存（用于测试或内存警告）
    func clearCache() {
        cachedGames = nil
        gameCache.removeAll()
    }
    
    /// 重新加载数据
    func reload() throws {
        clearCache()
        _ = try getAllGames()
    }
}

// MARK: - 扩展：高级查询

extension GameRepository {
    
    /// 查找相似游戏（基于标签重叠度）
    func findSimilarGames(to game: Game, limit: Int = 10) throws -> [Game] {
        let allGames = try getAllGames()
        let targetTags = game.tagSet
        
        // 计算每个游戏与目标游戏的相似度
        let gamesWithSimilarity = allGames
            .filter { $0.id != game.id }  // 排除自己
            .map { candidate -> (game: Game, similarity: Double) in
                let candidateTags = candidate.tagSet
                let intersection = targetTags.intersection(candidateTags)
                let union = targetTags.union(candidateTags)
                
                // Jaccard相似度
                let similarity = union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
                return (candidate, similarity)
            }
            .filter { $0.similarity > 0 }  // 至少有一个共同标签
            .sorted { $0.similarity > $1.similarity }  // 按相似度降序
        
        return Array(gamesWithSimilarity.prefix(limit)).map { $0.game }
    }
    
    /// 获取指定类别中的热门游戏（按发行年份排序，越新越靠前）
    func getPopularGames(inCategory category: GameCategory, limit: Int = 20) throws -> [Game] {
        let categoryGames = try getGames(byCategory: category)
        return Array(categoryGames.sorted { $0.releaseYear > $1.releaseYear }.prefix(limit))
    }
}
