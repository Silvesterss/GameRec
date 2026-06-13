//
//  Theme.swift
//  GameRec
//
//  设计系统 Design Token（集中管理颜色/间距/圆角/阴影/字体）
//  规范详见 docs/06_design_system.md
//

import SwiftUI

/// 全局设计 Token
enum Theme {

    // MARK: - 色彩（语义化，自适应深浅色）

    enum Palette {
        /// 主色：可点击 / 强调 / 选中
        static let primary = Color.blue
        /// 主色淡底：强调容器（统计卡、标签底）
        static let primaryTint = Color.blue.opacity(0.10)
        /// 评分专用色（仅评分使用）
        static let rating = Color.orange
        /// 促销专用色（仅折扣使用）
        static let sale = Color.red
        /// 主文字（标题、主价格）
        static let textPrimary = Color.primary
        /// 次要文字（说明、标签）
        static let textSecondary = Color.secondary
        /// 卡片底色
        static let surface = Color(uiColor: .secondarySystemGroupedBackground)
        /// 页面底色
        static let background = Color(uiColor: .systemGroupedBackground)
        /// 占位色（封面占位、空状态）
        static let placeholder = Color.gray.opacity(0.30)
    }

    // MARK: - 间距（8px 系统，4 为半档）

    enum Space {
        static let half: CGFloat = 4
        static let s1: CGFloat = 8
        static let s2: CGFloat = 16
        static let s3: CGFloat = 24
        static let s4: CGFloat = 32
        static let s5: CGFloat = 40
    }

    // MARK: - 圆角（收敛到 3 档）

    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
    }

    // MARK: - 阴影（统一 2 档）

    enum Shadow {
        /// 所有卡片统一阴影
        static let cardColor = Color.black.opacity(0.06)
        static let cardRadius: CGFloat = 8
        static let cardY: CGFloat = 2
        /// 浮层 / 弹窗阴影
        static let popColor = Color.black.opacity(0.12)
        static let popRadius: CGFloat = 16
        static let popY: CGFloat = 4
    }
}

// MARK: - 通用卡片样式修饰符

/// 统一卡片外观：surface 底 + 圆角 + 统一阴影 + 内边距
struct CardStyle: ViewModifier {
    var padding: CGFloat = Theme.Space.s2

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(Theme.Palette.surface)
                    .shadow(
                        color: Theme.Shadow.cardColor,
                        radius: Theme.Shadow.cardRadius,
                        x: 0,
                        y: Theme.Shadow.cardY
                    )
            )
    }
}

extension View {
    /// 套用统一卡片样式
    func cardStyle(padding: CGFloat = Theme.Space.s2) -> some View {
        modifier(CardStyle(padding: padding))
    }
}
