//
//  GameRecApp.swift
//  GameRec
//
//  App 入口
//

import SwiftUI

@main
struct GameRecApp: App {

    init() {
        // 首次启动从种子数据初始化用户数据
        DataStore.shared.initializeUserDataIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
