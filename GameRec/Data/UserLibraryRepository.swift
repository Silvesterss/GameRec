//
//  UserLibraryRepository.swift
//  GameRec
//
//  用户游戏库数据访问层（支持多账号合并）
//

import Foundation

/// 用户游戏库Repository
class UserLibraryRepository {
    
    static let shared = UserLibraryRepository()
    
    private let dataStore = DataStore.shared
    private let filename = "user_library.json"
    
    // MARK: - 缓存
    private var cachedRecords: [UserGameRecord]?
    
    private init() {}
    
    // MARK: - 基础CRUD
    
    /// 获取所有用户游戏记录
    func getAllRecords() throws -> [UserGameRecord] {
        if let cached = cachedRecords {
            return cached
        }
        
        // 尝试从用户目录加载
        if dataStore.userDataExists(filename: filename) {
            let records = try dataStore.loadUserData([UserGameRecord].self, filename: filename)
            cachedRecords = records
            return records
        }
        
        // 首次启动，从种子数据加载
        let records = try dataStore.loadSeedData([UserGameRecord].self, filename: "user_library")
        cachedRecords = records
        
        // 保存到用户目录
        try saveRecords(records)
        
        return records
    }
    
    /// 保存所有记录
    private func saveRecords(_ records: [UserGameRecord]) throws {
        try dataStore.saveUserData(records, filename: filename)
        cachedRecords = records
    }
    
    /// 添加游戏记录
    func addRecord(_ record: UserGameRecord) throws {
        var records = try getAllRecords()
        
        // 检查是否已存在（同gameId+platform）
        if let existingIndex = records.firstIndex(where: { $0.id == record.id }) {
            records[existingIndex] = record  // 更新
        } else {
            records.append(record)  // 新增
        }
        
        try saveRecords(records)
    }
    
    /// 批量添加记录
    func addRecords(_ newRecords: [UserGameRecord]) throws {
        var records = try getAllRecords()
        
        for newRecord in newRecords {
            if let existingIndex = records.firstIndex(where: { $0.id == newRecord.id }) {
                records[existingIndex] = newRecord
            } else {
                records.append(newRecord)
            }
        }
        
        try saveRecords(records)
    }
    
    /// 删除游戏记录
    func deleteRecord(id: String) throws {
        var records = try getAllRecords()
        records.removeAll { $0.id == id }
        try saveRecords(records)
    }
    
    /// 更新游戏记录
    func updateRecord(_ record: UserGameRecord) throws {
        try addRecord(record)  // 复用addRecord的更新逻辑
    }
    
    /// 清空所有记录
    func clearAll() throws {
        try saveRecords([])
    }
    
    // MARK: - 查询
    
    /// 根据游戏ID获取记录（可能跨多个平台）
    func getRecords(forGameId gameId: String) throws -> [UserGameRecord] {
        let allRecords = try getAllRecords()
        return allRecords.filter { $0.gameId == gameId }
    }
    
    /// 根据平台获取记录
    func getRecords(forPlatform platform: Platform) throws -> [UserGameRecord] {
        let allRecords = try getAllRecords()
        return allRecords.filter { $0.platform == platform }
    }
    
    /// 检查用户是否玩过某游戏（任意平台）
    func hasPlayed(gameId: String) throws -> Bool {
        let records = try getRecords(forGameId: gameId)
        return !records.isEmpty
    }
    
    /// 获取深度游玩的游戏记录
    func getDeepEngagementRecords() throws -> [UserGameRecord] {
        let allRecords = try getAllRecords()
        return allRecords.filter { $0.isDeepEngagement }
    }
    
    /// 获取已完成的游戏记录
    func getCompletedRecords() throws -> [UserGameRecord] {
        let allRecords = try getAllRecords()
        return allRecords.filter { $0.isCompleted }
    }
    
    /// 获取最近游玩的游戏（按时间排序）
    func getRecentlyPlayedRecords(limit: Int = 10) throws -> [UserGameRecord] {
        let allRecords = try getAllRecords()
        
        let sorted = allRecords
            .filter { $0.lastPlayedDate != nil }
            .sorted { ($0.lastPlayedDate ?? Date.distantPast) > ($1.lastPlayedDate ?? Date.distantPast) }
        
        return Array(sorted.prefix(limit))
    }
    
    // MARK: - 多账号合并逻辑 ⭐核心
    
