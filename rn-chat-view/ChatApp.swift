//
//  rn_chat_viewApp.swift
//  rn-chat-view
//
//  Created by Andrei on 02.04.2026.
//

import SwiftUI

@main
struct ChatApp: App {
    init() {
        UIApplication.shared.isIdleTimerDisabled = true
    }

    var body: some Scene {
        WindowGroup {
            DemoTabView()
                .ignoresSafeArea()
        }
    }
}

// MARK: - Tab Bar

struct DemoTabView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UITabBarController {
        let tab = UITabBarController()
        tab.tabBar.isTranslucent = true

        let chatDemo = ChatDemoViewController()
        chatDemo.tabBarItem = UITabBarItem(title: "Чат", image: UIImage(systemName: "bubble.left.fill"), tag: 0)

        let paginationDemo = PaginationDemoViewController()
        paginationDemo.tabBarItem = UITabBarItem(title: "Пагинация", image: UIImage(systemName: "arrow.up.arrow.down"), tag: 1)

        let liveDemo = LiveChatDemoViewController()
        liveDemo.tabBarItem = UITabBarItem(title: "Живой чат", image: UIImage(systemName: "bolt.fill"), tag: 2)

        tab.viewControllers = [chatDemo, paginationDemo, liveDemo]
        return tab
    }

    func updateUIViewController(_ vc: UITabBarController, context: Context) {}
}
