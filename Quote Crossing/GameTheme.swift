//
//  GameTheme.swift
//  Quote Crossing
//
//  Central tuning + palette shared between the SpriteKit world and the SwiftUI
//  overlay.
//

import SpriteKit
import SwiftUI

/// World geometry and movement/camera tuning constants.
enum GameMetrics {
    /// Edge length of a single map tile, in points.
    static let tileSize: CGFloat = 64

    static let mapColumns = 30
    static let mapRows = 30

    static var worldWidth: CGFloat { tileSize * CGFloat(mapColumns) }
    static var worldHeight: CGFloat { tileSize * CGFloat(mapRows) }

    /// Player speed at full joystick deflection (points / second).
    static let playerSpeed: CGFloat = 340

    /// Movement feels slower while wading through the Networking Lounge grass.
    static let loungeSlowFactor: CGFloat = 0.6

    /// 0...1 — how aggressively velocity chases the target each frame (accel/decel feel).
    static let moveLerp: CGFloat = 0.30

    /// 0...1 — how aggressively the camera chases the player each frame (follow smoothing).
    static let cameraLerp: CGFloat = 0.12
}

/// Physics collision/contact categories (bit masks).
enum PhysicsCategory {
    static let none: UInt32   = 0
    static let player: UInt32 = 1 << 0
    static let wall: UInt32   = 1 << 1
    static let lounge: UInt32 = 1 << 2
}

/// SpriteKit side uses `SKColor` (== `UIColor` on iOS).
enum Palette {
    // World
    static let sceneBackground = SKColor(red: 0.91, green: 0.95, blue: 0.98, alpha: 1)

    static let floor      = SKColor(red: 0.89, green: 0.95, blue: 0.98, alpha: 1)
    static let floorGlow  = SKColor(red: 0.96, green: 0.99, blue: 1.00, alpha: 1)
    static let floorLine  = SKColor(red: 0.73, green: 0.78, blue: 0.90, alpha: 1)
    static let floorWarm  = SKColor(red: 0.99, green: 0.92, blue: 0.84, alpha: 1)

    static let wall       = SKColor(red: 0.72, green: 0.74, blue: 0.91, alpha: 1)
    static let wallTop    = SKColor(red: 0.98, green: 0.70, blue: 0.80, alpha: 1)
    static let wallShadow = SKColor(red: 0.27, green: 0.18, blue: 0.36, alpha: 0.30)
    static let wallBrass  = SKColor(red: 0.98, green: 0.78, blue: 0.42, alpha: 1)

    static let carpet      = SKColor(red: 0.73, green: 0.91, blue: 0.88, alpha: 1)
    static let carpetLine  = SKColor(red: 0.54, green: 0.74, blue: 0.92, alpha: 1)
    static let carpetGold  = SKColor(red: 0.98, green: 0.82, blue: 0.48, alpha: 1)
    static let carpetWine  = SKColor(red: 0.86, green: 0.74, blue: 0.94, alpha: 1)

    static let lounge      = SKColor(red: 0.54, green: 0.86, blue: 0.60, alpha: 1)
    static let loungeBlade = SKColor(red: 0.77, green: 0.96, blue: 0.66, alpha: 1)
    static let plantDark   = SKColor(red: 0.25, green: 0.58, blue: 0.40, alpha: 1)
    static let plantLight  = SKColor(red: 0.67, green: 0.91, blue: 0.72, alpha: 1)
    static let fixtureInk  = SKColor(red: 0.16, green: 0.09, blue: 0.20, alpha: 1)
    static let fixtureTop  = SKColor(red: 0.99, green: 0.96, blue: 0.90, alpha: 1)
    static let glass       = SKColor(red: 0.62, green: 0.88, blue: 0.95, alpha: 0.64)
    static let shadow      = SKColor(red: 0.18, green: 0.10, blue: 0.22, alpha: 0.20)

    // Player
    static let playerFill   = SKColor(red: 0.99, green: 0.78, blue: 0.36, alpha: 1)
    static let playerStroke = SKColor(red: 0.15, green: 0.08, blue: 0.18, alpha: 1)
}
