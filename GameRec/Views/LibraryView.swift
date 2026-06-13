//
//  LibraryView.swift
//  GameRec
//
//  游戏库：展示用户已玩过的游戏（多平台合并），可搜索、点进详情
//

import SwiftUI

struct LibraryView: View {

    @StateObject private var viewModel = LibraryViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            Group {
                if viewModel.items.isEmpty {
                    EmptyStateView(icon: "books.vertical", message: "还没有游戏记录\n绑定平台账号后即可同步")
                } else {
                    ScrollView {
                        LazyVStack(spacing: Theme.Space.s2) {
                            ForEach(filteredItems, id: \.game.id) { item in
                                NavigationLink {
                                    GameDetailView(game: item.game)
                                } label: {
                                    LibraryRow(item: item)
                                }
                                .buttonStyle(PressableCardStyle())
                            }
                        }
                        .padding(Theme.Space.s2)
                    }
                }
            }
            .background(Theme.Palette.background)
            .navigationTitle("游戏库")
            .searchable(text: $searchText, prompt: "搜索游戏")
        }
        .onAppear { viewModel.load() }
    }

    private var filteredItems: [LibraryItem] {
        guard !searchText.isEmpty else { return viewModel.items }
        return viewModel.items.filter { $0.game.title.localizedCaseInsensitiveContains(searchText) }
    }
}

// MARK: - 列表行

struct LibraryRow: View {
    let item: LibraryItem

    var body: some View {
        HStack(spacing: Theme.Space.s2) {
            GameCoverView(game: item.game, size: 64)

            VStack(alignment: .leading, spacing: Theme.Space.half) {
                Text(item.game.title)
                    .font(.headline)
                    .foregroundColor(Theme.Palette.textPrimary)
                    .lineLimit(1)

                Text("时长 \(String(format: "%.0f", item.record.totalHoursPlayed))h · 进度 \(item.record.maxProgressPercentage)%")
                    .font(.caption)
                    .foregroundColor(Theme.Palette.textSecondary)

                HStack(spacing: Theme.Space.s1) {
                    PlatformIcons(platforms: item.record.platforms)
                    if item.record.isCompleted {
                        Text("已完成")
                            .font(.caption2)
                            .foregroundColor(Theme.Palette.rating)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
    }
}

// MARK: - ViewModel

struct LibraryItem {
    let game: Game
    let record: MergedGameRecord
}

@MainActor
final class LibraryViewModel: ObservableObject {
    private let userRepo = UserLibraryRepository.shared
    private let gameRepo = GameRepository.shared

    @Published var items: [LibraryItem] = []

    func load() {
        guard let merged = try? userRepo.getMergedLibrary() else {
            items = []
            return
        }
        // 关联游戏元数据，按最后游玩时间降序
        items = merged.compactMap { record -> LibraryItem? in
            guard let game = try? gameRepo.getGame(by: record.gameId) else { return nil }
            return LibraryItem(game: game, record: record)
        }
        .sorted { ($0.record.lastPlayedDate ?? .distantPast) > ($1.record.lastPlayedDate ?? .distantPast) }
    }
}
