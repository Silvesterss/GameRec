//
//  Platform.swift
//  GameRec
//
//  游戏平台枚举
//

import Foundation

/// 支持的游戏平台
enum Platform: String, Codable, CaseIterable {
    case psn = "PSN"
    case steam = "Steam"
    case nintendoSwitch = "Switch"
    
    var displayName: String {
        return self.rawValue
    }
    
    var iconName: String {
        switch self {
        case .psn:
            return "playstation.logo"
        case .steam:
            return "gear.circle"
        case .nintendoSwitch:
            return "gamecontroller"
        }
    }
}
