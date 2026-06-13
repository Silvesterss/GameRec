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
    private func seedDataURL(filename: String) -> URL? {
        return Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Data/SeedData")
    }
    
    /// 获取用户数据文件路径
    private func userDataURL(filename: String) -> URL {
        return documentsDirectory.appendingPathComponent(filename)
    }
    
    // MARK: - 通用加载方法
    
    /// 从Bundle加载种子数据
    func loadSeedData<T: Decodable>(_ type: T.Type, filename: String) throws -> T {
        guard let url = seedDataURL(filename: filename) else {
            throw DataStoreError.fileNotFound(filename)
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
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
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
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
