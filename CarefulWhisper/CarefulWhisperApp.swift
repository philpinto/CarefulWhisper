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
    @State private var appServices = AppServices()
    
    init() {
        do {
            modelContainer = try ModelContainer(
                for: Contact.self,
                     Conversation.self,
                     Message.self,
                     EncryptionKeys.self,
                     UserProfile.self,
                     ContactRequest.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(\.appServices, appServices)
                .onAppear {
                    // Configure services synchronously before any child views load
                    appServices.configure(with: modelContainer.mainContext)
                }
        }
    }
}
