//
//  MainTabView.swift
//  GameRec
//
//  底部 Tab 导航：首页 / 游戏库 / 我的
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }

            LibraryView()
                .tabItem {
                    Label("游戏库", systemImage: "books.vertical.fill")
                }

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
        }
        .tint(Theme.Palette.primary)
    }
}
