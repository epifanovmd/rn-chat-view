//
//  rn_chat_viewApp.swift
//  rn-chat-view
//
//  Created by Andrei on 02.04.2026.
//

import IOSChatView
import SwiftUI

@main
struct ChatApp: App {
    init() {
        UIApplication.shared.isIdleTimerDisabled = true
    }

    var body: some Scene {
        WindowGroup {
            DemoChatView()
                .ignoresSafeArea()
        }
    }
}

// MARK: - Tab Bar

struct DemoChatView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let tabBar = UITabBarController()
        tabBar.tabBar.isTranslucent = false
        tabBar.tabBar.barStyle = .black

        let standard = ChatDemoViewController()
        standard.tabBarItem = UITabBarItem(title: "Standard", image: UIImage(systemName: "bubble.left.and.bubble.right"), tag: 0)

        let custom = CustomChatDemoViewController()
        custom.tabBarItem = UITabBarItem(title: "Custom", image: UIImage(systemName: "paintbrush"), tag: 1)

        tabBar.viewControllers = [standard, custom]
        return tabBar
    }

    func updateUIViewController(_ vc: UIViewController, context: Context) {}
}
