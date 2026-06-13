//
//  RootView.swift
//  GameRec
//
//  根视图：根据登录状态切换「登录页」/「主界面」
//

import SwiftUI

struct RootView: View {
    @ObservedObject private var auth = AuthManager.shared

    var body: some View {
        Group {
            if auth.isLoggedIn {
                MainTabView()
            } else {
                AuthView()
            }
        }
    }
}
