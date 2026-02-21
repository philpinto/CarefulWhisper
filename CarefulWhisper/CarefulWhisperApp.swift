//
//  CarefulWhisperApp.swift
//  CarefulWhisper
//
//  Created by 906 on 2/20/26.
//

import SwiftUI
import SwiftData

@main
struct CarefulWhisperApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(
                for: Contact.self,
                     Conversation.self,
                     Message.self,
                     EncryptionKeys.self,
                     UserProfile.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
