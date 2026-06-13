//
//  DataStore.swift
//  GameRec
//
//  统一JSON读写入口
//

import Foundation

/// 数据存储管理器（JSON持久化）
class DataStore {
    
    static let shared = DataStore()
    
    private init() {}
    
    // MARK: - 文件路径
    
    /// 获取Documents目录路径
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// 获取种子数据Bundle路径
    /// 兼容多种打包结构：folder 引用会保留 Data/SeedData 子目录；普通资源引用会平铺到 bundle 根目录
    private func seedDataURL(filename: String) -> URL? {
        // 依次尝试不同的子目录结构，任意命中即返回
        let candidateSubdirectories: [String?] = ["Data/SeedData", "SeedData", nil]
        for subdirectory in candidateSubdirectories {
            if let url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: subdirectory) {
                return url
            }
        }
        return nil
    }
    
    /// 获取用户数据文件路径
    private func userDataURL(filename: String) -> URL {
        return documentsDirectory.appendingPathComponent(filename)
    }

    // MARK: - 日期解码

    /// 兼容多种 ISO8601 格式的日期解码策略
    /// Python 的 isoformat() 会输出带微秒的时间（如 2026-06-13T11:31:22.010322），
    /// Swift 的 .iso8601 默认不支持小数秒，这里用自定义策略同时兼容「带/不带小数秒」「带/不带时区」。
    private static let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)

        // 依次尝试多种 formatter
        let isoWithFractional = ISO8601DateFormatter()
        isoWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoWithFractional.date(from: dateString) {
            return date
        }

        let isoStandard = ISO8601DateFormatter()
        isoStandard.formatOptions = [.withInternetDateTime]
        if let date = isoStandard.date(from: dateString) {
            return date
        }

        // 无时区的本地格式（Python isoformat 默认不带时区），带/不带微秒各试一次
        for format in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss"] {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "无法解析日期字符串: \(dateString)"
            )
        )
    }

    /// 统一的 JSONDecoder（含自定义日期策略）
    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = DataStore.dateDecodingStrategy
        return decoder
    }
    
    // MARK: - 通用加载方法
    
    /// 从Bundle加载种子数据
    func loadSeedData<T: Decodable>(_ type: T.Type, filename: String) throws -> T {
        guard let url = seedDataURL(filename: filename) else {
            throw DataStoreError.fileNotFound(filename)
        }
        
        let data = try Data(contentsOf: url)
        let decoder = makeDecoder()
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw DataStoreError.decodingFailed(filename, error)
        }
    }
    
    /// 从Documents目录加载用户数据
    func loadUserData<T: Decodable>(_ type: T.Type, filename: String) throws -> T {
        let url = userDataURL(filename: filename)
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw DataStoreError.fileNotFound(filename)
        }
        
        let data = try Data(contentsOf: url)
        let decoder = makeDecoder()
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw DataStoreError.decodingFailed(filename, error)
        }
    }
    
    /// 保存用户数据到Documents目录
    func saveUserData<T: Encodable>(_ data: T, filename: String) throws {
        let url = userDataURL(filename: filename)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: url, options: .atomic)
        } catch {
            throw DataStoreError.encodingFailed(filename, error)
        }
    }
    
    /// 检查用户数据文件是否存在
    func userDataExists(filename: String) -> Bool {
        let url = userDataURL(filename: filename)
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    /// 删除用户数据文件
    func deleteUserData(filename: String) throws {
        let url = userDataURL(filename: filename)
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            return // 文件不存在，无需删除
        }
        
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            throw DataStoreError.deletionFailed(filename, error)
        }
    }
    
    // MARK: - 初始化用户数据
    
    /// 首次启动时，从种子数据复制到用户数据目录
    func initializeUserDataIfNeeded() {
        let userLibraryFilename = "user_library.json"
        
        // 如果用户数据已存在，不覆盖
        guard !userDataExists(filename: userLibraryFilename) else {
            return
        }
        
        // 从种子数据加载并保存到用户目录
        do {
            let seedLibrary = try loadSeedData([UserGameRecord].self, filename: "user_library")
            try saveUserData(seedLibrary, filename: userLibraryFilename)
            print("✅ 用户数据初始化完成")
        } catch {
            print("⚠️ 用户数据初始化失败: \(error)")
        }
    }
}

// MARK: - 错误类型

enum DataStoreError: LocalizedError {
    case fileNotFound(String)
    case decodingFailed(String, Error)
    case encodingFailed(String, Error)
    case deletionFailed(String, Error)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "文件未找到: \(filename)"
        case .decodingFailed(let filename, let error):
            return "解码失败 [\(filename)]: \(error.localizedDescription)"
        case .encodingFailed(let filename, let error):
            return "编码失败 [\(filename)]: \(error.localizedDescription)"
        case .deletionFailed(let filename, let error):
            return "删除失败 [\(filename)]: \(error.localizedDescription)"
        }
    }
}
