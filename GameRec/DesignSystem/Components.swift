//
//  Components.swift
//  GameRec
//
//  设计系统可复用组件（评分徽标、折扣徽标、类别标签、游戏封面）
//

import SwiftUI

// MARK: - 评分徽标（统一全 App 评分视觉：橙色文字，无底）

struct RatingBadge: View {
    let score: Double

    var body: some View {
        HStack(spacing: Theme.Space.half) {
            Image(systemName: "star.fill")
                .font(.caption2)
            Text(String(format: "%.1f", score))
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(Theme.Palette.rating)
    }
}

// MARK: - 折扣徽标（统一促销视觉：红底白字）

struct DiscountBadge: View {
    let percentage: Int

    var body: some View {
        Text("-\(percentage)%")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, Theme.Space.s1)
            .padding(.vertical, Theme.Space.half)
            .background(Theme.Palette.sale)
            .cornerRadius(Theme.Radius.sm)
    }
}

// MARK: - 类别标签（主色淡底 + 主色字）

struct CategoryTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, Theme.Space.s1)
            .padding(.vertical, Theme.Space.half)
            .background(Theme.Palette.primaryTint)
            .foregroundColor(Theme.Palette.primary)
            .cornerRadius(Theme.Radius.sm)
    }
}

// MARK: - 游戏封面

/// 游戏封面视图：有 imageURL 用 AsyncImage，否则用「按 id 稳定生成的色块 + 首字」占位
struct GameCoverView: View {
    let game: Game
    var size: CGFloat = 80
    var cornerRadius: CGFloat = Theme.Radius.sm

    var body: some View {
        Group {
            if let urlString = game.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// 占位封面：稳定色块 + 游戏首字（无随机色，按 id 哈希取系统中性色相）
    private var placeholder: some View {
        ZStack {
            coverColor
            Text(String(game.title.prefix(1)))
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(.white)
        }
    }

    /// 按 id 稳定映射到一组克制的中性色（避免随机色，且同一游戏色固定）
    private var coverColor: Color {
        let palette: [Color] = [
            Color(red: 0.20, green: 0.29, blue: 0.37),
            Color(red: 0.30, green: 0.34, blue: 0.42),
            Color(red: 0.25, green: 0.32, blue: 0.36),
            Color(red: 0.34, green: 0.30, blue: 0.38),
            Color(red: 0.22, green: 0.34, blue: 0.34)
        ]
        let hash = abs(game.id.hashValue)
        return palette[hash % palette.count]
    }
}

// MARK: - 平台小图标行

struct PlatformIcons: View {
    let platforms: [Platform]

    var body: some View {
        HStack(spacing: Theme.Space.half) {
            ForEach(platforms, id: \.self) { platform in
                Image(systemName: platform.iconName)
                    .font(.caption2)
                    .foregroundColor(Theme.Palette.textSecondary)
            }
        }
    }
}

// MARK: - 空状态

struct EmptyStateView: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: Theme.Space.s2) {
            Image(systemName: icon)
                .font(.system(size: Theme.Space.s5 + Theme.Space.s3)) // 64
                .foregroundColor(Theme.Palette.placeholder)
            Text(message)
                .font(.headline)
                .foregroundColor(Theme.Palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Space.s5)
    }
}
