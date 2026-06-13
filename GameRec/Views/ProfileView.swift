//
//  ProfileView.swift
//  GameRec
//
//  我的：账号信息、平台账号绑定/解绑、退出登录
//

import SwiftUI

struct ProfileView: View {

    @ObservedObject private var auth = AuthManager.shared
    @State private var showBindSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Space.s3) {
                    if let user = auth.currentUser {
                        userHeader(user)
                    }
                    platformSection
                    logoutButton
                }
                .padding(Theme.Space.s2)
            }
            .background(Theme.Palette.background)
            .navigationTitle("我的")
            .sheet(isPresented: $showBindSheet) {
                BindAccountSheet()
            }
        }
    }

    // MARK: - 用户头部

    private func userHeader(_ user: UserAccount) -> some View {
        HStack(spacing: Theme.Space.s2) {
            ZStack {
                Circle()
                    .fill(Theme.Palette.primaryTint)
                    .frame(width: 64, height: 64)
                Text(String(user.username.prefix(1)).uppercased())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Palette.primary)
            }
            VStack(alignment: .leading, spacing: Theme.Space.half) {
                Text(user.username)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(user.email)
                    .font(.caption)
                    .foregroundColor(Theme.Palette.textSecondary)
            }
            Spacer()
        }
        .cardStyle()
    }

    // MARK: - 平台账号

    private var platformSection: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s2) {
            HStack {
                Text("平台账号").font(.headline)
                Spacer()
                Button {
                    showBindSheet = true
                } label: {
                    HStack(spacing: Theme.Space.half) {
                        Image(systemName: "plus.circle")
                        Text("绑定")
                    }
                    .font(.subheadline)
                    .foregroundColor(Theme.Palette.primary)
                }
            }

            if auth.platformAccounts.isEmpty {
                Text("还未绑定任何平台账号\n绑定后可同步该平台已玩游戏")
                    .font(.caption)
                    .foregroundColor(Theme.Palette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
            } else {
                ForEach(Platform.allCases, id: \.self) { platform in
                    let accounts = auth.accounts(for: platform)
                    if !accounts.isEmpty {
                        platformGroup(platform: platform, accounts: accounts)
                    }
                }
            }
        }
    }

    private func platformGroup(platform: Platform, accounts: [PlatformAccount]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.s1) {
            HStack(spacing: Theme.Space.s1) {
                Image(systemName: platform.iconName)
                    .foregroundColor(Theme.Palette.primary)
                Text(platform.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            ForEach(accounts, id: \.id) { account in
                HStack {
                    Text(account.accountName)
                        .font(.subheadline)
                        .foregroundColor(Theme.Palette.textPrimary)
                    Spacer()
                    Button {
                        auth.unbindPlatformAccount(id: account.id)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.Palette.placeholder)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - 退出登录

    private var logoutButton: some View {
        Button {
            auth.logout()
        } label: {
            Text("退出登录")
                .font(.headline)
                .foregroundColor(Theme.Palette.sale)
                .frame(maxWidth: .infinity)
                .padding(Theme.Space.s2)
                .background(Theme.Palette.surface)
                .cornerRadius(Theme.Radius.md)
        }
    }
}

// MARK: - 绑定账号弹窗

struct BindAccountSheet: View {
    @ObservedObject private var auth = AuthManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlatform: Platform = .steam
    @State private var accountName = ""

    var body: some View {
        NavigationView {
            VStack(spacing: Theme.Space.s3) {
                // 平台选择
                VStack(alignment: .leading, spacing: Theme.Space.s1) {
                    Text("选择平台").font(.headline)
                    Picker("平台", selection: $selectedPlatform) {
                        ForEach(Platform.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // 账号名
                VStack(alignment: .leading, spacing: Theme.Space.s1) {
                    Text("账号名").font(.headline)
                    TextField("输入该平台的账号名 / ID", text: $accountName)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(Theme.Space.s2)
                        .background(Theme.Palette.surface)
                        .cornerRadius(Theme.Radius.md)
                }

                Button {
                    auth.bindPlatformAccount(platform: selectedPlatform, accountName: accountName)
                    dismiss()
                } label: {
                    Text("确认绑定")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Space.s2)
                        .background(accountName.isEmpty ? Theme.Palette.placeholder : Theme.Palette.primary)
                        .cornerRadius(Theme.Radius.md)
                }
                .disabled(accountName.isEmpty)

                Spacer()
            }
            .padding(Theme.Space.s2)
            .background(Theme.Palette.background)
            .navigationTitle("绑定平台账号")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}
