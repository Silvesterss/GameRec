//
//  AuthManager.swift
//  GameRec
//
//  登录/注册 + 多平台账号绑定（本地实现，无后端）
//
//  ⚠️ 安全说明：本实现把账号信息明文存在本地 Documents，仅用于学习/演示。
//  生产环境必须：密码加盐哈希、走后端鉴权、平台账号通过各平台 OAuth 授权绑定。
//

import Foundation
import Combine

@MainActor
final class AuthManager: ObservableObject {

    static let shared = AuthManager()

    // MARK: - 发布状态

    @Published private(set) var currentUser: UserAccount?
    @Published private(set) var platformAccounts: [PlatformAccount] = []

    /// 是否已登录
    var isLoggedIn: Bool { currentUser != nil }

    // MARK: - 持久化文件名

    private let dataStore = DataStore.shared
    private let usersFile = "accounts.json"             // 所有注册用户
    private let sessionFile = "session.json"            // 当前登录用户 id
    private let platformAccountsFile = "platform_accounts.json"

    private init() {
        restoreSession()
    }

    // MARK: - 注册

    enum AuthError: LocalizedError {
        case emailTaken
        case userNotFound
        case wrongPassword
        case emptyField

        var errorDescription: String? {
            switch self {
            case .emailTaken: return "该邮箱已被注册"
            case .userNotFound: return "账号不存在"
            case .wrongPassword: return "密码不正确"
            case .emptyField: return "请填写完整信息"
            }
        }
    }

    /// 注册新用户
    func register(username: String, email: String, password: String) throws {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            throw AuthError.emptyField
        }

        var users = loadUsers()
        guard !users.contains(where: { $0.email.lowercased() == email.lowercased() }) else {
            throw AuthError.emailTaken
        }

        let newUser = UserAccount(username: username, email: email, password: password)
        users.append(newUser)
        saveUsers(users)

        // 注册后自动登录
        setSession(user: newUser)
    }

    // MARK: - 登录

    /// 邮箱 + 密码登录
    func login(email: String, password: String) throws {
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.emptyField
        }

        let users = loadUsers()
        guard let user = users.first(where: { $0.email.lowercased() == email.lowercased() }) else {
            throw AuthError.userNotFound
        }
        guard user.password == password else {
            throw AuthError.wrongPassword
        }

        setSession(user: user)
    }

    /// 退出登录
    func logout() {
        currentUser = nil
        platformAccounts = []
        try? dataStore.deleteUserData(filename: sessionFile)
    }

    // MARK: - 平台账号绑定

    /// 绑定平台账号（同平台可绑多个）
    func bindPlatformAccount(platform: Platform, accountName: String) {
        guard !accountName.isEmpty else { return }
        let account = PlatformAccount(platform: platform, accountName: accountName)

        // 去重：同 id 不重复
        guard !platformAccounts.contains(where: { $0.id == account.id }) else { return }
        platformAccounts.append(account)
        savePlatformAccounts()
    }

    /// 解绑平台账号
    func unbindPlatformAccount(id: String) {
        platformAccounts.removeAll { $0.id == id }
        savePlatformAccounts()
    }

    /// 按平台分组的已绑定账号
    func accounts(for platform: Platform) -> [PlatformAccount] {
        platformAccounts.filter { $0.platform == platform }
    }

    // MARK: - 私有：会话与持久化

    private func setSession(user: UserAccount) {
        currentUser = user
        try? dataStore.saveUserData(["userId": user.id], filename: sessionFile)
        loadPlatformAccounts()
    }

    private func restoreSession() {
        guard let session = try? dataStore.loadUserData([String: String].self, filename: sessionFile),
              let userId = session["userId"] else {
            return
        }
        let users = loadUsers()
        currentUser = users.first(where: { $0.id == userId })
        loadPlatformAccounts()
    }

    private func loadUsers() -> [UserAccount] {
        (try? dataStore.loadUserData([UserAccount].self, filename: usersFile)) ?? []
    }

    private func saveUsers(_ users: [UserAccount]) {
        try? dataStore.saveUserData(users, filename: usersFile)
    }

    private func loadPlatformAccounts() {
        platformAccounts = (try? dataStore.loadUserData([PlatformAccount].self, filename: platformAccountsFile)) ?? []
    }

    private func savePlatformAccounts() {
        try? dataStore.saveUserData(platformAccounts, filename: platformAccountsFile)
    }
}
