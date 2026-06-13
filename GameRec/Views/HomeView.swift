//
//  HomeView.swift
//  GameRec
//
//  推荐首页（两层推荐：类别 → 游戏）
//

import SwiftUI

struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - 顶部统计卡片
                    if let stats = viewModel.userStats {
                        UserStatsCard(stats: stats)
                            .padding(.horizontal)
                    }
                    
                    // MARK: - 类别推荐区（第一层）
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("为你推荐的类别")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.refreshCategories()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("换一批")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        if viewModel.isLoadingCategories {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(viewModel.recommendedCategories, id: \.category) { recommendation in
                                        CategoryCard(recommendation: recommendation)
                                            .onTapGesture {
                                                viewModel.selectCategory(recommendation.category)
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // MARK: - 游戏推荐区（第二层）
                    if let selectedCategory = viewModel.selectedCategory {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(selectedCategory.displayName) 游戏推荐")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    if let reason = viewModel.categoryReason {
                                        Text(reason)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.refreshGames()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.clockwise")
                                        Text("换一批")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)
                            
                            if viewModel.isLoadingGames {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(viewModel.recommendedGames, id: \.game.id) { recommendation in
                                        GameCard(recommendation: recommendation)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    } else {
                        // 空状态：提示选择类别
                        VStack(spacing: 16) {
                            Image(systemName: "hand.tap")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("点击上方类别查看游戏推荐")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("游戏推荐")
            .refreshable {
                await viewModel.refresh()
            }
            .alert("错误", isPresented: $viewModel.showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "未知错误")
            }
        }
        .onAppear {
            viewModel.loadInitialData()
        }
    }
}

// MARK: - 用户统计卡片

struct UserStatsCard: View {
    let stats: UserStats
    
    var body: some View {
        HStack(spacing: 20) {
            StatItem(
                icon: "gamecontroller.fill",
                value: "\(stats.totalGames)",
                label: "已玩游戏"
            )
            
            Divider()
            
            StatItem(
                icon: "clock.fill",
                value: String(format: "%.0f", stats.totalHours),
                label: "游戏时长"
            )
            
            Divider()
            
            StatItem(
                icon: "star.fill",
                value: "\(stats.completedGames)",
                label: "已完成"
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 类别卡片

struct CategoryCard: View {
    let recommendation: CategoryRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recommendation.category.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(String(format: "%.1f", recommendation.score))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            
            Text(recommendation.reason)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                Text("\(recommendation.unplayedGameCount) 款未玩")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - 游戏卡片

struct GameCard: View {
    let recommendation: GameRecommendation
    
    var body: some View {
        HStack(spacing: 16) {
            // 游戏封面占位符
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "gamecontroller.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                // 游戏标题
                Text(recommendation.game.title)
                    .font(.headline)
                    .lineLimit(1)
                
                // 推荐理由
                Text(recommendation.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // 标签
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(recommendation.game.categories.prefix(3), id: \.self) { category in
                            Text(category.displayName)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                    }
                }
                
                // 价格信息
                if let price = recommendation.bestPrice {
                    HStack(spacing: 8) {
                        if price.isOnSale {
                            Text("¥\(Int(price.originalPrice))")
                                .font(.caption)
                                .strikethrough()
                                .foregroundColor(.secondary)
                            
                            Text(price.formattedPrice)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            
                            Text("-\(price.discountPercentage)%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .cornerRadius(4)
                        } else {
                            Text(price.formattedPrice)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Text(String(format: "%.1f", recommendation.score))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
