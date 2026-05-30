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

    var baseRadius: CGFloat = 52
    var thumbRadius: CGFloat = 23

    @State private var thumbOffset: CGSize = .zero
    @State private var isActive = false

    var body: some View {
        ZStack {
            // Base ring.
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().strokeBorder(.white.opacity(0.24), lineWidth: 1.5))
                .shadow(color: .black.opacity(0.16), radius: 12, y: 7)

            // Faint cardinal tick marks.
            ForEach(0..<4) { i in
                Capsule()
                    .fill(.white.opacity(0.14))
                    .frame(width: 3, height: 10)
                    .offset(y: -(baseRadius - 12))
                    .rotationEffect(.degrees(Double(i) * 90))
            }

            // Thumb.
            Circle()
                .fill(
                    LinearGradient(colors: [.white.opacity(isActive ? 0.98 : 0.82),
                                            QuotaOS.Colors.porcelain.opacity(isActive ? 0.92 : 0.72)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .overlay(Circle().strokeBorder(.black.opacity(0.08), lineWidth: 1.5))
                .frame(width: thumbRadius * 2, height: thumbRadius * 2)
                .offset(thumbOffset)
                .shadow(color: .black.opacity(0.22), radius: 5, y: 3)
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

struct GestureJoystickSurface: View {
    let input: GameInput
    var enabled: Bool = true

    @State private var origin: CGPoint?
    @State private var thumbOffset: CGSize = .zero
    @State private var isActive = false
    @State private var isVisible = false
    @State private var fadeToken = UUID()

    private let radius: CGFloat = 70
    private let thumbRadius: CGFloat = 24

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged(handleDragChanged)
                        .onEnded(handleDragEnded)
                )

            if let origin, isVisible {
                joystickVisual
                    .position(origin)
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                    .allowsHitTesting(false)
            }
        }
        .allowsHitTesting(enabled)
        .onChange(of: enabled) { _, isEnabled in
            if !isEnabled {
                input.movement = .zero
                isActive = false
                isVisible = false
                origin = nil
                thumbOffset = .zero
            }
        }
    }

    private var joystickVisual: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().strokeBorder(.white.opacity(0.26), lineWidth: 1.4))
                .frame(width: radius * 2, height: radius * 2)
                .shadow(color: .black.opacity(0.20), radius: 18, y: 9)

            ForEach(0..<4) { i in
                Capsule()
                    .fill(.white.opacity(0.14))
                    .frame(width: 3, height: 12)
                    .offset(y: -(radius - 14))
                    .rotationEffect(.degrees(Double(i) * 90))
            }

            Circle()
                .fill(
                    LinearGradient(colors: [.white.opacity(isActive ? 0.98 : 0.86),
                                            QuotaOS.Colors.porcelain.opacity(0.78)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .overlay(Circle().strokeBorder(.black.opacity(0.08), lineWidth: 1.5))
                .frame(width: thumbRadius * 2, height: thumbRadius * 2)
                .offset(thumbOffset)
                .shadow(color: .black.opacity(0.22), radius: 6, y: 3)
        }
        .opacity(isActive ? 1 : 0.72)
    }

    private func handleDragChanged(_ value: DragGesture.Value) {
        guard enabled else { return }
        if origin == nil {
            origin = value.startLocation
            thumbOffset = .zero
        }
        fadeToken = UUID()
        isActive = true
        withAnimation(.easeOut(duration: 0.12)) {
            isVisible = true
        }
        update(to: value.location)
    }

    private func handleDragEnded(_: DragGesture.Value) {
        guard enabled else { return }
        input.movement = .zero
        isActive = false
        let token = UUID()
        fadeToken = token

        withAnimation(.spring(response: 0.25, dampingFraction: 0.66)) {
            thumbOffset = .zero
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            guard fadeToken == token, !isActive else { return }
            withAnimation(.easeOut(duration: 0.35)) {
                isVisible = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.65) {
            guard fadeToken == token, !isActive else { return }
            origin = nil
        }
    }

    private func update(to location: CGPoint) {
        guard let origin else { return }
        let dx = location.x - origin.x
        let dy = location.y - origin.y
        let distance = max(hypot(dx, dy), 0.0001)
        let clamped = min(distance, radius)

        let nx = dx / distance
        let ny = dy / distance
        let magnitude = clamped / radius

        thumbOffset = CGSize(width: nx * clamped, height: ny * clamped)
        input.movement = CGVector(dx: nx * magnitude, dy: -ny * magnitude)
    }
}
