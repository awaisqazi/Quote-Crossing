//
//  GameInput.swift
//  Quote Crossing
//
//  Lightweight bridge between the SwiftUI virtual joystick and the SpriteKit
//  scene. The joystick *writes* the latest analog vector; the scene *polls* it
//  once per frame in `update(_:)`.
//
//  Deliberately NOT @Observable: the scene reads it every frame, so we don't
//  want SwiftUI invalidating views 60×/second. It's a plain shared reference.
//

import CoreGraphics

final class GameInput {
    /// Normalised movement vector.
    /// - Magnitude is `0...1` (0 = idle, 1 = full deflection → variable analog speed).
    /// - Already converted to SpriteKit space: `+dy` is up, `-dy` is down.
    var movement: CGVector = .zero
}
