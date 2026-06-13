//
//  GameCategory.swift
//  GameRec
//
//  游戏类别枚举
//

import Foundation

/// 游戏类别
enum GameCategory: String, Codable, CaseIterable {
    case rpg = "RPG"
    case actionRPG = "动作RPG"
    case roguelike = "Roguelike"
    case roguelite = "Roguelite"
    case metroidvania = "银河恶魔城"
    case shooter = "射击"
    case fps = "第一人称射击"
    case tps = "第三人称射击"
    case action = "动作"
    case adventure = "冒险"
    case puzzle = "解谜"
    case platformer = "平台跳跃"
    case fighting = "格斗"
    case racing = "赛车"
    case sports = "体育"
    case simulation = "模拟"
    case strategy = "策略"
    case moba = "MOBA"
    case mmo = "MMO"
    case sandbox = "沙盒"
    case survival = "生存"
    case horror = "恐怖"
    case stealth = "潜行"
    case rhythm = "音乐节奏"
    case visualNovel = "Galgame"
    case cardGame = "卡牌"
    case indie = "独立游戏"
    case openWorld = "开放世界"
    case soulLike = "魂系"
    
    var displayName: String {
        return self.rawValue
    }
    
    /// 类别的推荐优先级权重基数（可被用户偏好覆盖）
    var baseWeight: Double {
        switch self {
        case .rpg, .actionRPG, .openWorld:
            return 1.2  // 热门类别
        case .visualNovel, .indie:
            return 1.0  // 中等
        default:
            return 1.1
        }
    }
}
