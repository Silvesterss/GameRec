//
//  GameDetailView.swift
//  GameRec
//
//  游戏详情页：封面/简介/各平台价格/我的游玩数据/相似推荐
//  数据来源：本地 Repository（模拟 Steam/PSN/Switch 平台数据）
//

import SwiftUI

struct GameDetailView: View {
    let game: Game

    @StateObject private var viewModel: GameDetailViewModel

    init(game: Game) {
        self.game = game
        _viewModel = StateObject(wrappedValue: GameDetailViewModel(game: game))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.s3) {
                header
                descriptionSection
                pricesSection
                if viewModel.myRecords.isEmpty == false {
                    mySection
                }
                similarSection
            }
            .padding(Theme.Space.s2)
        }
        .background(Theme.Palette.background)
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.load() }
    }

    // MARK: - 头部（封面 + 标题 + 平台 + 年份）

    private var header: some View {
        HStack(alignment: .top, spacing: Theme.Space.s2) {
            GameCoverView(game: game, size: 120, cornerRadius: Theme.Radius.md)

            VStack(alignment: .leading, spacing: Theme.Space.s1) {
                Text(game.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Palette.textPrimary)

                Text("\(game.releaseYear) 年")
                    .font(.caption)
                    .foregroundColor(Theme.Palette.textSecondary)

                // 类别标签
                HStack(spacing: Theme.Space.half) {
                    ForEach(game.categories.prefix(3), id: \.self) { c in
                        CategoryTag(text: c.displayName)
                    }
                }

                // 平台
                HStack(spacing: Theme.Space.s1) {
                    ForEach(game.platforms, id: \.self) { p in
                        HStack(spacing: Theme.Space.half) {
                            Image(systemName: p.iconName)
                            Text(p.displayName)
                        }
                        .font(.caption)
                        .foregroundColor(Theme.Palette.textSecondary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - 简介

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s1) {
            Text("简介").font(.headline)
            Text(game.description)
                .font(.body)
                .foregroundColor(Theme.Palette.textSecondary)
        }
    }

    // MARK: - 各平台价格

    private var pricesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s2) {
            Text("各平台价格").font(.headline)

            if viewModel.prices.isEmpty {
                Text("暂无价格数据")
                    .font(.caption)
                    .foregroundColor(Theme.Palette.textSecondary)
            } else {
                VStack(spacing: Theme.Space.s1) {
                    ForEach(viewModel.prices, id: \.id) { price in
                        priceRow(price)
                    }
                }
            }
        }
    }

    private func priceRow(_ price: PriceRecord) -> some View {
        HStack(spacing: Theme.Space.s1) {
            Image(systemName: price.platform.iconName)
                .foregroundColor(Theme.Palette.textSecondary)
            Text(price.platform.displayName)
                .font(.subheadline)
                .foregroundColor(Theme.Palette.textPrimary)
            Spacer()
            if price.isOnSale {
                Text("¥\(Int(price.originalPrice))")
                    .font(.caption)
                    .strikethrough()
                    .foregroundColor(Theme.Palette.textSecondary)
                DiscountBadge(percentage: price.discountPercentage)
            }
            Text(price.formattedPrice)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(Theme.Palette.textPrimary)
        }
        .cardStyle(padding: Theme.Space.s1 + Theme.Space.half)
    }

    // MARK: - 我的游玩数据

    private var mySection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s2) {
            Text("我的游玩数据").font(.headline)
            VStack(spacing: Theme.Space.s1) {
                ForEach(viewModel.myRecords, id: \.id) { record in
                    HStack(spacing: Theme.Space.s2) {
                        Image(systemName: record.platform.iconName)
                            .foregroundColor(Theme.Palette.textSecondary)
                        VStack(alignment: .leading, spacing: Theme.Space.half) {
                            Text(record.platform.displayName)
                                .font(.subheadline)
                                .foregroundColor(Theme.Palette.textPrimary)
                            Text("时长 \(String(format: "%.0f", record.hoursPlayed))h · 进度 \(record.progressPercentage)% · 成就 \(record.achievementsUnlocked)/\(record.totalAchievements)")
                                .font(.caption)
                                .foregroundColor(Theme.Palette.textSecondary)
                        }
                        Spacer()
                    }
                    .cardStyle(padding: Theme.Space.s1 + Theme.Space.half)
                }
            }
        }
    }

    // MARK: - 相似推荐

    @ViewBuilder
    private var similarSection: some View {
        if !viewModel.similarGames.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Space.s2) {
                Text("相似游戏").font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Space.s2) {
                        ForEach(viewModel.similarGames, id: \.id) { similar in
                            NavigationLink {
                                GameDetailView(game: similar)
                            } label: {
                                VStack(alignment: .leading, spacing: Theme.Space.s1) {
                                    GameCoverView(game: similar, size: 100, cornerRadius: Theme.Radius.sm)
                                    Text(similar.title)
                                        .font(.caption)
                                        .foregroundColor(Theme.Palette.textPrimary)
                                        .lineLimit(1)
                                        .frame(width: 100, alignment: .leading)
                                }
                            }
                            .buttonStyle(PressableCardStyle())
                        }
                    }
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class GameDetailViewModel: ObservableObject {
    private let game: Game
    private let priceRepo = PriceRepository.shared
    private let userRepo = UserLibraryRepository.shared
    private let gameRepo = GameRepository.shared

    @Published var prices: [PriceRecord] = []
    @Published var myRecords: [UserGameRecord] = []
    @Published var similarGames: [Game] = []

    init(game: Game) {
        self.game = game
    }

    func load() {
        // 各平台价格（按平台名排序，稳定展示）
        prices = (try? priceRepo.getPrices(forGameId: game.id))?
            .sorted { $0.platform.rawValue < $1.platform.rawValue } ?? []

        // 我玩过的记录
        myRecords = (try? userRepo.getRecords(forGameId: game.id)) ?? []

        // 相似游戏
        similarGames = (try? gameRepo.findSimilarGames(to: game, limit: 8)) ?? []
    }
}
