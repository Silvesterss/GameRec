//
//  Game.swift
//  GameRec
//
//  游戏元数据
//

import Foundation

/// 游戏元数据
struct Game: Codable, Identifiable, Equatable {
    let id: String  // 全局唯一ID（如 "game_001"）
    let title: String  // 游戏名称
    let categories: [GameCategory]  // 所属类别（可多个）
    let tags: [String]  // 特征标签（用于相似度计算）
    let description: String  // 简介
    let releaseYear: Int  // 发行年份
    let platforms: [Platform]  // 支持的平台
    let imageURL: String?  // 封面图URL（可选，MVP阶段为空）
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, title, categories, tags, description, releaseYear, platforms, imageURL
    }
    
    // MARK: - Equatable
    static func == (lhs: Game, rhs: Game) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - 计算属性
    
    /// 主类别（取第一个）
    var primaryCategory: GameCategory {
        return categories.first ?? .indie
    }
    
    /// 是否支持指定平台
    func isAvailableOn(_ platform: Platform) -> Bool {
        return platforms.contains(platform)
    }
    
    /// 标签集合（用于相似度计算）
    var tagSet: Set<String> {
        return Set(tags.map { $0.lowercased() })
    }
}

// MARK: - Mock Data（仅用于预览）
extension Game {
    static let preview = Game(
        id: "game_001",
        title: "艾尔登法环",
        categories: [.actionRPG, .openWorld, .soulLike],
        tags: ["开放世界", "魂系", "困难", "探索", "BOSS战"],
        description: "FromSoftware 与《冰与火之歌》作者合作的开放世界魂系游戏",
        releaseYear: 2022,
        platforms: [.psn, .steam],
        imageURL: nil
    )
    
    static let previewList: [Game] = [
        preview,
        Game(
            id: "game_002",
            title: "女神异闻录5 皇家版",
            categories: [.rpg, .visualNovel],
            tags: ["回合制", "剧情向", "学园", "日式RPG"],
            description: "ATLUS经典JRPG系列的集大成之作",
            releaseYear: 2019,
            platforms: [.psn, .steam, .nintendoSwitch],
            imageURL: nil
        )
    ]
}
