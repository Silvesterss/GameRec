//
//  HomeViewModel.swift
//  GameRec
//
//  推荐首页ViewModel
//

import Foundation
import Combine

/// 用户统计数据
struct UserStats {
    let totalGames: Int
    let totalHours: Double
    let completedGames: Int
}

/// 推荐首页ViewModel
@MainActor
class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var recommendedCategories: [CategoryRecommendation] = []
    @Published var recommendedGames: [GameRecommendation] = []
    @Published var selectedCategory: GameCategory?
    @Published var categoryReason: String?
    @Published var userStats: UserStats?
    
    @Published var isLoadingCategories = false
    @Published var isLoadingGames = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let categoryRecommender: CategoryRecommender
    private let gameRecommender: GameRecommender
    private let refreshStrategy: RefreshStrategy
    private let userLibraryRepo: UserLibraryRepository
    
    // MARK: - Initialization
    
    init() {
        self.categoryRecommender = CategoryRecommender()
        self.gameRecommender = GameRecommender()
        self.refreshStrategy = RefreshStrategy()
        self.userLibraryRepo = UserLibraryRepository.shared
    }
    
    // MARK: - Public Methods
    
    /// 加载初始数据
    func loadInitialData() {
        Task {
            await loadUserStats()
            await loadCategories()
        }
    }
    
    /// 下拉刷新
    func refresh() async {
        refreshStrategy.resetAll()
        await loadCategories()
        
        if selectedCategory != nil {
            await loadGames()
        }
    }
    
    /// 刷新类别推荐
    func refreshCategories() {
        Task {
            await loadCategories(seed: refreshStrategy.nextCategorySeed())
        }
    }
    
    /// 刷新游戏推荐
    func refreshGames() {
        Task {
            await loadGames(seed: refreshStrategy.nextGameSeed())
        }
    }
    
    /// 选择类别
    func selectCategory(_ category: GameCategory) {
        selectedCategory = category
        refreshStrategy.onCategoryChanged()
        
        // 找到该类别的推荐理由
        if let recommendation = recommendedCategories.first(where: { $0.category == category }) {
            categoryReason = recommendation.reason
        }
        
        Task {
            await loadGames()
        }
    }
    
    // MARK: - Private Methods
    
    /// 加载用户统计数据
    private func loadUserStats() async {
        do {
            let library = try userLibraryRepo.getMergedLibrary()
            
            let totalGames = library.count
            let totalHours = library.reduce(0.0) { $0 + $1.totalHoursPlayed }
            let completedGames = library.filter { $0.isCompleted }.count
            
            userStats = UserStats(
                totalGames: totalGames,
                totalHours: totalHours,
                completedGames: completedGames
            )
        } catch {
            handleError(error)
        }
    }
    
    /// 加载类别推荐
    private func loadCategories(seed: Int = 0) async {
        isLoadingCategories = true
        
        do {
            let categories = try categoryRecommender.recommendCategories(
                topN: 5,
                seed: seed
            )
            recommendedCategories = categories
            
            // 如果还没选择类别，自动选择第一个
            if selectedCategory == nil, let first = categories.first {
                selectCategory(first.category)
            }
        } catch {
            handleError(error)
        }
        
        isLoadingCategories = false
    }
    
    /// 加载游戏推荐
    private func loadGames(seed: Int = 0) async {
        guard let category = selectedCategory else { return }
        
        isLoadingGames = true
        
        do {
            let games = try gameRecommender.recommendGames(
                inCategory: category,
                topN: 8,
                seed: seed
            )
            recommendedGames = games
        } catch {
            handleError(error)
        }
        
        isLoadingGames = false
    }
    
    /// 错误处理
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        print("❌ HomeViewModel Error: \(error)")
    }
}
