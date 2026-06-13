# GameRec Design System 设计规范

> 适用范围：GameRec iOS App（SwiftUI）。所有数值来自真实代码，落地实现见 `GameRec/DesignSystem/Theme.swift` 与 `Components.swift`。

---

## 1. 产品气质 / 目标用户 / 核心场景

**产品气质**：克制、信息密度中等、偏「工具型推荐」而非「内容型社区」。主色蓝 + 卡片化布局，贴近 iOS 系统原生质感（语义色 + SF Symbols），不张扬、不游戏化炫酷。一句话：**像一个懂你游戏口味、还顺手帮你看了价格的理性导购。**

**目标用户**：跨平台（PSN / Steam / Switch）主机+PC 玩家，已有一定游戏库存量、面临「下一个玩什么」的选择焦虑、对价格折扣敏感的理性消费型玩家。

**核心使用场景**：
1. 打开即看「为你推荐的类别」→ 点类别 → 看类内未玩游戏（两层漏斗式决策）
2. 对推荐不满意 → 点「换一批」快速刷新
3. 决策辅助：每张卡片给「为什么推荐」+ 价格/折扣，支撑「值不值得买」判断
4. 绑定多平台账号 → 同步已玩游戏 → 游戏库管理 → 点进详情看跨平台价格

---

## 2. 视觉语言提炼（从代码归纳）

| 维度 | 现状 |
|---|---|
| 主色 | 系统蓝，用于可点击元素、强调、选中 |
| 辅助色 | 橙（评分/星标）、红（价格/折扣） |
| 中性色 | primary（标题）、secondary（说明）、gray（占位） |
| 背景 | 卡片 secondarySystemGroupedBackground，统计卡 primaryTint |
| 字体 | 全部用 SF 系统语义字体，标题 title2 bold |
| 间距 | 统一 8 的倍数（半档 4） |
| 圆角 | 收敛到 6 / 12 / 16 三档 |
| 阴影 | 统一两档（card / pop） |
| 组件 | 卡片、评分徽标、折扣徽标、类别标签、按钮、空状态、封面 |
| 交互态 | Pressed（opacity+scale）、Selected（主色描边）、Loading、Empty |

---

## 3. Design System 规范

### 3.1 设计原则

1. **决策优先于装饰**
   - 适用：推荐理由、价格、折扣给最高视觉权重。
   - 不要：为了好看加渐变/大图/动效，挤占决策信息。
2. **系统原生感**
   - 适用：背景、文字层级、图标统一走系统语义色 + SF Symbols。
   - 不要：硬编码十六进制随机色覆盖深浅色模式。
3. **一种数据一种表达**
   - 适用：评分在全 App 永远是同一视觉（橙色 RatingBadge）。
   - 不要：同一个 score 在不同卡片用不同样式。
4. **8px 网格统一节奏**
   - 适用：padding、spacing、组件尺寸只取 8 的倍数（必要时 4 作半档）。
   - 不要：随手写 20 / 6 / 2 这种破网格的值。

### 3.2 色彩系统

| Token | 用途 | 不要这样用 |
|---|---|---|
| `primary` | 可点击/强调/选中 | 不要大面积背景填充 |
| `primaryTint` | 强调容器底（统计卡、标签底） | 不要再叠加第二种透明度 |
| `rating`（橙） | **仅**评分 | 不要当按钮/链接色 |
| `sale`（红） | **仅**降价/折扣 | 不要当普通价格或错误色 |
| `textPrimary` | 标题、主价格 | 不要给说明文字 |
| `textSecondary` | 推荐理由、标签说明 | 不要给标题 |
| `surface` | 所有卡片底 | 不要硬编码纯白/纯灰 |
| `placeholder` | 封面占位、空状态 | 不要当正式内容色 |

**红线**：除上述外不得引入新色相；橙=评分、红=促销，禁止串用。

### 3.3 字体系统

全部用系统动态字体（支持无障碍缩放），不引入自定义字体。

| Token | SwiftUI | 用途 | 不要 |
|---|---|---|---|
| `title` | `.title2` bold | 区块标题 | 每屏不超过 2 个 |
| `stat` | `.title3` bold | 统计数值 | 不要给普通文本 |
| `body` | `.headline`/`.body` | 卡片标题/正文 | 不要堆叠多个 headline |
| `body-strong` | `.subheadline` semibold | 价格 | — |
| `caption` | `.caption` | 推荐理由、评分 | — |
| `caption-mini` | `.caption2` | 类别小标签 | 不要承载关键信息 |

