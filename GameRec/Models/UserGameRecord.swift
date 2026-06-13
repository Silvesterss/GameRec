//
//  UserGameRecord.swift
//  GameRec
//
//  用户已玩游戏记录
//

import Foundation

/// 用户在某个平台上玩过的游戏记录
struct UserGameRecord: Codable, Identifiable {
    let id: String  // 唯一ID: "\(gameId)_\(platform.rawValue)"
    let gameId: String  // 对应 Game.id
    let platform: Platform  // 在哪个平台玩的
    let hoursPlayed: Double  // 游戏时长（小时）
    let progressPercentage: Int  // 完成进度（0-100）
    let achievementsUnlocked: Int  // 已解锁成就数
    let totalAchievements: Int  // 总成就数
    let lastPlayedDate: Date?  // 最后游玩时间（可选）
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, gameId, platform, hoursPlayed, progressPercentage
        case achievementsUnlocked, totalAchievements, lastPlayedDate
    }
    
    // MARK: - 初始化
    init(
        gameId: String,
        platform: Platform,
        hoursPlayed: Double,
        progressPercentage: Int,
        achievementsUnlocked: Int,
        totalAchievements: Int,
        lastPlayedDate: Date? = nil
    ) {
        self.id = "\(gameId)_\(platform.rawValue)"
        self.gameId = gameId
        self.platform = platform
        self.hoursPlayed = hoursPlayed
        self.progressPercentage = min(100, max(0, progressPercentage))
        self.achievementsUnlocked = achievementsUnlocked
        self.totalAchievements = totalAchievements
        self.lastPlayedDate = lastPlayedDate
    }
    
    // MARK: - 计算属性
    
    /// 成就完成度（0.0 - 1.0）
    var achievementCompletionRate: Double {
        guard totalAchievements > 0 else { return 0.0 }
        return Double(achievementsUnlocked) / Double(totalAchievements)
    }
    
    /// 是否深度游玩（时长>20小时 或 进度>50%）
    var isDeepEngagement: Bool {
        return hoursPlayed > 20.0 || progressPercentage > 50
    }
    
    /// 是否已完成
    var isCompleted: Bool {
        return progressPercentage >= 100
    }
    
    /// 投入强度评分（0-10）综合时长、进度、成就
    var engagementScore: Double {
        let hourScore = min(hoursPlayed / 50.0, 1.0) * 4.0  // 最高4分
        let progressScore = Double(progressPercentage) / 100.0 * 4.0  // 最高4分
        let achievementScore = achievementCompletionRate * 2.0  // 最高2分
        return hourScore + progressScore + achievementScore
    }
}

// MARK: - Mock Data
extension UserGameRecord {
    static let preview = UserGameRecord(
        gameId: "game_001",
        platform: .steam,
        hoursPlayed: 85.5,
        progressPercentage: 78,
        achievementsUnlocked: 32,
        totalAchievements: 42,
        lastPlayedDate: Date()
    )
    
    static let previewList: [UserGameRecord] = [
        preview,
        UserGameRecord(
            gameId: "game_002",
            platform: .psn,
            hoursPlayed: 120.0,
            progressPercentage: 100,
            achievementsUnlocked: 50,
            totalAchievements: 50,
            lastPlayedDate: Date().addingTimeInterval(-86400 * 30)
        )
    ]
}
