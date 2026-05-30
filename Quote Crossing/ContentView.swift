//
//  ContentView.swift
//  Quote Crossing
//
//  The overworld screen. Composes the SpriteKit world (via SpriteView) with the
//  SwiftUI HUD on top and the virtual joystick in the bottom-left corner.
//
//  The shared game objects live in a `GameSession` (@State), so the same
//  GameState (HUD ⇄ scene) and GameInput (joystick → scene) instances are
//  wired across every layer.
//

import SwiftUI
import SpriteKit
import Combine

struct ContentView: View {
    @State private var session = GameSession()
    @State private var showWardrobe = false
    @State private var showQBR = false
    @State private var showPauseMenu = false
    @State private var showPipeDex = false
    @State private var pipeDexVM = PipeDexViewModel()
    @State private var showQBot = false
    @State private var qBotVM = QBotViewModel()

    @AppStorage("hasCreatedCharacter") private var hasCreatedCharacter = true

    private static let fiscalClock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    /// The overworld controls are live only when no full-screen UI is up.
    private var controlsEnabled: Bool {
        session.activeEncounter == nil && !showWardrobe && !showQBR && !showPauseMenu && !showPipeDex && !showQBot
    }

    var body: some View {
        ZStack {
            // SpriteKit world.
            SpriteView(
                scene: session.scene,
                options: [.ignoresSiblingOrder],
                debugOptions: spriteDebugOptions
            )
            .ignoresSafeArea()

            // HUD pinned to the top-left, action buttons top-right.
            VStack {
                HStack(alignment: .top) {
                    HUDView(state: session.state, inventory: session.inventory)
                    Spacer()
                    HStack(spacing: 12) {
                        qbotButton
                        qbrButton
                        pauseButton
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                Spacer()
            }

            // Controls: joystick (bottom-left) + actions group (bottom-right).
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    VirtualJoystick(input: session.input, enabled: controlsEnabled)
                        .padding(.leading, 28)
                    Spacer()
                    HStack(spacing: 14) {
                        pipeDexButton
                        wardrobeButton
                    }
                    .padding(.trailing, 28)
                }
                .padding(.bottom, 30)
            }

            // Slide-up wardrobe.
            if showWardrobe {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { closeWardrobe() }

                WardrobeView(
                    inventory: session.inventory,
                    avatar: session.avatar,
                    stats: session.state,
                    onEquip: { session.toggleEquip($0) },
                    onClose: { closeWardrobe() }
                )
                .padding(.top, 64)
                .transition(.move(edge: .bottom))
            }

            // Slide-up Pipe-Dex mini-game.
            if showPipeDex {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { closePipeDex() }

                PipeDexView(
                    viewModel: pipeDexVM,
                    gameState: session.state,
                    inventory: session.inventory,
                    onClose: { closePipeDex() }
                )
                .padding(.top, 40)
                .transition(.move(edge: .bottom))
                .zIndex(40)
            }

            // Slide-up Q-Bot 3000 terminal.
            if showQBot {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { closeQBot() }

                QBot3000View(
                    viewModel: qBotVM,
                    gameState: session.state,
                    onClose: { closeQBot() }
                )
                .padding(.top, 40)
                .transition(.move(edge: .bottom))
                .zIndex(45)
            }

            // Sales Encounter (turn-based battle) — covers everything while active.
            if let encounter = session.activeEncounter {
                SalesEncounterView(
                    viewModel: encounter,
                    avatar: session.avatar,
                    wearables: session.inventory.equippedItems,
                    playerName: session.avatar.name.isEmpty ? "You" : session.avatar.name
                )
                .transition(.opacity.combined(with: .scale(scale: 1.04)))
                .zIndex(10)
            }

            // Quarterly Brag Report (Digital Business Card).
            if showQBR {
                QBRView(
                    avatar: session.avatar,
                    wearables: session.inventory.equippedItems,
                    stats: qbrStats,
                    onClose: { closeQBR() }
                )
                .transition(.opacity)
                .zIndex(20)
            }

            // Pause Menu (resets career or resumes).
            if showPauseMenu {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { closePauseMenu() }

                PauseMenuView(
                    onResume: { closePauseMenu() },
                    onResetGame: { resetAndNewGame() }
                )
                .transition(.scale(scale: 0.92).combined(with: .opacity))
                .zIndex(30)
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onReceive(Self.fiscalClock) { date in
            session.state.tickFiscalClock(now: date)
        }
    }

    private var spriteDebugOptions: SpriteView.DebugOptions {
        #if DEBUG
        [.showsFPS, .showsNodeCount]
        #else
        []
        #endif
    }

    private var qbrStats: QBRStats {
        QBRStats(
            name: session.avatar.name,
            title: session.avatar.title,
            lifetimeCash: session.state.lifetimeCommishCash,
            wins: session.state.wins,
            losses: session.state.losses,
            tier: session.state.cardTier,
            fiscalLabel: session.state.fiscalMoment.qbrLabel,
            deskPlantStatus: session.state.deskPlantStatus
        )
    }

    private var qbrButton: some View {
        Button {
            session.pauseWorld()
            withAnimation(.easeInOut(duration: 0.3)) { showQBR = true }
        } label: {
            Image(systemName: "person.text.rectangle.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(colors: [Color(red: 0.55, green: 0.42, blue: 0.92),
                                            Color(red: 0.40, green: 0.30, blue: 0.78)],
                                   startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                )
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(.white.opacity(0.3), lineWidth: 2))
                .shadow(color: .black.opacity(0.25), radius: 5, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func closeQBR() {
        withAnimation(.easeInOut(duration: 0.3)) { showQBR = false }
        session.resumeWorld()
    }

    private var pauseButton: some View {
        Button {
            session.pauseWorld()
            withAnimation(.easeInOut(duration: 0.3)) { showPauseMenu = true }
        } label: {
            Image(systemName: "pause.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(colors: [Color(red: 0.28, green: 0.31, blue: 0.40),
                                            Color(red: 0.18, green: 0.20, blue: 0.26)],
                                   startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                )
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(.white.opacity(0.3), lineWidth: 2))
                .shadow(color: .black.opacity(0.25), radius: 5, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func closePauseMenu() {
        withAnimation(.easeInOut(duration: 0.3)) { showPauseMenu = false }
        session.resumeWorld()
    }

    private func resetAndNewGame() {
        // Clear career data
        UserDefaults.standard.removeObject(forKey: "player.avatar.v1")
        UserDefaults.standard.removeObject(forKey: "player.stats.v1")
        UserDefaults.standard.removeObject(forKey: "player.inventory.v1")
        
        // Return to Badging Process character creator
        withAnimation(.easeInOut(duration: 0.45)) {
            hasCreatedCharacter = false
        }
    }

    private var wardrobeButton: some View {
        Button {
            session.pauseWorld()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) { showWardrobe = true }
        } label: {
            Image(systemName: "hanger")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(colors: [Color(red: 0.22, green: 0.62, blue: 0.55),
                                            Color(red: 0.14, green: 0.50, blue: 0.45)],
                                   startPoint: .top, endPoint: .bottom),
                    in: Circle()
                )
                .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 2))
                .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func closeWardrobe() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) { showWardrobe = false }
        session.resumeWorld()
    }

    private var pipeDexButton: some View {
        Button {
            session.pauseWorld()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) { showPipeDex = true }
        } label: {
            Image(systemName: "funnel.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(colors: [Color(red: 0.28, green: 0.52, blue: 0.92),
                                            Color(red: 0.18, green: 0.38, blue: 0.80)],
                                   startPoint: .top, endPoint: .bottom),
                    in: Circle()
                )
                .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 2))
                .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func closePipeDex() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) { showPipeDex = false }
        session.resumeWorld()
    }

    private var qbotButton: some View {
        Button {
            session.pauseWorld()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) { showQBot = true }
        } label: {
            Image(systemName: "cpu.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(colors: [Color.orange, Color(red: 0.85, green: 0.45, blue: 0.10)],
                                   startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                )
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(.white.opacity(0.3), lineWidth: 2))
                .shadow(color: .black.opacity(0.25), radius: 5, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func closeQBot() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) { showQBot = false }
        session.resumeWorld()
    }
}

#Preview {
    ContentView()
}
