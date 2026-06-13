//
//  PriceRecord.swift
//  GameRec
//
//  游戏价格记录
//

import Foundation

/// 游戏价格快照（含折扣信息）
struct PriceRecord: Codable, Identifiable {
    let id: String  // "\(gameId)_\(platform.rawValue)"
    let gameId: String
    let platform: Platform
    let originalPrice: Double  // 原价（CNY）
    let currentPrice: Double  // 当前价格（CNY）
    let discountPercentage: Int  // 折扣百分比（0-100，0表示无折扣）
    let isFree: Bool  // 是否免费游戏
    let lastUpdated: Date  // 价格更新时间
    
    // MARK: - 初始化
    init(
        gameId: String,
        platform: Platform,
        originalPrice: Double,
        currentPrice: Double,
        discountPercentage: Int = 0,
        isFree: Bool = false,
        lastUpdated: Date = Date()
    ) {
        self.id = "\(gameId)_\(platform.rawValue)"
        self.gameId = gameId
        self.platform = platform
        self.originalPrice = originalPrice
        self.currentPrice = currentPrice
        self.discountPercentage = min(100, max(0, discountPercentage))
        self.isFree = isFree
        self.lastUpdated = lastUpdated
    }
    
    // MARK: - 计算属性
    
    /// 是否正在打折
    var isOnSale: Bool {
        return discountPercentage > 0 && !isFree
    }
    
    /// 节省的金额
    var savedAmount: Double {
        return originalPrice - currentPrice
    }
    
    /// 价格友好度评分（0-10）
    /// 免费=10，大折扣>小折扣>低价>高价
    var priceFriendlinessScore: Double {
        if isFree {
            return 10.0
        }
        
        // 折扣分（最高5分）
        let discountScore = Double(discountPercentage) / 100.0 * 5.0
        
        // 价格分（最高5分，价格越低分数越高）
        // 100元以下=5分，200元=3分，300元以上=1分
        let priceScore: Double
        if currentPrice <= 100 {
            priceScore = 5.0
        } else if currentPrice <= 200 {
            priceScore = 4.0 - (currentPrice - 100) / 100.0
        } else if currentPrice <= 300 {
            priceScore = 3.0 - (currentPrice - 200) / 100.0
        } else {
            priceScore = max(1.0, 2.0 - (currentPrice - 300) / 200.0)
        }
        
        return discountScore + priceScore
    }
    
    /// 格式化价格字符串
    var formattedPrice: String {
        if isFree {
            return "免费"
        }
        return String(format: "¥%.0f", currentPrice)
    }
    
    /// 格式化折扣字符串
    var formattedDiscount: String? {
        guard isOnSale else { return nil }
        return "-\(discountPercentage)%"
    }
}

// MARK: - Mock Data
extension PriceRecord {
    static let preview = PriceRecord(
        gameId: "game_001",
        platform: .steam,
        originalPrice: 298.0,
        currentPrice: 178.8,
        discountPercentage: 40
    )
    
    static let previewList: [PriceRecord] = [
        preview,
        PriceRecord(
            gameId: "game_002",
            platform: .psn,
            originalPrice: 468.0,
            currentPrice: 468.0,
            discountPercentage: 0
        ),
        PriceRecord(
            gameId: "game_003",
            platform: .steam,
            originalPrice: 0.0,
            currentPrice: 0.0,
            isFree: true
        )
    ]
}
