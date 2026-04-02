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
        #if DEBUG
        AudioCache.shared.removeAll()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ChatDemoView()
                .ignoresSafeArea()
        }
    }
}
