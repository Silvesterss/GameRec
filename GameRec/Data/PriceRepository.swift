//
//  PriceRepository.swift
//  GameRec
//
//  价格数据访问层
//

import Foundation

/// 价格Repository
class PriceRepository {
    
    static let shared = PriceRepository()
    
    private let dataStore = DataStore.shared
    private let filename = "prices"
    
    // MARK: - 缓存
    private var cachedPrices: [PriceRecord]?
    private var priceCache: [String: PriceRecord] = [:]  // 按ID索引
    
    private init() {}
    
    // MARK: - 基础查询
    
    /// 获取所有价格记录
    func getAllPrices() throws -> [PriceRecord] {
        if let cached = cachedPrices {
            return cached
        }
        
        let prices = try dataStore.loadSeedData([PriceRecord].self, filename: filename)
        cachedPrices = prices
        
        // 建立ID索引
        for price in prices {
            priceCache[price.id] = price
        }
        
        return prices
    }
    
    /// 根据ID获取单条价格记录
    func getPrice(by id: String) throws -> PriceRecord? {
        if let cached = priceCache[id] {
            return cached
        }
        
        _ = try getAllPrices()
        return priceCache[id]
    }
    
    /// 根据游戏ID和平台获取价格
    func getPrice(gameId: String, platform: Platform) throws -> PriceRecord? {
        let id = "\(gameId)_\(platform.rawValue)"
        return try getPrice(by: id)
    }
    
    /// 获取某游戏在所有平台的价格
    func getPrices(forGameId gameId: String) throws -> [PriceRecord] {
        let allPrices = try getAllPrices()
        return allPrices.filter { $0.gameId == gameId }
    }
    
    /// 批量获取游戏价格（按游戏ID列表）
    func getPrices(forGameIds gameIds: [String]) throws -> [PriceRecord] {
        let allPrices = try getAllPrices()
        let idSet = Set(gameIds)
        return allPrices.filter { idSet.contains($0.gameId) }
    }
    
    /// 获取某平台的所有价格
    func getPrices(forPlatform platform: Platform) throws -> [PriceRecord] {
        let allPrices = try getAllPrices()
        return allPrices.filter { $0.platform == platform }
    }
    
    // MARK: - 折扣相关
    
    /// 获取所有打折游戏
    func getOnSalePrices() throws -> [PriceRecord] {
        let allPrices = try getAllPrices()
        return allPrices.filter { $0.isOnSale }
    }
    
    /// 获取指定折扣范围的游戏
    func getPrices(discountFrom minDiscount: Int, to maxDiscount: Int) throws -> [PriceRecord] {
        let allPrices = try getAllPrices()
        return allPrices.filter { 
            $0.discountPercentage >= minDiscount && $0.discountPercentage <= maxDiscount 
        }
    }
    
    /// 获取大折扣游戏（折扣≥50%）
    func getBigDiscountPrices() throws -> [PriceRecord] {
        return try getPrices(discountFrom: 50, to: 100)
    }
    
    /// 获取所有免费游戏
    func getFreePrices() throws -> [PriceRecord] {
        let allPrices = try getAllPrices()
        return allPrices.filter { $0.isFree }
    }
    
    // MARK: - 价格范围查询
    
    /// 获取指定价格范围的游戏
    func getPrices(from minPrice: Double, to maxPrice: Double) throws -> [PriceRecord] {
        let allPrices = try getAllPrices()
        return allPrices.filter { 
            $0.currentPrice >= minPrice && $0.currentPrice <= maxPrice 
        }
    }
    
    /// 获取低价游戏（≤100元）
    func getLowPricePrices() throws -> [PriceRecord] {
        return try getPrices(from: 0, to: 100)
    }
    
    /// 获取中价游戏（100-300元）
    func getMidPricePrices() throws -> [PriceRecord] {
        return try getPrices(from: 100, to: 300)
    }
    
    /// 获取高价游戏（>300元）
    func getHighPricePrices() throws -> [PriceRecord] {
        let allPrices = try getAllPrices()
        return allPrices.filter { $0.currentPrice > 300 }
    }
    