    /// 合并后的游戏库（同一游戏在多平台的数据合并）
    func getMergedLibrary() throws -> [MergedGameRecord] {
        let allRecords = try getAllRecords()
        
        // 按gameId分组
        var gameGroups: [String: [UserGameRecord]] = [:]
        for record in allRecords {
            gameGroups[record.gameId, default: []].append(record)
        }
        
        // 合并每组
        return gameGroups.map { (gameId, records) in
            mergePlatformRecords(gameId: gameId, records: records)
        }
    }
    
    /// 合并单个游戏的多平台记录
    private func mergePlatformRecords(gameId: String, records: [UserGameRecord]) -> MergedGameRecord {
        // 时长累加
        let totalHours = records.reduce(0.0) { $0 + $1.hoursPlayed }
        
        // 进度取最大值
        let maxProgress = records.map { $0.progressPercentage }.max() ?? 0
        
        // 成就：总数取最大，已解锁取最大
        let maxTotalAchievements = records.map { $0.totalAchievements }.max() ?? 0
        let maxUnlockedAchievements = records.map { $0.achievementsUnlocked }.max() ?? 0
        
        // 最后游玩时间：取最新的
        let lastPlayed = records.compactMap { $0.lastPlayedDate }.max()
        
        // 平台列表
        let platforms = records.map { $0.platform }
        
        // 投入强度评分：取平均值（也可以取最大值）
        let avgEngagement = records.map { $0.engagementScore }.reduce(0.0, +) / Double(records.count)
        
        return MergedGameRecord(
            gameId: gameId,
            platforms: platforms,
            totalHoursPlayed: totalHours,
            maxProgressPercentage: maxProgress,
            maxAchievementsUnlocked: maxUnlockedAchievements,
            totalAchievements: maxTotalAchievements,
            lastPlayedDate: lastPlayed,
            averageEngagementScore: avgEngagement,
            originalRecords: records
        )
    }
    
    /// 获取用户已玩的游戏ID列表（去重）
    func getPlayedGameIds() throws -> Set<String> {
        let allRecords = try getAllRecords()
        return Set(allRecords.map { $0.gameId })
    }
    
    /// 获取用户未玩过的游戏ID（从全部游戏中排除已玩）
    func getUnplayedGameIds(allGameIds: [String]) throws -> Set<String> {
        let playedIds = try getPlayedGameIds()
        return Set(allGameIds).subtracting(playedIds)
    }
    
    // MARK: - 统计信息
    
    /// 获取总游戏时长
    func getTotalPlayTime() throws -> Double {
        let allRecords = try getAllRecords()
        return allRecords.reduce(0.0) { $0 + $1.hoursPlayed }
    }
    
    /// 获取已玩游戏数量（去重）
    func getUniqueGameCount() throws -> Int {
        return try getPlayedGameIds().count
    }
    
    /// 获取平台游戏数量统计
    func getPlatformGameCount() throws -> [Platform: Int] {
        let allRecords = try getAllRecords()
        var stats: [Platform: Int] = [:]
        
        for record in allRecords {
            stats[record.platform, default: 0] += 1
        }
        
        return stats
    }
    
    // MARK: - 缓存管理
    
    /// 清空缓存
    func clearCache() {
        cachedRecords = nil
    }
    
    /// 重新加载
    func reload() throws {
        clearCache()
        _ = try getAllRecords()
    }
}

// MARK: - 合并后的游戏记录

/// 合并后的游戏记录（同一游戏跨平台合并）
struct MergedGameRecord {
    let gameId: String
    let platforms: [Platform]  // 玩过的平台列表
    let totalHoursPlayed: Double  // 累加时长
    let maxProgressPercentage: Int  // 最大进度
    let maxAchievementsUnlocked: Int  // 最大已解锁成就
    let totalAchievements: Int  // 总成就数（取最大）
    let lastPlayedDate: Date?  // 最后游玩时间（最新）
    let averageEngagementScore: Double  // 平均投入强度评分
    let originalRecords: [UserGameRecord]  // 原始记录列表
    
    /// 是否已完成
    var isCompleted: Bool {
        return maxProgressPercentage >= 100
    }
    
    /// 是否深度游玩
    var isDeepEngagement: Bool {
        return totalHoursPlayed > 20.0 || maxProgressPercentage > 50
    }
    
    /// 成就完成度
    var achievementCompletionRate: Double {
        guard totalAchievements > 0 else { return 0.0 }
        return Double(maxAchievementsUnlocked) / Double(totalAchievements)
    }
}
