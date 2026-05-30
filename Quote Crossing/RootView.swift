//
//  RootView.swift
//  Quote Crossing
//
//  App coordinator. Sends first-time players through the Badging Process
//  (CharacterCreatorView); afterwards boots straight into the overworld.
//  Gated by an AppStorage flag so the choice persists across launches.
//

import SwiftUI

struct RootView: View {
    @AppStorage("hasCreatedCharacter") private var hasCreatedCharacter = false

    var body: some View {
        ZStack {
            if hasCreatedCharacter {
                ContentView()
                    .transition(.opacity)
            } else {
                CharacterCreatorView {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        hasCreatedCharacter = true
                    }
                }
                .transition(.opacity)
            }
        }
    }
}
