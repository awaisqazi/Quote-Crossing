//
//  ContentView.swift
//  Quote Crossing
//
//  Overworld shell plus the Quota OS route coordinator.
//

import SwiftUI
import SpriteKit
import Combine

struct ContentView: View {
    @State private var session = GameSession()
    @State private var activeRoute: GameRoute? = Self.debugInitialRoute
    @State private var pipeDexVM = PipeDexViewModel()
    @State private var qBotVM = QBotViewModel()
    @State private var isCommandDeckCollapsed = true

    @AppStorage("hasCreatedCharacter") private var hasCreatedCharacter = true

    private static let fiscalClock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var controlsEnabled: Bool {
        session.activeEncounter == nil && activeRoute == nil
    }

    var body: some View {
        ZStack {
            SpriteView(
                scene: session.scene,
                options: [.ignoresSiblingOrder],
                debugOptions: spriteDebugOptions
            )
            .ignoresSafeArea()

            GestureJoystickSurface(input: session.input, enabled: controlsEnabled)
                .ignoresSafeArea()

            if activeRoute == nil && session.activeEncounter == nil {
                overworldHUD
                    .transition(.opacity)
                overworldControls
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let route = activeRoute {
                routeOverlay(route)
                    .zIndex(50)
            }

            if let encounter = session.activeEncounter {
                SalesEncounterView(
                    viewModel: encounter,
                    avatar: session.avatar,
                    wearables: session.inventory.equippedItems,
                    playerName: session.avatar.name.isEmpty ? "You" : session.avatar.name
                )
                .transition(.opacity.combined(with: .scale(scale: 1.04)))
                .zIndex(80)
            }
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onReceive(Self.fiscalClock) { date in
            session.state.tickFiscalClock(now: date)
        }
        .onAppear {
            if activeRoute != nil {
                session.pauseWorld()
            }
        }
    }

    private static var debugInitialRoute: GameRoute? {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard let keyIndex = arguments.firstIndex(of: "-QuotaDebugRoute"),
              arguments.indices.contains(arguments.index(after: keyIndex)) else {
            return nil
        }
        return GameRoute(rawValue: arguments[arguments.index(after: keyIndex)])
        #else
        return nil
        #endif
    }

    private var overworldHUD: some View {
        VStack {
            TopCommandBanner(state: session.state,
                             open: openRoute)
            Spacer()
        }
        .ignoresSafeArea(.container, edges: .top)
        .allowsHitTesting(controlsEnabled)
    }

    private var overworldControls: some View {
        VStack {
            Spacer()
            CareerCommandDeck(state: session.state,
                              nearbyEntrance: session.nearbyEntrance,
                              isCollapsed: $isCommandDeckCollapsed,
                              open: openRoute)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    @ViewBuilder
    private func routeOverlay(_ route: GameRoute) -> some View {
        ZStack {
            routeBackdrop(for: route)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    if route != .pause { closeRoute() }
                }

            routeContent(route)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, route == .wardrobe ? 64 : 0)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private func routeBackdrop(for route: GameRoute) -> some View {
        if route == .qBot || route == .pipeDex || route == .qbr {
            QuotaBackdrop(tint: route.tint, tone: .campus)
        } else {
            Color.black.opacity(0.52)
        }
    }

    @ViewBuilder
    private func routeContent(_ route: GameRoute) -> some View {
        switch route {
        case .careerHub:
            CareerHubView(state: session.state, inventory: session.inventory, open: switchRoute, onClose: closeRoute)
        case .prospecting:
            ProspectingView(gameState: session.state, pipeDex: pipeDexVM, onClose: closeRoute)
        case .pipeDex:
            PipeDexView(viewModel: pipeDexVM, gameState: session.state, inventory: session.inventory, onClose: closeRoute)
                .padding(.top, 6)
        case .qBot:
            QBot3000View(viewModel: qBotVM, gameState: session.state, onClose: closeRoute)
                .padding(.top, 6)
        case .bidDesk:
            BidDeskDungeonView(gameState: session.state, onClose: closeRoute)
        case .cubicleBuilder:
            CubicleBuilderView(onClose: closeRoute)
        case .expenseRun:
            ExpenseRunView(gameState: session.state, onClose: closeRoute)
        case .treasury:
            CorporateTreasuryView(gameState: session.state, onClose: closeRoute)
        case .outfitter:
            CorporateOutfitterView(gameState: session.state, inventory: session.inventory, onClose: closeRoute)
        case .swagVending:
            SwagVendingView(gameState: session.state, inventory: session.inventory, onClose: closeRoute)
        case .wardrobe:
            WardrobeView(
                inventory: session.inventory,
                avatar: session.avatar,
                stats: session.state,
                onEquip: { session.toggleEquip($0) },
                onClose: closeRoute
            )
        case .socialLinks:
            SocialLinksView(gameState: session.state,
                            inventory: session.inventory,
                            avatar: session.avatar,
                            stats: qbrStats,
                            onClose: closeRoute)
        case .qbr:
            QBRView(
                avatar: session.avatar,
                wearables: session.inventory.equippedItems,
                stats: qbrStats,
                onClose: closeRoute
            )
        case .endgame:
            EndgameView(gameState: session.state, onClose: closeRoute)
        case .pause:
            PauseMenuView(onResume: closeRoute, onResetGame: resetAndNewGame)
                .transition(.scale(scale: 0.92).combined(with: .opacity))
        }
    }

    private func openRoute(_ route: GameRoute) {
        session.pauseWorld()
        session.state.openRoute(route)
        withAnimation(QuotaOS.spring) { activeRoute = route }
    }

    private func switchRoute(_ route: GameRoute) {
        session.state.openRoute(route)
        withAnimation(QuotaOS.spring) { activeRoute = route }
    }

    private func closeRoute() {
        if activeRoute == .cubicleBuilder {
            session.state.completeCareerStep(.cubicleBase)
            session.scene.refreshOfficeMarkers()
        }
        if activeRoute == .qbr || activeRoute == .socialLinks { session.state.completeCareerStep(.qbrSocial) }
        withAnimation(QuotaOS.spring) { activeRoute = nil }
        session.resumeWorld()
    }

    private func resetAndNewGame() {
        UserDefaults.standard.removeObject(forKey: "player.avatar.v1")
        UserDefaults.standard.removeObject(forKey: "player.stats.v1")
        UserDefaults.standard.removeObject(forKey: "player.inventory.v1")
        UserDefaults.standard.removeObject(forKey: "player.pipedex.grid.v1")
        UserDefaults.standard.removeObject(forKey: "player.qbot.tray.v1")
        UserDefaults.standard.removeObject(forKey: "player.qbot.quotes.v1")
        UserDefaults.standard.removeObject(forKey: "player.cubicle.layout.v1")

        withAnimation(.easeInOut(duration: 0.45)) {
            hasCreatedCharacter = false
        }
    }

    private var spriteDebugOptions: SpriteView.DebugOptions {
        []
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
}

private struct TopCommandBanner: View {
    var state: GameState
    var open: (GameRoute) -> Void

    @GestureState private var drawerPull: CGFloat = 0

    private static let pausePullThreshold: CGFloat = 44

    private var bandwidthFraction: Double {
        guard state.maxBandwidth > 0 else { return 0 }
        return Double(state.bandwidth) / Double(state.maxBandwidth)
    }

    private var easedDrawerPull: CGFloat {
        min(drawerPull, 34)
    }

    private var pullProgress: CGFloat {
        min(1, drawerPull / 54)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            SlidingTopPaneShape(cornerRadius: 34)
                .fill(QuotaOS.Colors.campusPaper)
            SlidingTopPaneShape(cornerRadius: 34)
                .fill(
                    LinearGradient(colors: [
                        Color.white.opacity(0.98),
                        QuotaOS.Colors.campusBlue.opacity(0.42),
                        QuotaOS.Colors.campusPink.opacity(0.24),
                        QuotaOS.Colors.campusMint.opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing)
                )
            SlidingTopPaneShape(cornerRadius: 34)
                .stroke(
                    LinearGradient(colors: [
                        Color.white.opacity(0.82),
                        QuotaOS.Colors.logoInk.opacity(0.14)
                    ], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.5
                )
            paneHighlights
            VStack(spacing: 7) {
                Spacer(minLength: 55)
                commandRail
                    .padding(.horizontal, 12)
                pullHandle
            }
            .padding(.bottom, 8)
        }
        .frame(height: 118)
        .contentShape(Rectangle())
        .offset(y: easedDrawerPull * 0.22)
        .shadow(color: QuotaOS.Colors.logoInk.opacity(0.12), radius: 18, y: 7)
        .simultaneousGesture(pausePullGesture)
        .accessibilityElement(children: .contain)
        .accessibilityHint("Pull down to pause.")
        .accessibilityAction(named: Text("Pause")) {
            open(.pause)
        }
    }

    private var paneHighlights: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [.white.opacity(0.18), .clear],
                           startPoint: .top,
                           endPoint: .bottom)
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(colors: [
                        QuotaOS.Colors.campusPink.opacity(0.20),
                        QuotaOS.Colors.campusBlue.opacity(0.16),
                        .clear
                    ], startPoint: .leading, endPoint: .trailing)
                )
                .frame(width: 270, height: 44)
                .rotationEffect(.degrees(-4))
                .offset(x: -28, y: -22)
                .blur(radius: 5)
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(QuotaOS.Colors.campusMint.opacity(0.14))
                .frame(width: 190, height: 28)
                .rotationEffect(.degrees(5))
                .offset(x: 74, y: -34)
                .blur(radius: 4)
            Rectangle()
                .fill(LinearGradient(colors: [.clear, QuotaOS.Colors.campusPink.opacity(0.50), QuotaOS.Colors.campusBlue.opacity(0.44), .clear],
                                     startPoint: .leading,
                                     endPoint: .trailing))
                .frame(height: 1)
                .padding(.horizontal, 24)
        }
        .allowsHitTesting(false)
    }

    private var commandRail: some View {
        HStack(spacing: 7) {
            statusCluster
            walletChip
            bannerButton(.careerHub)
            bannerButton(.qbr)
        }
        .padding(5)
        .background(
            LinearGradient(colors: [Color.white.opacity(0.82),
                                    QuotaOS.Colors.campusPaper.opacity(0.72),
                                    QuotaOS.Colors.campusLavender.opacity(0.16)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing),
            in: Capsule()
        )
        .overlay(
            Capsule().stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
        .overlay(
            Capsule().stroke(QuotaOS.Colors.logoInk.opacity(0.08), lineWidth: 1)
        )
    }

    private var statusCluster: some View {
        HStack(spacing: 8) {
            Image(systemName: state.fiscalMoment.isEOQBlizzard ? "snowflake" : "calendar")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(state.fiscalMoment.isEOQBlizzard ? QuotaOS.Colors.red : QuotaOS.Colors.gold)
                .frame(width: 28, height: 28)
                .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(QuotaOS.Colors.logoInk.opacity(0.06), lineWidth: 1)
                )
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(state.fiscalMoment.hudLabel)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(QuotaOS.Colors.logoInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                    Text(state.fiscalMoment.clockText)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.50))
                        .monospacedDigit()
                        .lineLimit(1)
                }
                HStack(spacing: 6) {
                    CompactStatusBar(fraction: bandwidthFraction)
                        .frame(height: 5)
                    Text("\(state.bandwidth)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.62))
                        .monospacedDigit()
                }
            }
        }
        .padding(.leading, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var walletChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(QuotaOS.Colors.green)
            Text(state.commishCash.formatted(.number.grouping(.automatic)))
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(QuotaOS.Colors.logoInk)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .frame(minWidth: 76)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            LinearGradient(colors: [QuotaOS.Colors.green.opacity(0.22), Color.white.opacity(0.70)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing),
            in: Capsule()
        )
        .overlay(Capsule().stroke(Color.white.opacity(0.70), lineWidth: 1))
        .overlay(Capsule().stroke(QuotaOS.Colors.green.opacity(0.18), lineWidth: 1))
    }

    private var pullHandle: some View {
        Capsule()
            .fill(
                LinearGradient(colors: [QuotaOS.Colors.logoInk.opacity(0.20 + pullProgress * 0.18),
                                        QuotaOS.Colors.logoInk.opacity(0.08 + pullProgress * 0.10)],
                               startPoint: .top,
                               endPoint: .bottom)
            )
            .frame(width: 50 + easedDrawerPull * 0.72, height: 4)
            .shadow(color: QuotaOS.Colors.logoInk.opacity(0.08 + pullProgress * 0.10), radius: 5)
    }

    private var pausePullGesture: some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .local)
            .updating($drawerPull) { value, state, _ in
                guard value.translation.height > abs(value.translation.width) else { return }
                state = max(0, value.translation.height)
            }
            .onEnded { value in
                let pulledDown = value.translation.height > Self.pausePullThreshold
                let hasMomentum = value.predictedEndTranslation.height > Self.pausePullThreshold * 1.7
                let mostlyVertical = value.translation.height > abs(value.translation.width)
                guard mostlyVertical && (pulledDown || hasMomentum) else { return }
                QuotaOS.impact(.medium)
                open(.pause)
            }
    }

    private func bannerButton(_ route: GameRoute) -> some View {
        Button {
            QuotaOS.impact(.light)
            open(route)
        } label: {
            Image(systemName: route.systemImage)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(
                    LinearGradient(colors: [route.tint.opacity(0.96), route.tint.opacity(0.60)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing),
                    in: Circle()
                )
                .overlay(
                    Circle().stroke(.white.opacity(0.58), lineWidth: 1)
                )
                .shadow(color: route.tint.opacity(0.18), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(route.title)
    }
}

private struct SlidingTopPaneShape: Shape {
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(cornerRadius, rect.width / 2, rect.height / 2)

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                          control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                          control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

private struct CompactStatusBar: View {
    var fraction: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(QuotaOS.Colors.logoInk.opacity(0.13))
                Capsule()
                    .fill(
                        LinearGradient(colors: [QuotaOS.Colors.mint, QuotaOS.Colors.blue],
                                       startPoint: .leading,
                                       endPoint: .trailing)
                    )
                    .frame(width: max(0, min(1, fraction)) * proxy.size.width)
            }
        }
    }
}

#Preview {
    ContentView()
}