    // MARK: - 价格友好度排序
    
    /// 获取最价格友好的游戏（按priceFriendlinessScore降序）
    func getMostPriceFriendlyPrices(limit: Int = 20) throws -> [PriceRecord] {
        let allPrices = try getAllPrices()
        let sorted = allPrices.sorted { $0.priceFriendlinessScore > $1.priceFriendlinessScore }
        return Array(sorted.prefix(limit))
    }
    
    /// 根据游戏ID列表，返回最优价格（每个游戏选最便宜平台）
    func getBestPrices(forGameIds gameIds: [String]) throws -> [String: PriceRecord] {
        var bestPrices: [String: PriceRecord] = [:]
        
        for gameId in gameIds {
            let gamePrices = try getPrices(forGameId: gameId)
            
            if let bestPrice = gamePrices.min(by: { $0.currentPrice < $1.currentPrice }) {
                bestPrices[gameId] = bestPrice
            }
        }
        
        return bestPrices
    }
    
    /// 根据游戏ID，返回最优价格记录
    func getBestPrice(forGameId gameId: String) throws -> PriceRecord? {
        let gamePrices = try getPrices(forGameId: gameId)
        return gamePrices.min(by: { $0.currentPrice < $1.currentPrice })
    }
    
    // MARK: - 统计信息
    
    /// 获取平均价格
    func getAveragePrice() throws -> Double {
        let allPrices = try getAllPrices()
        guard !allPrices.isEmpty else { return 0.0 }
        
        let total = allPrices.reduce(0.0) { $0 + $1.currentPrice }
        return total / Double(allPrices.count)
    }
    
    /// 获取打折游戏占比
    func getDiscountPercentage() throws -> Double {
        let allPrices = try getAllPrices()
        guard !allPrices.isEmpty else { return 0.0 }
        
        let discountCount = allPrices.filter { $0.isOnSale }.count
        return Double(discountCount) / Double(allPrices.count) * 100.0
    }
    
    /// 获取价格区间分布
    func getPriceDistribution() throws -> [String: Int] {
        let allPrices = try getAllPrices()
        var distribution: [String: Int] = [
            "免费": 0,
            "0-50": 0,
            "50-100": 0,
            "100-200": 0,
            "200-300": 0,
            "300+": 0
        ]
        
        for price in allPrices {
            if price.isFree {
                distribution["免费"]! += 1
            } else if price.currentPrice <= 50 {
                distribution["0-50"]! += 1
            } else if price.currentPrice <= 100 {
                distribution["50-100"]! += 1
            } else if price.currentPrice <= 200 {
                distribution["100-200"]! += 1
            } else if price.currentPrice <= 300 {
                distribution["200-300"]! += 1
            } else {
                distribution["300+"]! += 1
            }
        }
        
        return distribution
    }
    
    // MARK: - 缓存管理
    
    /// 清空缓存
    func clearCache() {
        cachedPrices = nil
        priceCache.removeAll()
    }
    
    /// 重新加载
    func reload() throws {
        clearCache()
        _ = try getAllPrices()
    }
}

// MARK: - 扩展：推荐辅助

extension PriceRepository {
    
    /// 为游戏列表计算平均价格友好度
    func calculateAveragePriceFriendliness(forGameIds gameIds: [String]) throws -> Double {
        guard !gameIds.isEmpty else { return 0.0 }
        
        let bestPrices = try getBestPrices(forGameIds: gameIds)
        let scores = bestPrices.values.map { $0.priceFriendlinessScore }
        
        guard !scores.isEmpty else { return 0.0 }
        return scores.reduce(0.0, +) / Double(scores.count)
    }
    
    /// 获取指定游戏列表中打折的游戏ID
    func getDiscountedGameIds(from gameIds: [String]) throws -> Set<String> {
        let prices = try getPrices(forGameIds: gameIds)
        let discountedPrices = prices.filter { $0.isOnSale }
        return Set(discountedPrices.map { $0.gameId })
    }
}
