//
//  Account.swift
//  GameRec
//
//  账号模型：App 用户 + 绑定的平台账号
//

import Foundation

/// App 用户账号（本地账号系统）
struct UserAccount: Codable, Identifiable {
    let id: String          // 用户唯一 ID
    var username: String    // 用户名
    var email: String       // 邮箱
    var password: String    // 仅本地 demo 存储，生产环境必须加盐哈希后由后端管理
    let createdAt: Date

    init(username: String, email: String, password: String) {
        self.id = UUID().uuidString
        self.username = username
        self.email = email
        self.password = password
        self.createdAt = Date()
    }
}

/// 绑定的平台账号（一个用户可绑定多平台、每平台多个账号）
struct PlatformAccount: Codable, Identifiable {
    let id: String          // "\(platform)_\(accountName)"
    let platform: Platform  // 所属平台
    var accountName: String // 平台账号名（如 Steam ID）
    let boundAt: Date       // 绑定时间

    init(platform: Platform, accountName: String) {
        self.id = "\(platform.rawValue)_\(accountName)"
        self.platform = platform
        self.accountName = accountName
        self.boundAt = Date()
    }
}