层级最多 4 级同屏可见；正文与说明靠字号+颜色区分，不靠字重堆叠。

### 3.4 间距与栅格（8px 系统）

| Token | 值 | 用途 |
|---|---|---|
| `half` | 4 | 徽标内 padding、紧凑图标间距 |
| `s1` | 8 | 卡片内元素间距 |
| `s2` | 16 | 卡片内主间距、列表项间距、页面边距 |
| `s3` | 24 | 区块之间 |
| `s4` | 32 | 页面顶/底留白 |
| `s5` | 40 | 空状态垂直留白 |

适用：所有 padding/spacing 只能取上表值。
不要：出现 20 / 6 / 2 / 60 等非档位值。

### 3.5 圆角 / 边框 / 阴影

**圆角**（3 档）：`sm=6`（标签/徽标）、`md=12`（所有卡片）、`lg=16`（大容器/sheet）。

**边框**：默认无边框，靠 surface 色差和阴影分层；需要分隔用系统 `Divider()`，不用自定义 1px 线。选中态例外：用 `primary` 2px 描边。

**阴影**（2 档，禁止同级组件用不同阴影）：
- `shadow-card`：black 6%, blur 8, y 2 —— 所有卡片统一
- `shadow-pop`：black 12%, blur 16, y 4 —— 浮层/弹窗

不要：给卡片加 >12% 的重阴影。

### 3.6 核心组件规范

- **Card**：底 `surface`、圆角 `md`、阴影 `shadow-card`、内距 `s2`。用 `.cardStyle()` 修饰符统一。不要每种卡各调一套。
- **RatingBadge**：橙色星标 + 数值，无底。仅用于评分。
- **DiscountBadge**：红底白字，圆角 `sm`。仅用于折扣。
- **CategoryTag**：`primaryTint` 底 + `primary` 字，圆角 `sm`，最多 3 个。
- **Button（换一批/次要操作）**：文字按钮 `primary` 色 + 图标。不要做成实底大按钮抢焦点。
- **主操作按钮（登录/绑定）**：`primary` 实底 + 白字 + 圆角 `md`，满宽。
- **Stat**：图标(primary) + 数值(stat) + 标签(caption/secondary)，竖排等宽。

### 3.7 状态规范

| 状态 | 规范 | 适用 | 不要 |
|---|---|---|---|
| Default | 见各组件 | — | — |
| Pressed | opacity 0.6 + scale 0.98（`PressableCardStyle`） | 所有可点卡片/链接 | 不要无反馈 |
| Selected | 主色 2px 描边 | 当前选中类别 | 不要靠颜色突变 |
| Loading | `ProgressView` 居中 | 数据加载中 | 不要整屏空白 |
| Empty | `EmptyStateView`（灰图标 + headline 提示） | 无数据时 | 不要只留空白 |
| Error | 行内提示（登录）或 alert（首页） | 失败场景 | 关键流程不要只用一闪而过的 alert |
| Disabled | 背景置灰 placeholder + 不可点 | 不可用操作（如未填账号名） | 不要隐藏，要可见但禁用 |

### 3.8 图标 / 插画规范

- 统一用 **SF Symbols**，不混用第三方图标。
- 图标色跟随语义：可点=`primary`，评分=`rating`，占位/次要=`textSecondary`/`placeholder`。
- 尺寸跟字体走，不写死像素。
- 平台图标：PSN=`playstation.logo`、Steam=`gear.circle`、Switch=`gamecontroller`。
- 不要：用 emoji 当正式 UI 图标；不要彩色多色图标破坏克制基调。

### 3.9 文案语气规范

- 第二人称、口语、简短，像懂行的朋友推荐（"你深度游玩过这类游戏""与你喜欢的《X》类似"）。
- 推荐理由控制在 1～2 行。
- 数字优先（"15 款未玩"、"-40%"）。
- 不要：营销夸张词（"史诗级""不容错过"）、客服腔（"亲""为您"）、长句堆叠。

### 3.10 禁用规则 / 设计红线

1. 🚫 不用渐变（除非明确要求）。
2. 🚫 不引入语义外的新颜色；橙仅评分、红仅促销。
3. 🚫 间距/圆角不得脱离 token 档位。
4. 🚫 同一数据不得有两种视觉表达。
5. 🚫 不硬编码深浅色，必须走语义色自适应。
6. 🚫 可点击元素必须有按压反馈。
7. 🚫 每屏 title 级标题不超过 2 个。

---

## 4. Design Tokens

### 4.1 CSS Variables

