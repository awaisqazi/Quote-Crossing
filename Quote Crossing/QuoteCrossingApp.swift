//
//  QuoteCrossingApp.swift
//  Quote Crossing
//
//  SwiftUI App entry point. Hosts a SpriteKit scene (OverworldScene) behind a
//  SwiftUI HUD + virtual joystick. See ContentView for the composition.
//

import SwiftUI

@main
struct QuoteCrossingApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
