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
        let chatDemo = ChatDemoViewController()
        return chatDemo
    }

    func updateUIViewController(_ vc: UIViewController, context: Context) {}
}