```css
:root {
  --color-primary: #0A84FF;
  --color-primary-tint: rgba(10, 132, 255, 0.10);
  --color-accent-rating: #FF9F0A;
  --color-accent-sale: #FF3B30;
  --color-text-primary: #1C1C1E;
  --color-text-secondary: #8E8E93;
  --color-surface: #F2F2F7;
  --color-placeholder: rgba(142, 142, 147, 0.30);

  --space-0_5: 4px;  --space-1: 8px;  --space-2: 16px;
  --space-3: 24px;   --space-4: 32px; --space-5: 40px;

  --radius-sm: 6px;  --radius-md: 12px; --radius-lg: 16px;

  --shadow-card: 0 2px 8px rgba(0,0,0,0.06);
  --shadow-pop:  0 4px 16px rgba(0,0,0,0.12);

  --font-title: 22px;  --font-stat: 20px;  --font-body: 17px;
  --font-body-strong: 15px; --font-caption: 12px; --font-caption-mini: 11px;
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-text-primary: #FFFFFF;
    --color-text-secondary: #98989D;
    --color-surface: #1C1C1E;
  }
}
```

### 4.2 Tailwind Config

```js
module.exports = {
  theme: {
    extend: {
      colors: {
        primary: { DEFAULT: '#0A84FF', tint: 'rgba(10,132,255,0.10)' },
        rating: '#FF9F0A',
        sale: '#FF3B30',
        surface: '#F2F2F7',
        placeholder: 'rgba(142,142,147,0.30)',
      },
      spacing: { 0.5: '4px', 1: '8px', 2: '16px', 3: '24px', 4: '32px', 5: '40px' },
      borderRadius: { sm: '6px', md: '12px', lg: '16px' },
      boxShadow: {
        card: '0 2px 8px rgba(0,0,0,0.06)',
        pop:  '0 4px 16px rgba(0,0,0,0.12)',
      },
      fontSize: {
        title: ['22px', { fontWeight: '700' }],
        stat: ['20px', { fontWeight: '700' }],
        body: ['17px'],
        'body-strong': ['15px', { fontWeight: '600' }],
        caption: ['12px'],
        'caption-mini': ['11px'],
      },
    },
  },
}
```

### 4.3 SwiftUI 映射

落地实现见 `GameRec/DesignSystem/Theme.swift`（`Theme.Palette` / `Theme.Space` / `Theme.Radius` / `Theme.Shadow`）和 `.cardStyle()` 修饰符。

---

## 5. 改造前的不一致清单（已全部修复）

| # | 原问题 | 修复 |
|---|---|---|
| 1 | 同一「评分」两种视觉（类别卡蓝底白字 vs 游戏卡橙裸字） | 统一为 `RatingBadge`（橙色星标） |
| 2 | 同级卡片阴影不一致（0.1/r4 vs 0.05/r2） | 统一 `shadow-card`（`.cardStyle()`） |
| 3 | 圆角 5 档混用（16/12/8/6/4） | 收敛到 6/12/16 |
| 4 | 间距破网格（20/6/2/60） | 全部改为 8 的倍数（`Theme.Space`） |
| 5 | tint 透明度两套（0.1 / 0.2） | 统一 `primaryTint`(0.10) |
| 6 | 红色语义重载（促销价 + 折扣都红） | 主价格改 `textPrimary`，红仅留折扣徽标 |
| 7 | 可点元素无按压反馈 | 加 `PressableCardStyle`（opacity+scale） |
| 8 | 选中类别无视觉标识 | 选中类别加 `primary` 2px 描边 |
| 9 | 错误只用 alert | 登录流程改行内 error 提示 |

---

## 6. 新增功能（本次迭代）

- **底部 Tab 导航**：首页 / 游戏库 / 我的（`MainTabView`）。
- **登录 / 注册系统**：本地账号，邮箱+密码（`AuthView` + `AuthManager`）。
- **多平台账号绑定**：一个用户可绑定 PSN/Steam/Switch 多平台、每平台多账号，「我的」页查看与解绑（`ProfileView` + `BindAccountSheet`）。
- **游戏封面**：`GameCoverView`，有图用 `AsyncImage`，无图用按 id 稳定生成的中性色块 + 首字占位。
- **游戏详情页**：封面/简介/各平台价格/我的游玩数据/相似游戏推荐（`GameDetailView`），首页卡片与游戏库均可点进。

> ⚠️ 安全说明：当前登录与平台绑定为本地明文存储，仅用于学习/演示。生产环境必须：密码加盐哈希、后端鉴权、平台账号走各平台官方 OAuth 授权（Steam Web API / PSN / Nintendo），详情页数据接入对应平台真实 API。
