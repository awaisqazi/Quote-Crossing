//
//  VirtualJoystick.swift
//  Quote Crossing
//
//  On-screen analog D-pad. Writes a normalised movement vector into the shared
//  GameInput (which the scene polls each frame). Supports full 360° analog
//  movement — the eight cardinal/diagonal directions and everything between.
//

import SwiftUI

struct VirtualJoystick: View {
    /// Shared input sink the scene reads from.
    let input: GameInput

    /// When false (e.g. a menu/battle is up) the stick ignores drags and
    /// re-centres, so a finger held through a pause can't leak stale movement.
    var enabled: Bool = true

    var baseRadius: CGFloat = 64
    var thumbRadius: CGFloat = 30

    @State private var thumbOffset: CGSize = .zero
    @State private var isActive = false

    var body: some View {
        ZStack {
            // Base ring.
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 2))

            // Faint cardinal tick marks.
            ForEach(0..<4) { i in
                Capsule()
                    .fill(.white.opacity(0.18))
                    .frame(width: 3, height: 10)
                    .offset(y: -(baseRadius - 12))
                    .rotationEffect(.degrees(Double(i) * 90))
            }

            // Thumb.
            Circle()
                .fill(.white.opacity(isActive ? 0.95 : 0.75))
                .overlay(Circle().strokeBorder(.black.opacity(0.12), lineWidth: 2))
                .frame(width: thumbRadius * 2, height: thumbRadius * 2)
                .offset(thumbOffset)
                .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
        }
        .frame(width: baseRadius * 2, height: baseRadius * 2)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard enabled else { return }
                    isActive = true
                    update(to: value.location)
                }
                .onEnded { _ in
                    isActive = false
                    input.movement = .zero
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                        thumbOffset = .zero
                    }
                }
        )
        .opacity(enabled ? 1 : 0.5)
        .onChange(of: enabled) { _, isEnabled in
            if !isEnabled {
                isActive = false
                input.movement = .zero
                thumbOffset = .zero
            }
        }
        .animation(.easeOut(duration: 0.08), value: isActive)
    }

    /// `location` is in the joystick's local space (origin top-left).
    private func update(to location: CGPoint) {
        let dx = location.x - baseRadius
        let dy = location.y - baseRadius
        let distance = max(hypot(dx, dy), 0.0001)
        let clamped = min(distance, baseRadius)

        let nx = dx / distance        // unit direction
        let ny = dy / distance
        let magnitude = clamped / baseRadius   // 0...1 analog strength

        thumbOffset = CGSize(width: nx * clamped, height: ny * clamped)

        // Flip Y: SwiftUI is y-down, SpriteKit is y-up.
        input.movement = CGVector(dx: nx * magnitude, dy: -ny * magnitude)
    }
}
