//
//  GameTheme.swift
//  Quote Crossing
//
//  Central tuning + palette shared between the SpriteKit world and the SwiftUI
//  overlay. Keeping these in one place makes the "bright, flat-vector" art
//  direction easy to iterate on.
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

/// Flat-vector colour palette. SpriteKit side uses `SKColor` (== `UIColor` on iOS).
enum Palette {
    // World
    static let sceneBackground = SKColor(red: 0.13, green: 0.15, blue: 0.20, alpha: 1)

    static let floor      = SKColor(red: 0.91, green: 0.92, blue: 0.95, alpha: 1)
    static let floorLine  = SKColor(red: 0.83, green: 0.85, blue: 0.91, alpha: 1)

    static let wall       = SKColor(red: 0.27, green: 0.31, blue: 0.42, alpha: 1)
    static let wallTop    = SKColor(red: 0.37, green: 0.42, blue: 0.55, alpha: 1)

    static let lounge      = SKColor(red: 0.58, green: 0.80, blue: 0.50, alpha: 1)
    static let loungeBlade = SKColor(red: 0.39, green: 0.65, blue: 0.35, alpha: 1)

    // Player
    static let playerFill   = SKColor(red: 0.99, green: 0.78, blue: 0.36, alpha: 1)
    static let playerStroke = SKColor(red: 0.20, green: 0.22, blue: 0.30, alpha: 1)
}
