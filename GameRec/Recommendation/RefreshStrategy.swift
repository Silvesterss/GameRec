//
//  RefreshStrategy.swift
//  GameRec
//
//  "换一批"策略管理
//

import Foundation

/// 刷新策略管理器
// 标记为 final：使 Codable 的 init(from:) 可在扩展中自动合成（非 final 类无法在扩展里合成 required 初始化器）
final class RefreshStrategy {
    
    // MARK: - 种子管理
    
    private var categorySeed: Int = 0
    private var gameSeed: Int = 0
    
    /// 重置所有种子
    func resetAll() {
        categorySeed = 0
        gameSeed = 0
    }
    
    /// 重置类别种子
    func resetCategorySeed() {
        categorySeed = 0
    }
    
    /// 重置游戏种子
    func resetGameSeed() {
        gameSeed = 0
    }
    
    // MARK: - 类别刷新
    
    /// 获取下一个类别推荐种子（用于"换一批"）
    func nextCategorySeed() -> Int {
        categorySeed += 1
        return categorySeed
    }
    
    /// 获取当前类别种子
    func currentCategorySeed() -> Int {
        return categorySeed
    }
    
    // MARK: - 游戏刷新
    
    /// 获取下一个游戏推荐种子（用于"换一批"）
    func nextGameSeed() -> Int {
        gameSeed += 1
        return gameSeed
    }
    
    /// 获取当前游戏种子
    func currentGameSeed() -> Int {
        return gameSeed
    }
    
    // MARK: - 智能刷新
    
    /// 智能决定是否需要刷新类别
    /// 规则：如果游戏已经刷新3次还没找到满意的，建议换类别
    func shouldRefreshCategory() -> Bool {
        return gameSeed >= 3
    }
    
    /// 当选择新类别时，重置游戏种子
    func onCategoryChanged() {
        gameSeed = 0
    }
}

// MARK: - Codable（持久化刷新状态）

extension RefreshStrategy: Codable {
    enum CodingKeys: String, CodingKey {
        case categorySeed
        case gameSeed
    }
}
