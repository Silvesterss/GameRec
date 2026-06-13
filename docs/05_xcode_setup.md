# Xcode 工程创建步骤

> 由于 Xcode 工程文件 (`.xcodeproj`)是特殊格式（包含project.pbxproj 二进制/JSON混合格式），不适合用文本工具直接生成。
> 请按下面步骤在 Xcode 里手动创建工程，并把文件位置映射好。

---

##1. 创建工程

1.打开 **Xcode**
2.菜单： `File` → `New` → `Project...`
3. 选择：**iOS** → **App**
4. 点击 **Next**
5.填写：
 - **Product Name**: `GameRec`
 - **Team**:你的 Apple ID（个人账号即可，未付费也能在模拟器跑）
 - **Organization Identifier**:填一个反向域名（如 `com.yourname`）
 - **Bundle Identifier**: 自动生成（如 `com.yourname.GameRec`）
 - **Interface**: **SwiftUI** ←重要
 - **Language**: **Swift**
 - **Storage**: **None**（我们手动管理）
 - **Include Tests**: ✅勾选
6. 点击 **Next**
7. **保存位置**：选 `D:\GameRec`（注意：让 Xcode 把工程文件直接放在 `D:\GameRec`根目录下）
 - ⚠️ 不要选 `D:\GameRec\GameRec` 子目录
 - 如果 Xcode 默认在子目录创建，手动移到根目录
8. 点击 **Create**

---

##2.调整工程结构

Xcode 创建后默认会有：
```
D:\GameRec\
├── GameRec.xcodeproj/
└── GameRec/ ← Xcode的源码目录
 ├── GameRecApp.swift
 ├── ContentView.swift
 ├── Assets.xcassets
 └── Preview Content/
```

我们的目标结构（**已有**）：
```
D:\GameRec\
├── docs/ ✅
├── scripts/ ✅
├── GameRec.xcodeproj/ ← Xcode创建的
├── GameRec/ ← Xcode的源码目录
└── GameRecTests/
```

**冲突处理**：我们之前已经创建了 `D:\GameRec\GameRec\Models/` 等子目录。Xcode创建的源码根目录也叫 `GameRec`。这其实正合适——让 Xcode 的 `GameRec/`目录承担"源码根"，我们预建的 `Models/` 等目录会被 Xcode 自动识别为 group。

---

##3. 在 Xcode 里创建 Group（对应目录）

在 Xcode左侧 **Project Navigator** 里：
1. 右键点击 `GameRec` group → `New Group`
2. 创建以下 group（**小写**命名，与目录对应）：
 - `Models`
 - `Data`（在 Data 下再创建子 group：`SeedData`）
 - `Services`
 - `Recommendation`
 - `Views`（在 Views 下创建：`Components`）
 - `Utils`

---

##4. 添加种子数据 JSON 到工程

1. 把后续 Step2生成的 JSON 文件（`games.json` / `categories.json` / `user_library.json`）放在 `D:\GameRec\GameRec\Data\SeedData\`
2. 在 Xcode 里：**右键 SeedData group** → **Add Files to "GameRec"...**
3.选中三个 JSON 文件
4. ⚠️重要选项：
 - **Copy items if needed**: ❌ 不勾选（已经放在目标位置）
 - **Create groups**: ✅勾选
 - **Add to targets**: ✅勾选 `GameRec`
5. 点击 **Add**

---

##5. 设置最低 iOS 版本

1. 点击左侧 **GameRec** 工程根节点
2. 中间面板选 **GameRec** target
3. **General** 选项卡 → **Minimum Deployments** → **iOS15.0**

---

##6. 删除 Xcode 默认的多余文件

Xcode 创建时默认生成：
- `ContentView.swift`（我们用自己的版本替换）
- `GameRecApp.swift`（保留，会被我们改写）
- `Assets.xcassets`（保留，会被我们改）

---

##7.验证工程能跑

1.顶部 Scheme 选择 `GameRec` →模拟器选 `iPhone15`
2. 点击 ▶️ 运行
3. 应该看到一个空白的 SwiftUI "Hello World"
4. 说明工程配置 OK ✅

---

##8.后续步骤

每完成一个 Step，我会告诉你：
- 在哪个 group 下添加哪些 `.swift` 文件
-哪些文件需要 import什么
-哪些文件需要改 `GameRecApp.swift` 的入口

---

## ⚠️注意事项

- **不要**用 Xcode 自动 rename我们的文件夹（会破坏路径）
- **不要**把 `docs/` 和 `scripts/` 加进 Xcode target（它们不属于 App bundle）
-后续如果想把 docs注释进 Xcode，可以创建 Documentation group 但不勾选 target

---

## 🆘 如果遇到问题

常见错误：
- **"No such module"** → 检查 File Inspector 的 Target Membership
- **"Cannot find type X in scope"** → 检查文件是否在正确的 group，Build Phases → Compile Sources 是否包含
- **模拟器黑屏** → Product → Clean Build Folder (⇧⌘K)，然后重启

---
