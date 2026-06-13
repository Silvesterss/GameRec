//
//  HomeView.swift
//  GameRec
//
//  推荐首页（两层推荐：类别 → 游戏）—— 套用设计系统 Theme
//

import SwiftUI

struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Space.s3) {

                    // 顶部统计卡片
                    if let stats = viewModel.userStats {
                        UserStatsCard(stats: stats)
                            .padding(.horizontal, Theme.Space.s2)
                    }

                    // 类别推荐区（第一层）
                    categorySection

                    Divider()
                        .padding(.horizontal, Theme.Space.s2)

                    // 游戏推荐区（第二层）
                    gameSection
                }
                .padding(.vertical, Theme.Space.s2)
            }
            .background(Theme.Palette.background)
            .navigationTitle("游戏推荐")
            .refreshable { await viewModel.refresh() }
            .alert("错误", isPresented: $viewModel.showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "未知错误")
            }
        }
        .onAppear { viewModel.loadInitialData() }
    }

    // MARK: - 类别区

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s2) {
            SectionHeader(title: "为你推荐的类别") {
                viewModel.refreshCategories()
            }

            if viewModel.isLoadingCategories {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Space.s2)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Space.s2) {
                        ForEach(viewModel.recommendedCategories, id: \.category) { rec in
                            CategoryCard(
                                recommendation: rec,
                                isSelected: viewModel.selectedCategory == rec.category
                            )
                            .onTapGesture { viewModel.selectCategory(rec.category) }
                        }
                    }
                    .padding(.horizontal, Theme.Space.s2)
                }
            }
        }
    }

    // MARK: - 游戏区

    @ViewBuilder
    private var gameSection: some View {
        if let selectedCategory = viewModel.selectedCategory {
            VStack(alignment: .leading, spacing: Theme.Space.s2) {
                SectionHeader(
                    title: "\(selectedCategory.displayName) 游戏推荐",
                    subtitle: viewModel.categoryReason
                ) {
                    viewModel.refreshGames()
                }

                if viewModel.isLoadingGames {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Space.s2)
                } else {
                    LazyVStack(spacing: Theme.Space.s2) {
                        ForEach(viewModel.recommendedGames, id: \.game.id) { rec in
                            NavigationLink {
                                GameDetailView(game: rec.game)
                            } label: {
                                GameCard(recommendation: rec)
                            }
                            .buttonStyle(PressableCardStyle())
                        }
                    }
                    .padding(.horizontal, Theme.Space.s2)
                }
            }
        } else {
            EmptyStateView(icon: "hand.tap", message: "点击上方类别查看游戏推荐")
        }
    }
}

// MARK: - 区块标题（标题 + 可选副标题 + 换一批）

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    let onRefresh: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Theme.Space.half) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Theme.Palette.textSecondary)
                }
            }
            Spacer()
            Button(action: onRefresh) {
                HStack(spacing: Theme.Space.half) {
                    Image(systemName: "arrow.clockwise")
                    Text("换一批")
                }
                .font(.subheadline)
                .foregroundColor(Theme.Palette.primary)
            }
        }
        .padding(.horizontal, Theme.Space.s2)
    }
}

// MARK: - 可按压卡片样式（统一交互反馈）

struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - 用户统计卡片

struct UserStatsCard: View {
    let stats: UserStats

    var body: some View {
        HStack(spacing: Theme.Space.s3) {
            StatItem(icon: "gamecontroller.fill", value: "\(stats.totalGames)", label: "已玩游戏")
            Divider()
            StatItem(icon: "clock.fill", value: String(format: "%.0f", stats.totalHours), label: "游戏时长")
            Divider()
            StatItem(icon: "star.fill", value: "\(stats.completedGames)", label: "已完成")
        }
        .padding(Theme.Space.s2)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(Theme.Palette.primaryTint)
        )
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: Theme.Space.s1) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Theme.Palette.primary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(Theme.Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 类别卡片

struct CategoryCard: View {
    let recommendation: CategoryRecommendation
    var isSelected: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s1) {
            HStack {
                Text(recommendation.category.displayName)
                    .font(.headline)
                    .foregroundColor(Theme.Palette.textPrimary)
                Spacer()
                RatingBadge(score: recommendation.score)
            }

            Text(recommendation.reason)
                .font(.caption)
                .foregroundColor(Theme.Palette.textSecondary)
                .lineLimit(2)

            HStack(spacing: Theme.Space.half) {
                Image(systemName: "square.stack.3d.up")
                    .font(.caption)
                    .foregroundColor(Theme.Palette.textSecondary)
                Text("\(recommendation.unplayedGameCount) 款未玩")
                    .font(.caption)
                    .foregroundColor(Theme.Palette.textSecondary)
            }
        }
        .frame(width: 200, alignment: .leading)
        .cardStyle()
        .overlay(
            // 选中态：主色描边
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .stroke(Theme.Palette.primary, lineWidth: isSelected ? 2 : 0)
        )
    }
}

// MARK: - 游戏卡片

struct GameCard: View {
    let recommendation: GameRecommendation

    var body: some View {
        HStack(spacing: Theme.Space.s2) {
            GameCoverView(game: recommendation.game, size: 80)

            VStack(alignment: .leading, spacing: Theme.Space.s1) {
                Text(recommendation.game.title)
                    .font(.headline)
                    .foregroundColor(Theme.Palette.textPrimary)
                    .lineLimit(1)

                Text(recommendation.reason)
                    .font(.caption)
                    .foregroundColor(Theme.Palette.textSecondary)
                    .lineLimit(2)

                // 类别标签（最多 3 个）
                HStack(spacing: Theme.Space.half) {
                    ForEach(recommendation.game.categories.prefix(3), id: \.self) { category in
                        CategoryTag(text: category.displayName)
                    }
                }

                // 价格信息
                if let price = recommendation.bestPrice {
                    priceRow(price)
                }
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
    }

    @ViewBuilder
    private func priceRow(_ price: PriceRecord) -> some View {
        HStack(spacing: Theme.Space.s1) {
            if price.isOnSale {
                Text("¥\(Int(price.originalPrice))")
                    .font(.caption)
                    .strikethrough()
                    .foregroundColor(Theme.Palette.textSecondary)
                Text(price.formattedPrice)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Palette.textPrimary)
                DiscountBadge(percentage: price.discountPercentage)
            } else {
                Text(price.formattedPrice)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Palette.textPrimary)
            }
            Spacer()
            RatingBadge(score: recommendation.score)
        }
    }
}

// MARK: - Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
