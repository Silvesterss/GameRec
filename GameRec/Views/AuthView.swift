//
//  AuthView.swift
//  GameRec
//
//  登录 / 注册页
//

import SwiftUI

struct AuthView: View {

    @ObservedObject private var auth = AuthManager.shared

    @State private var isRegisterMode = false
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Space.s3) {

                    // Logo 区
                    VStack(spacing: Theme.Space.s1) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: Theme.Space.s5 + Theme.Space.s2))
                            .foregroundColor(Theme.Palette.primary)
                        Text("GameRec")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("发现下一款想玩的游戏")
                            .font(.caption)
                            .foregroundColor(Theme.Palette.textSecondary)
                    }
                    .padding(.top, Theme.Space.s5)

                    // 表单
                    VStack(spacing: Theme.Space.s2) {
                        if isRegisterMode {
                            inputField(icon: "person", placeholder: "用户名", text: $username)
                        }
                        inputField(icon: "envelope", placeholder: "邮箱", text: $email, keyboard: .emailAddress)
                        inputField(icon: "lock", placeholder: "密码", text: $password, isSecure: true)

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(Theme.Palette.sale)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: submit) {
                            Text(isRegisterMode ? "注册并登录" : "登录")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(Theme.Space.s2)
                                .background(Theme.Palette.primary)
                                .cornerRadius(Theme.Radius.md)
                        }

                        Button {
                            withAnimation { isRegisterMode.toggle(); errorMessage = nil }
                        } label: {
                            Text(isRegisterMode ? "已有账号？去登录" : "没有账号？去注册")
                                .font(.subheadline)
                                .foregroundColor(Theme.Palette.primary)
                        }
                    }
                    .padding(.horizontal, Theme.Space.s2)
                }
                .padding(.bottom, Theme.Space.s4)
            }
            .background(Theme.Palette.background)
            .navigationTitle(isRegisterMode ? "注册" : "登录")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - 输入框

    private func inputField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        HStack(spacing: Theme.Space.s1) {
            Image(systemName: icon)
                .foregroundColor(Theme.Palette.textSecondary)
                .frame(width: Theme.Space.s3)
            if isSecure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
        .padding(Theme.Space.s2)
        .background(Theme.Palette.surface)
        .cornerRadius(Theme.Radius.md)
    }

    // MARK: - 提交

    private func submit() {
        errorMessage = nil
        do {
            if isRegisterMode {
                try auth.register(username: username, email: email, password: password)
            } else {
                try auth.login(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
