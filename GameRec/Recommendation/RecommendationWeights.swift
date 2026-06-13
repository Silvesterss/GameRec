//
//  RecommendationWeights.swift
//  GameRec
//
//  推荐算法权重配置（可调）
//

import Foundation

/// 推荐算法权重配置
struct RecommendationWeights {
    
    // MARK: - 类别推荐权重（第一层）
    
    /// α - 用户偏好强度权重
    /// 基于用户已玩该类别游戏的时长和投入度
    var categoryPreferenceWeight: Double = 0.5
    
    /// β - 未覆盖度权重
    /// 该类别中用户未玩过的游戏占比
    var categoryUncoveredWeight: Double = 0.3
    
    /// γ - 价格友好度权重
    /// 该类别游戏的平均价格友好度
    var categoryPriceWeight: Double = 0.2
    
    // MARK: - 游戏推荐权重（第二层）
    
    /// δ - 内容相似度权重
    /// 基于标签与用户已玩游戏的相似度
    var gameSimilarityWeight: Double = 0.6
    
    /// ε - 价格友好度权重
    /// 该游戏的价格友好度评分
    var gamePriceWeight: Double = 0.2
    
    /// ζ - 多样性惩罚权重
    /// 避免推荐过于相似的游戏
    var gameDiversityPenalty: Double = 0.2
    
    // MARK: - 其他参数
    
    /// 相似度计算的最小标签重叠数（低于此值相似度为0）
    var minTagOverlap: Int = 1
    
    /// "深度游玩"的权重加成（用于偏好强度计算）
    var deepEngagementBonus: Double = 1.5
    
    /// "已完成"的权重加成
    var completedBonus: Double = 2.0
    
    // MARK: - 预设配置
    
    /// 默认配置（均衡）
    static let `default` = RecommendationWeights()
    
    /// 重视价格的配置
    static let priceFocused = RecommendationWeights(
        categoryPreferenceWeight: 0.4,
        categoryUncoveredWeight: 0.2,
        categoryPriceWeight: 0.4,
        gameSimilarityWeight: 0.5,
        gamePriceWeight: 0.4,
        gameDiversityPenalty: 0.1
    )
    
    /// 重视相似度的配置（内容为王）
    static let similarityFocused = RecommendationWeights(
        categoryPreferenceWeight: 0.6,
        categoryUncoveredWeight: 0.3,
        categoryPriceWeight: 0.1,
        gameSimilarityWeight: 0.7,
        gamePriceWeight: 0.1,
        gameDiversityPenalty: 0.2
    )
    
    /// 探索新类别的配置
    static let explorationFocused = RecommendationWeights(
        categoryPreferenceWeight: 0.3,
        categoryUncoveredWeight: 0.5,
        categoryPriceWeight: 0.2,
        gameSimilarityWeight: 0.5,
        gamePriceWeight: 0.2,
        gameDiversityPenalty: 0.3
    )
    
    // MARK: - 验证
    
    /// 验证权重配置是否合理
    var isValid: Bool {
        let categorySum = categoryPreferenceWeight + categoryUncoveredWeight + categoryPriceWeight
        let gameSum = gameSimilarityWeight + gamePriceWeight + gameDiversityPenalty
        
        // 权重和应该接近1.0（允许±0.1误差）
        let categoryValid = abs(categorySum - 1.0) < 0.1
        let gameValid = abs(gameSum - 1.0) < 0.1
        
        // 所有权重应该非负
        let allPositive = [
            categoryPreferenceWeight,
            categoryUncoveredWeight,
            categoryPriceWeight,
            gameSimilarityWeight,
            gamePriceWeight,
            gameDiversityPenalty
        ].allSatisfy { $0 >= 0 }
        
        return categoryValid && gameValid && allPositive
    }
    
    /// 归一化权重（使权重和为1.0）
    mutating func normalize() {
        // 归一化类别权重
        let categorySum = categoryPreferenceWeight + categoryUncoveredWeight + categoryPriceWeight
        if categorySum > 0 {
            categoryPreferenceWeight /= categorySum
            categoryUncoveredWeight /= categorySum
            categoryPriceWeight /= categorySum
        }
        
        // 归一化游戏权重
        let gameSum = gameSimilarityWeight + gamePriceWeight + gameDiversityPenalty
        if gameSum > 0 {
            gameSimilarityWeight /= gameSum
            gamePriceWeight /= gameSum
            gameDiversityPenalty /= gameSum
        }
    }
}

// MARK: - Codable（支持保存用户自定义配置）

extension RecommendationWeights: Codable {
    enum CodingKeys: String, CodingKey {
        case categoryPreferenceWeight
        case categoryUncoveredWeight
        case categoryPriceWeight
        case gameSimilarityWeight
        case gamePriceWeight
        case gameDiversityPenalty
        case minTagOverlap
        case deepEngagementBonus
        case completedBonus
    }
}

// MARK: - CustomStringConvertible

extension RecommendationWeights: CustomStringConvertible {
    var description: String {
        """
        RecommendationWeights:
          类别推荐:
            - 偏好强度: \(categoryPreferenceWeight)
            - 未覆盖度: \(categoryUncoveredWeight)
            - 价格友好: \(categoryPriceWeight)
          游戏推荐:
            - 内容相似: \(gameSimilarityWeight)
            - 价格友好: \(gamePriceWeight)
            - 多样性: \(gameDiversityPenalty)
        """
    }
}
