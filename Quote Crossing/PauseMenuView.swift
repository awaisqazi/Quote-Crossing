//
//  PauseMenuView.swift
//  Quote Crossing
//
//  Created for Quote Crossing on 2026-05-30.
//  A beautiful corporate-themed pause menu that supports resuming the game
//  or resetting the career data (signing the pink slip) to start a new game.
//

import SwiftUI

struct PauseMenuView: View {
    var onResume: () -> Void
    var onResetGame: () -> Void

    @State private var showConfirmReset = false
    @State private var isAnimating = false

    private let avatarSnapshot = AvatarStore.load()
    private let statsSnapshot = StatsStore.load()

    var body: some View {
        VStack(spacing: 24) {
            if !showConfirmReset {
                standardMenu
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                confirmResetMenu
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .padding(30)
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1.5)
        )
        .scaleEffect(isAnimating ? 1.0 : 0.95)
        .opacity(isAnimating ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                isAnimating = true
            }
        }
    }

    // MARK: - Main Pause Layout

    private var standardMenu: some View {
        VStack(spacing: 22) {
            // Header
            VStack(spacing: 6) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(red: 0.55, green: 0.42, blue: 0.92),
                                                Color(red: 0.40, green: 0.30, blue: 0.78)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                
                Text("SYSTEM PAUSED")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(1.0)
            }
            
            // Career Summary Card
            if let avatar = avatarSnapshot {
                VStack(spacing: 10) {
                    Text(avatar.name)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(avatar.title)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Divider()
                        .background(.white.opacity(0.15))
                        .padding(.vertical, 4)
                    
                    HStack(spacing: 24) {
                        VStack(spacing: 3) {
                            Text("COMMISH-CASH")
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                            Text("$\(statsSnapshot?.commishCash ?? 1250)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(red: 0.22, green: 0.80, blue: 0.56))
                        }
                        
                        VStack(spacing: 3) {
                            Text("CAREER RECORD")
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                            Text("\(statsSnapshot?.wins ?? 0)W · \(statsSnapshot?.losses ?? 0)L")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(red: 0.30, green: 0.55, blue: 0.95))
                        }
                    }
                }
                .padding(16)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
            }

            // Navigation Buttons
            VStack(spacing: 12) {
                // Resume
                Button(action: onResume) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Resume Career")
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [Color(red: 0.30, green: 0.55, blue: 0.95),
                                                Color(red: 0.21, green: 0.42, blue: 0.86)],
                                       startPoint: .top, endPoint: .bottom),
                        in: Capsule()
                    )
                    .shadow(color: Color(red: 0.21, green: 0.42, blue: 0.86).opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                
                // Quit & Start New
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                        showConfirmReset = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "doc.text.badge.gearshape")
                        Text("Resign from OmniTech")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        Color.white.opacity(0.08),
                        in: Capsule()
                    )
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Reset Confirmation Layout

    private var confirmResetMenu: some View {
        VStack(spacing: 22) {
            // Header
            VStack(spacing: 6) {
                Image(systemName: "exclamationmark.octagon.fill")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(red: 0.92, green: 0.30, blue: 0.35),
                                                Color(red: 0.78, green: 0.16, blue: 0.22)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                
                Text("EXIT INTERVIEW")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(1.0)
            }
            
            // HR Consequences Warning
            VStack(alignment: .leading, spacing: 10) {
                Text("Official Notification:")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                
                Text("Are you absolutely sure you want to resign? HR will instantly shred all of your custom fleece vests, your current Commish-Cash, and wipe your synergy records from the regional database.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .background(Color(red: 0.40, green: 0.08, blue: 0.12).opacity(0.35), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(red: 0.92, green: 0.30, blue: 0.35).opacity(0.25), lineWidth: 1.5)
            )

            // Decisions
            VStack(spacing: 12) {
                // Pink slip reset
                Button(action: onResetGame) {
                    HStack {
                        Image(systemName: "signature")
                        Text("Sign Pink Slip (Reset)")
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [Color(red: 0.92, green: 0.30, blue: 0.35),
                                                Color(red: 0.78, green: 0.16, blue: 0.22)],
                                       startPoint: .top, endPoint: .bottom),
                        in: Capsule()
                    )
                    .shadow(color: Color(red: 0.78, green: 0.16, blue: 0.22).opacity(0.35), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                
                // Cancel
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                        showConfirmReset = false
                    }
                } label: {
                    Text("Cancel & Return to Work")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            Color.white.opacity(0.08),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .stroke(.white.opacity(0.12), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.65)
            .ignoresSafeArea()
        PauseMenuView(onResume: {}, onResetGame: {})
    }
}
