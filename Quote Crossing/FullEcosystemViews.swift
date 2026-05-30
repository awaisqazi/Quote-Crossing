//
//  FullEcosystemViews.swift
//  Quote Crossing
//
//  Playable offline systems from the full GDD ecosystem.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct CareerCommandDeck: View {
    var state: GameState
    var nearbyEntrance: OfficeEntrance?
    @Binding var isCollapsed: Bool
    var open: (GameRoute) -> Void

    @GestureState private var drawerDrag: CGFloat = 0

    private var quickRoutes: [GameRoute] {
        let next = state.career.nextStep.route
        var routes = [next, .prospecting, .cubicleBuilder, .pipeDex, .qBot, .bidDesk]
        routes.removeAll { $0 == .careerHub && next == .careerHub }
        var seen = Set<GameRoute>()
        return Array(routes.filter { seen.insert($0).inserted }.prefix(4))
    }

    private var layoutSummary: CubicleLayoutSummary {
        CubicleLayoutSummary.load()
    }

    private var completionFraction: Double {
        state.career.completionFraction
    }

    private var completedStepCount: Int {
        CareerStep.allCases.filter { state.career.isComplete($0) }.count
    }

    private var progressLabel: String {
        "\(completedStepCount)/\(CareerStep.allCases.count)"
    }

    private var nextRoute: GameRoute {
        state.career.nextStep.route
    }

    private var primaryRoute: GameRoute {
        nearbyEntrance?.route ?? nextRoute
    }

    private var primaryDestinationRoute: GameRoute {
        nearbyEntrance?.destinationRoute ?? unlockedRoute(for: nextRoute)
    }

    private var primaryTitle: String {
        nearbyEntrance?.ctaTitle ?? state.career.nextStep.title
    }

    private var primarySubtitle: String {
        nearbyEntrance?.ctaSubtitle ?? "Next quota move"
    }

    private var primaryEyebrow: String {
        guard let nearbyEntrance else { return "NEXT QUOTA MOVE" }
        return nearbyEntrance.isLocked ? "ROOM LOCKED" : "NEARBY ENTRANCE"
    }

    private var primaryIcon: String {
        if nearbyEntrance?.isLocked == true { return "lock.fill" }
        return primaryRoute.systemImage
    }

    private var primaryTint: Color {
        nearbyEntrance?.isLocked == true ? QuotaOS.Colors.slate : primaryRoute.tint
    }

    private var liveDrawerOffset: CGFloat {
        if isCollapsed {
            return min(10, max(-22, drawerDrag))
        }
        return min(56, max(0, drawerDrag))
    }

    var body: some View {
        VStack(spacing: 9) {
            drawerHandle
            Group {
                if isCollapsed {
                    collapsedSummary
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    expandedControls
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, isCollapsed ? 7 : 8)
        .padding(.bottom, isCollapsed ? 12 : 22)
        .background(drawerBackground)
        .overlay(
            BottomCommandDrawerShape(cornerRadius: 34)
                .stroke(
                    LinearGradient(colors: [
                        Color.white.opacity(0.86),
                        QuotaOS.Colors.logoInk.opacity(0.13)
                    ], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.5
                )
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(LinearGradient(colors: [.clear, primaryTint.opacity(0.46), QuotaOS.Colors.campusPink.opacity(0.32), .clear],
                                     startPoint: .leading,
                                     endPoint: .trailing))
                .frame(height: 1.2)
                .padding(.horizontal, 24)
        }
        .shadow(color: QuotaOS.Colors.logoInk.opacity(isCollapsed ? 0.10 : 0.14), radius: isCollapsed ? 12 : 18, y: -2)
        .offset(y: liveDrawerOffset)
        .gesture(drawerGesture)
    }

    private var drawerBackground: some View {
        BottomCommandDrawerShape(cornerRadius: 34)
            .fill(.ultraThinMaterial)
            .overlay {
                BottomCommandDrawerShape(cornerRadius: 34)
                    .fill(
                        LinearGradient(colors: [
                            Color.white.opacity(0.96),
                            QuotaOS.Colors.campusPaper.opacity(0.90),
                            QuotaOS.Colors.campusBlue.opacity(0.30),
                            QuotaOS.Colors.campusPink.opacity(0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing)
                    )
            }
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(primaryTint.opacity(0.15))
                    .frame(width: isCollapsed ? 180 : 250, height: isCollapsed ? 42 : 58)
                    .rotationEffect(.degrees(-6))
                    .blur(radius: 8)
                    .offset(x: -42, y: isCollapsed ? -14 : -24)
            }
            .overlay(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(QuotaOS.Colors.campusPink.opacity(0.14))
                    .frame(width: isCollapsed ? 150 : 210, height: isCollapsed ? 34 : 48)
                    .rotationEffect(.degrees(7))
                    .blur(radius: 7)
                    .offset(x: 26, y: isCollapsed ? -10 : -18)
            }
    }

    private var drawerHandle: some View {
        Button {
            setCollapsed(!isCollapsed)
        } label: {
            VStack(spacing: 4) {
                Capsule()
                    .fill(QuotaOS.Colors.logoInk.opacity(isCollapsed ? 0.28 : 0.16))
                    .frame(width: 48, height: 3.5)
                Image(systemName: isCollapsed ? "chevron.up" : "chevron.down")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.38))
                    .frame(height: 8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCollapsed ? "Show command drawer" : "Hide command drawer")
    }

    private var collapsedSummary: some View {
        Button {
            setCollapsed(false)
        } label: {
            HStack(spacing: 12) {
                routeMedallion(icon: primaryIcon, tint: primaryTint, size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(nearbyEntrance == nil ? "NEXT QUOTA MOVE" : primaryEyebrow)
                            .font(.system(size: 7.5, weight: .black, design: .rounded))
                            .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.48))
                            .lineLimit(1)
                        Text(progressLabel)
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundStyle(primaryTint)
                            .monospacedDigit()
                    }
                    Text(nearbyEntrance?.title ?? state.career.nextStep.title)
                        .font(.system(size: 15.5, weight: .black, design: .rounded))
                        .foregroundStyle(QuotaOS.Colors.logoInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    progressTrack(height: 4)
                }
                Spacer()
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.56))
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.72), in: Circle())
                    .overlay(Circle().stroke(primaryTint.opacity(0.22), lineWidth: 1))
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(
                LinearGradient(colors: [
                    Color.white.opacity(0.80),
                    primaryTint.opacity(0.10),
                    Color.white.opacity(0.58)
                ], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: Capsule()
            )
            .overlay(Capsule().stroke(Color.white.opacity(0.70), lineWidth: 1))
            .overlay(Capsule().stroke(primaryTint.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show command drawer")
    }

    private var expandedControls: some View {
        VStack(spacing: 11) {
            storyProgressStrip
            nextMoveButton
            HStack(spacing: 8) {
                ForEach(quickRoutes) { route in
                    compactRouteButton(route)
                }
            }
        }
    }

    private var storyProgressStrip: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("CAREER PATH")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.44))
                Text(state.career.nextStep.storyBeat)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.64))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }
            Spacer(minLength: 8)
            Text(progressLabel)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(primaryTint)
                .monospacedDigit()
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.72), in: Capsule())
                .overlay(Capsule().stroke(primaryTint.opacity(0.20), lineWidth: 1))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.50), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .bottom) {
            progressTrack(height: 4)
                .padding(.horizontal, 14)
                .offset(y: 2)
        }
    }

    private var nextMoveButton: some View {
        return Button {
            open(primaryDestinationRoute)
        } label: {
            HStack(spacing: 11) {
                routeMedallion(icon: primaryIcon, tint: primaryTint, size: 42)
                VStack(alignment: .leading, spacing: 4) {
                    Text(primaryEyebrow)
                        .font(.system(size: 8.5, weight: .black, design: .rounded))
                        .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.48))
                    Text(primaryTitle)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(QuotaOS.Colors.logoInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(primarySubtitle)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.52))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(primaryTint, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.50), lineWidth: 1))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(
                LinearGradient(colors: [
                    Color.white.opacity(0.92),
                    primaryTint.opacity(0.16),
                    QuotaOS.Colors.campusLavender.opacity(0.10)
                ],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.72), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(primaryTint.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func compactRouteButton(_ route: GameRoute) -> some View {
        let isUnlocked = layoutSummary.isUnlocked(route)
        return Button {
            QuotaOS.impact(.light)
            open(unlockedRoute(for: route))
        } label: {
            VStack(spacing: 5) {
                Image(systemName: isUnlocked ? route.systemImage : "lock.fill")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(isUnlocked ? .white : QuotaOS.Colors.slate)
                    .frame(width: 30, height: 30)
                    .background(
                        LinearGradient(colors: [
                            (isUnlocked ? route.tint : QuotaOS.Colors.slate).opacity(isUnlocked ? 0.92 : 0.16),
                            (isUnlocked ? route.tint : QuotaOS.Colors.slate).opacity(isUnlocked ? 0.58 : 0.08)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Circle()
                    )
                    .overlay(Circle().stroke(Color.white.opacity(isUnlocked ? 0.56 : 0.16), lineWidth: 1))
                Text(route.compactTitle)
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.76))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                LinearGradient(colors: [Color.white.opacity(0.80),
                                        (isUnlocked ? route.tint : QuotaOS.Colors.slate).opacity(0.13),
                                        QuotaOS.Colors.campusPaper.opacity(0.60)],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.70), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(QuotaOS.Colors.logoInk.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isUnlocked ? route.title : "\(route.title), \(layoutSummary.requirementText(for: route) ?? "locked")")
    }

    private func unlockedRoute(for route: GameRoute) -> GameRoute {
        layoutSummary.isUnlocked(route) ? route : .cubicleBuilder
    }

    private var drawerGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .updating($drawerDrag) { value, state, _ in
                guard abs(value.translation.height) > abs(value.translation.width) else { return }
                state = value.translation.height
            }
            .onEnded { value in
                let vertical = value.predictedEndTranslation.height
                guard abs(vertical) > abs(value.predictedEndTranslation.width) else { return }
                if isCollapsed && vertical < -28 {
                    setCollapsed(false)
                } else if !isCollapsed && vertical > 34 {
                    setCollapsed(true)
                }
            }
    }

    private func setCollapsed(_ collapsed: Bool) {
        guard isCollapsed != collapsed else { return }
        QuotaOS.impact(.light)
        withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
            isCollapsed = collapsed
        }
    }

    private func routeMedallion(icon: String, tint: Color, size: CGFloat) -> some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.42, weight: .black))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(colors: [tint.opacity(0.98), tint.opacity(0.58)],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing),
                in: Circle()
            )
            .overlay(Circle().stroke(Color.white.opacity(0.58), lineWidth: 1))
            .shadow(color: tint.opacity(0.18), radius: 8, y: 4)
    }

    private func progressTrack(height: CGFloat) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(QuotaOS.Colors.logoInk.opacity(0.08))
                Capsule()
                    .fill(
                        LinearGradient(colors: [
                            QuotaOS.Colors.campusMint,
                            primaryTint,
                            QuotaOS.Colors.campusPink
                        ], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: max(0, min(1, completionFraction)) * proxy.size.width)
            }
        }
        .frame(height: height)
    }
}

private struct BottomCommandDrawerShape: Shape {
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(cornerRadius, rect.width / 2, rect.height / 2)

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY),
                          control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                          control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct CareerHubView: View {
    var state: GameState
    @ObservedObject var inventory: InventoryManager
    var open: (GameRoute) -> Void
    var onClose: () -> Void

    private var completedCount: Int {
        CareerStep.allCases.filter { state.career.isComplete($0) }.count
    }

    private var currentStep: CareerStep {
        state.career.nextStep
    }

    private var optionalRoutes: [GameRoute] {
        [.outfitter, .swagVending, .wardrobe, .treasury, .expenseRun, .socialLinks]
    }

    private var layoutSummary: CubicleLayoutSummary {
        CubicleLayoutSummary.load()
    }

    var body: some View {
        ZStack {
            QuotaBackdrop(tint: QuotaOS.Colors.gold, tone: .campus)
            VStack(spacing: 0) {
                QuotaHeader(title: "Quota Crossing",
                            subtitle: "\(currentStep.chapter) • \(currentStep.objective)",
                            tint: QuotaOS.Colors.gold,
                            tone: .campus,
                            onClose: onClose)
                ScrollView {
                    VStack(spacing: 14) {
                        storyBrief
                        scoreStrip
                        officeLoopPanel
                        storyline
                        sideSystems
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 34)
                }
            }
        }
    }

    private var storyBrief: some View {
        let requirement = layoutSummary.requirementText(for: currentStep.route)
        return Button {
            open(requirement == nil ? currentStep.route : .cubicleBuilder)
        } label: {
            ZStack(alignment: .bottomLeading) {
                CareerMapBackdrop(
                    fraction: state.career.completionFraction,
                    tint: currentStep.route.tint
                )

                VStack(alignment: .leading, spacing: 15) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("CAREER MAP")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .foregroundStyle(currentStep.route.tint)
                            Text("New Hire to CFO Showdown")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.58))
                        }
                        Spacer()
                        CareerProgressRing(fraction: state.career.completionFraction)
                            .frame(width: 58, height: 58)
                    }

                    Spacer(minLength: 24)

                    HStack(alignment: .bottom, spacing: 12) {
                        VStack(alignment: .leading, spacing: 9) {
                            HStack(spacing: 7) {
                                Image(systemName: requirement == nil ? currentStep.route.systemImage : "building.2.crop.circle.fill")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(.white)
                                    .frame(width: 25, height: 25)
                                    .background(
                                        LinearGradient(colors: [currentStep.route.tint, currentStep.route.tint.opacity(0.58)],
                                                       startPoint: .topLeading,
                                                       endPoint: .bottomTrailing),
                                        in: Circle()
                                    )
                                Text(requirement == nil ? "NEXT ASSIGNMENT" : "BUILD TO UNLOCK")
                                    .font(.system(size: 8.5, weight: .black, design: .rounded))
                                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.48))
                            }
                            Text(currentStep.title)
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(QuotaOS.Colors.logoInk)
                                .lineLimit(1)
                                .minimumScaleFactor(0.64)
                            Text(requirement ?? currentStep.storyBeat)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.64))
                                .lineSpacing(3)
                                .lineLimit(3)
                            HStack(spacing: 8) {
                                miniStatus(icon: "doc.text.fill", text: "\(completedCount)/\(CareerStep.allCases.count) filed", tint: QuotaOS.Colors.green)
                                miniStatus(icon: "building.2.fill", text: "\(layoutSummary.roomCount) rooms", tint: QuotaOS.Colors.teal)
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.56), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(QuotaOS.Colors.logoInk.opacity(0.08), lineWidth: 1)
                        )

                        Spacer(minLength: 0)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                LinearGradient(colors: [currentStep.route.tint, QuotaOS.Colors.campusPink],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing),
                                in: Circle()
                            )
                            .shadow(color: currentStep.route.tint.opacity(0.28), radius: 12, y: 7)
                    }
                }
                .padding(18)
            }
            .frame(minHeight: 292)
            .background(
                LinearGradient(colors: [Color.white.opacity(0.94),
                                        QuotaOS.Colors.campusBlue.opacity(0.34),
                                        QuotaOS.Colors.campusPink.opacity(0.26)],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(QuotaOS.Colors.gold.opacity(0.28), lineWidth: 1.5)
            )
            .shadow(color: QuotaOS.Colors.logoInk.opacity(0.11), radius: 18, y: 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Current assignment, \(currentStep.title)")
    }

    private func miniStatus(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .black))
            Text(text)
                .font(.system(size: 9.5, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundStyle(QuotaOS.Colors.logoInk)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.72), in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.22), lineWidth: 1))
    }

    private var officeLoopPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            QuotaSectionLabel(title: "Core Loop", detail: "\(layoutSummary.roomCount) rooms built", tone: .campus)
            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(colors: [
                            QuotaOS.Colors.campusBlue.opacity(0.35),
                            QuotaOS.Colors.campusPink.opacity(0.28),
                            QuotaOS.Colors.campusMint.opacity(0.32)
                        ], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 10)
                    .padding(.horizontal, 26)
                    .offset(y: -24)

                HStack(alignment: .top, spacing: 7) {
                    loopStep(icon: "figure.walk", title: "Scout", detail: "Find leads", tint: QuotaOS.Colors.blue)
                    loopStep(icon: "dollarsign.circle.fill", title: "Fund", detail: "Earn cash", tint: QuotaOS.Colors.green)
                    loopStep(icon: "building.2.crop.circle.fill", title: "Build", detail: "Place rooms", tint: QuotaOS.Colors.teal)
                    loopStep(icon: "door.left.hand.open", title: "Enter", detail: "Play systems", tint: QuotaOS.Colors.purple)
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(QuotaOS.Colors.logoInk.opacity(0.08), lineWidth: 1)
        )
    }

    private func loopStep(icon: String, title: String, detail: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(
                    LinearGradient(colors: [tint, tint.opacity(0.62)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing),
                    in: Circle()
                )
                .overlay(Circle().stroke(.white.opacity(0.32), lineWidth: 1))
                .shadow(color: tint.opacity(0.18), radius: 8, y: 4)
            Text(title)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(QuotaOS.Colors.logoInk)
            Text(detail)
                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.48))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }

    private var scoreStrip: some View {
        HStack(spacing: 8) {
            QuotaMetricPill(title: "Quota", value: "\(Int(state.career.completionFraction * 100))%", icon: "target", tint: QuotaOS.Colors.gold, tone: .campus)
            QuotaMetricPill(title: "Cash", value: state.lifetimeCommishCash.formatted(.number.grouping(.automatic)), icon: "dollarsign.circle.fill", tint: QuotaOS.Colors.green, tone: .campus)
            QuotaMetricPill(title: "Friends", value: "\(state.expenseRun.friendNPCs.count)", icon: "person.2.fill", tint: QuotaOS.Colors.blue, tone: .campus)
        }
    }

    private var storyline: some View {
        VStack(spacing: 10) {
            QuotaSectionLabel(title: "Storyline", detail: "New Hire to CFO showdown", tone: .campus)
            VStack(spacing: 8) {
                ForEach(CareerStep.allCases) { step in
                    timelineRow(step)
                }
            }
        }
    }

    private func timelineRow(_ step: CareerStep) -> some View {
        let isDone = state.career.isComplete(step)
        let isCurrent = step == currentStep
        let requirement = layoutSummary.requirementText(for: step.route)
        let isRoomLocked = requirement != nil
        let tint = isDone ? QuotaOS.Colors.green : isCurrent ? step.route.tint : QuotaOS.Colors.slate

        return Button {
            open(isRoomLocked ? .cubicleBuilder : step.route)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 0) {
                    Image(systemName: isDone ? "checkmark" : isRoomLocked ? "lock.fill" : step.route.systemImage)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(
                            LinearGradient(colors: [tint, tint.opacity(0.56)],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing),
                            in: Circle()
                        )
                    Rectangle()
                        .fill(.white.opacity(step == CareerStep.allCases.last ? 0 : 0.12))
                        .frame(width: 2, height: 26)
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(step.chapter.uppercased())
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundStyle(tint)
                        Text(isDone ? "FILED" : isCurrent ? "NOW" : isRoomLocked ? "ROOM LOCKED" : "QUEUED")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundStyle(QuotaOS.Colors.logoInk.opacity(isCurrent ? 0.70 : 0.42))
                    }
                    Text(step.title)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(QuotaOS.Colors.logoInk.opacity(isCurrent || isDone ? 1 : 0.70))
                    Text(requirement ?? step.storyBeat)
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(QuotaOS.Colors.logoInk.opacity(isCurrent || isDone ? 0.60 : 0.38))
                        .lineLimit(2)
                        .lineSpacing(2)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(tint.opacity(isCurrent ? 0.72 : 0.30))
                    .padding(.top, 16)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                LinearGradient(colors: [Color.white.opacity(isCurrent ? 0.82 : 0.64),
                                        tint.opacity(isCurrent ? 0.14 : 0.06),
                                        QuotaOS.Colors.campusPink.opacity(isCurrent ? 0.10 : 0.04)],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(tint.opacity(isCurrent ? 0.30 : 0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(step.title), \(isDone ? "filed" : isCurrent ? "current" : "queued")")
    }

    private var sideSystems: some View {
        VStack(spacing: 10) {
            QuotaSectionLabel(title: "Side Systems", detail: "Optional boosts", tone: .campus)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                ForEach(optionalRoutes) { route in
                    routeChip(route)
                }
            }
        }
    }

    private func routeChip(_ route: GameRoute) -> some View {
        let requirement = layoutSummary.requirementText(for: route)
        let isUnlocked = requirement == nil
        return Button {
            open(isUnlocked ? route : .cubicleBuilder)
        } label: {
            HStack(spacing: 9) {
                Image(systemName: isUnlocked ? route.systemImage : "lock.fill")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(isUnlocked ? route.tint : QuotaOS.Colors.slate)
                    .frame(width: 28, height: 28)
                    .background((isUnlocked ? route.tint : QuotaOS.Colors.slate).opacity(0.11), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(route.title)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(QuotaOS.Colors.logoInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(statusText(for: route))
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.48))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(Color.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke((isUnlocked ? route.tint : QuotaOS.Colors.slate).opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func statusText(for route: GameRoute) -> String {
        if let requirement = layoutSummary.requirementText(for: route) {
            return requirement
        }
        switch route {
        case .expenseRun: return "\(state.expenseRun.regionalListings) listings"
        case .treasury: return "\(state.treasury.portfolioValue) portfolio"
        case .outfitter: return "\(inventory.ownedItems.count) owned"
        case .swagVending: return "\(state.spiffCoins) SPIFF"
        case .wardrobe: return "\(inventory.equippedItems.count) equipped"
        case .socialLinks: return "\(state.expenseRun.friendNPCs.count) friends"
        default: return route.compactTitle
        }
    }
}

private struct CareerProgressRing: View {
    var fraction: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(QuotaOS.Colors.logoInk.opacity(0.10), lineWidth: 8)
            Circle()
                .trim(from: 0, to: max(0, min(1, fraction)))
                .stroke(
                    LinearGradient(colors: [QuotaOS.Colors.gold, QuotaOS.Colors.green],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("\(Int(fraction * 100))%")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(QuotaOS.Colors.logoInk)
                .monospacedDigit()
        }
    }
}

private struct CareerMapBackdrop: View {
    var fraction: Double
    var tint: Color

    private let nodes: [CGPoint] = [
        CGPoint(x: 0.10, y: 0.70),
        CGPoint(x: 0.23, y: 0.48),
        CGPoint(x: 0.38, y: 0.62),
        CGPoint(x: 0.54, y: 0.39),
        CGPoint(x: 0.70, y: 0.54),
        CGPoint(x: 0.86, y: 0.31)
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                campusBuildings(in: size)

                Path { path in
                    guard let first = nodes.first else { return }
                    path.move(to: point(first, in: size))
                    for node in nodes.dropFirst() {
                        path.addLine(to: point(node, in: size))
                    }
                }
                .stroke(QuotaOS.Colors.logoInk.opacity(0.07), style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))

                Path { path in
                    guard let first = nodes.first else { return }
                    path.move(to: point(first, in: size))
                    for node in nodes.dropFirst() {
                        path.addLine(to: point(node, in: size))
                    }
                }
                .trim(from: 0, to: min(1, max(0.06, fraction)))
                .stroke(
                    LinearGradient(colors: [QuotaOS.Colors.green, tint, QuotaOS.Colors.campusPink],
                                   startPoint: .leading,
                                   endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                )

                ForEach(Array(nodes.enumerated()), id: \.offset) { index, node in
                    let nodeFraction = Double(index) / Double(max(1, nodes.count - 1))
                    let isReached = fraction + 0.02 >= nodeFraction
                    Circle()
                        .fill(isReached ? tint : Color.white.opacity(0.80))
                        .frame(width: isReached ? 17 : 13, height: isReached ? 17 : 13)
                        .overlay(Circle().stroke(.white.opacity(0.80), lineWidth: 2))
                        .shadow(color: (isReached ? tint : QuotaOS.Colors.logoInk).opacity(0.18), radius: 7, y: 4)
                        .position(point(node, in: size))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .allowsHitTesting(false)
    }

    private func point(_ node: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: node.x * size.width, y: node.y * size.height)
    }

    private func campusBuildings(in size: CGSize) -> some View {
        ZStack {
            careerBuilding(width: size.width * 0.32,
                           height: size.height * 0.48,
                           color: QuotaOS.Colors.campusPink,
                           rows: 3,
                           columns: 2)
                .offset(x: -size.width * 0.26, y: -size.height * 0.05)
            careerBuilding(width: size.width * 0.46,
                           height: size.height * 0.58,
                           color: QuotaOS.Colors.campusBlue,
                           rows: 4,
                           columns: 3)
                .offset(x: size.width * 0.10, y: -size.height * 0.11)
            careerBuilding(width: size.width * 0.26,
                           height: size.height * 0.38,
                           color: QuotaOS.Colors.campusMint,
                           rows: 2,
                           columns: 2)
                .offset(x: size.width * 0.32, y: size.height * 0.08)
        }
        .opacity(0.72)
        .frame(width: size.width, height: size.height)
    }

    private func careerBuilding(width: CGFloat, height: CGFloat, color: Color, rows: Int, columns: Int) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(color.opacity(0.18))
            .overlay(
                VStack(spacing: 5) {
                    ForEach(0..<rows, id: \.self) { _ in
                        HStack(spacing: 5) {
                            ForEach(0..<columns, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(index.isMultiple(of: 2) ? Color.white.opacity(0.54) : color.opacity(0.24))
                            }
                        }
                    }
                }
                .padding(12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(QuotaOS.Colors.logoInk.opacity(0.08), lineWidth: 1.5)
            )
            .frame(width: width, height: height)
    }
}

struct ProspectingView: View {
    var gameState: GameState
    @ObservedObject var pipeDex: PipeDexViewModel
    var onClose: () -> Void

    @State private var tiles = ProspectingTile.seeded()
    @State private var revealed = Set<Int>()
    @State private var banner = "Networking Lounge scan armed."

    var body: some View {
        ZStack {
            QuotaBackdrop(tint: QuotaOS.Colors.blue, tone: .campus)
            VStack(spacing: 12) {
                QuotaHeader(title: "Prospecting",
                            subtitle: banner,
                            tint: QuotaOS.Colors.blue,
                            tone: .campus,
                            onClose: onClose)

                ProspectingSignalRail(
                    charges: gameState.prospecting.scannerCharges,
                    leads: gameState.prospecting.leadsFound,
                    gatekeepers: gameState.prospecting.gatekeeperHits
                )
                .padding(.horizontal, 16)

                ProspectingLoungeBoard(
                    tiles: tiles,
                    revealed: revealed,
                    chargesRemaining: gameState.prospecting.scannerCharges,
                    reveal: reveal
                )
                .padding(.horizontal, 16)

                QuotaPrimaryButton(title: "Refresh Lounge Map", icon: "arrow.clockwise", tint: QuotaOS.Colors.blue) {
                    QuotaOS.impact(.light)
                    tiles = ProspectingTile.seeded()
                    revealed.removeAll()
                    gameState.prospecting.scannerCharges = 3
                    gameState.persistCareer()
                    banner = "Fresh gatekeeper pattern loaded."
                }
                .padding(.horizontal, 16)
                Spacer(minLength: 10)
            }
        }
    }

    private func reveal(_ index: Int) {
        guard !revealed.contains(index), gameState.prospecting.scannerCharges > 0 else { return }
        QuotaOS.impact(.light)
        revealed.insert(index)
        gameState.prospecting.scansCompleted += 1
        gameState.prospecting.scannerCharges -= 1

        switch tiles[index] {
        case .lead:
            let level = Int.random(in: 1...3)
            pipeDex.addProspectedLead(level: level)
            gameState.prospecting.leadsFound += 1
            gameState.prospecting.lastLeadName = "Level \(level) Prospect"
            gameState.spiffCoins += 5
            gameState.completeCareerStep(.prospecting)
            banner = "Lead found. Pipe-Dex received a level \(level) prospect."
        case .gatekeeper:
            gameState.prospecting.gatekeeperHits += 1
            gameState.bandwidth = max(0, gameState.bandwidth - 8)
            banner = "Gatekeeper pinged your badge. Bandwidth clipped."
        case .empty:
            gameState.basePay += 25
            gameState.treasury.basePayReserve = gameState.basePay
            banner = "Clean signal. +25 Base Pay research credit."
        }
        gameState.persistCareer()
    }
}

private enum ProspectingTile {
    case lead, gatekeeper, empty

    var icon: String {
        switch self {
        case .lead: "person.crop.circle.badge.plus"
        case .gatekeeper: "hand.raised.fill"
        case .empty: "dot.radiowaves.left.and.right"
        }
    }

    var title: String {
        switch self {
        case .lead: "Lead"
        case .gatekeeper: "Gate"
        case .empty: "Signal"
        }
    }

    var tint: Color {
        switch self {
        case .lead: QuotaOS.Colors.green
        case .gatekeeper: QuotaOS.Colors.red
        case .empty: QuotaOS.Colors.blue
        }
    }

    static func seeded() -> [ProspectingTile] {
        var tiles: [ProspectingTile] = Array(repeating: .empty, count: 25)
        for index in [2, 7, 13, 18, 22] { tiles[index] = .lead }
        for index in [4, 11, 16, 20] { tiles[index] = .gatekeeper }
        return tiles.shuffled()
    }
}

private struct ProspectingBackdrop: View {
    var body: some View {
        ZStack {
            QuotaOS.Colors.ink
            LinearGradient(
                colors: [
                    Color(red: 0.020, green: 0.055, blue: 0.070),
                    QuotaOS.Colors.blue.opacity(0.22),
                    QuotaOS.Colors.green.opacity(0.16),
                    Color(red: 0.030, green: 0.044, blue: 0.052)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Canvas { context, size in
                let floorStep: CGFloat = 34
                for y in stride(from: 98, through: size.height, by: floorStep) {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y + size.width * 0.18))
                    context.stroke(path, with: .color(.white.opacity(0.030)), lineWidth: 1)
                }
                for x in stride(from: -size.width, through: size.width * 1.5, by: floorStep) {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + size.height * 0.34, y: size.height))
                    context.stroke(path, with: .color(.white.opacity(0.024)), lineWidth: 1)
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct ProspectingSignalRail: View {
    let charges: Int
    let leads: Int
    let gatekeepers: Int

    var body: some View {
        HStack(spacing: 8) {
            scannerChargeCard
            ProspectingMiniStat(title: "Leads", value: "\(leads)", icon: "person.crop.circle.badge.plus", tint: QuotaOS.Colors.green)
            ProspectingMiniStat(title: "Gates", value: "\(gatekeepers)", icon: "hand.raised.fill", tint: QuotaOS.Colors.red)
        }
        .accessibilityElement(children: .combine)
    }

    private var scannerChargeCard: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.router.fill")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(QuotaOS.Colors.blue)
                .frame(width: 28, height: 28)
                .background(QuotaOS.Colors.blue.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text("Scanner")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.54))
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index < charges ? QuotaOS.Colors.blue : QuotaOS.Colors.logoInk.opacity(0.10))
                            .frame(width: index < charges ? 18 : 10, height: 5)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.72), in: Capsule())
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(QuotaOS.Colors.blue.opacity(0.18), lineWidth: 1))
    }
}

private struct ProspectingMiniStat: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(tint)
                .frame(width: 22, height: 22)
                .background(tint.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 7.5, weight: .black, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.50))
                Text(value)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(QuotaOS.Colors.logoInk)
            }
        }
        .frame(width: 86, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.72), in: Capsule())
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.18), lineWidth: 1))
    }
}

private struct ProspectingLoungeBoard: View {
    let tiles: [ProspectingTile]
    let revealed: Set<Int>
    let chargesRemaining: Int
    let reveal: (Int) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lounge Signal")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(QuotaOS.Colors.logoInk)
                    Text(signalSubtitle)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.54))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                Spacer()
                Image(systemName: chargesRemaining > 0 ? "dot.viewfinder" : "lock.fill")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(chargesRemaining > 0 ? QuotaOS.Colors.blue : QuotaOS.Colors.logoInk.opacity(0.38))
                    .frame(width: 34, height: 34)
                    .background(QuotaOS.Colors.blue.opacity(0.11), in: Circle())
                    .overlay(Circle().stroke(QuotaOS.Colors.blue.opacity(0.18), lineWidth: 1))
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(tiles.indices, id: \.self) { index in
                    ProspectingTileButton(
                        tile: tiles[index],
                        index: index,
                        isRevealed: revealed.contains(index),
                        isDisabled: revealed.contains(index) || chargesRemaining <= 0,
                        action: { reveal(index) }
                    )
                }
            }
        }
        .padding(14)
        .background(
            LinearGradient(colors: [
                Color.white.opacity(0.92),
                QuotaOS.Colors.campusBlue.opacity(0.30),
                QuotaOS.Colors.campusMint.opacity(0.24),
                QuotaOS.Colors.campusPink.opacity(0.16)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(QuotaOS.Colors.blue.opacity(0.18), lineWidth: 1.2)
        )
        .shadow(color: QuotaOS.Colors.logoInk.opacity(0.10), radius: 22, y: 12)
    }

    private var signalSubtitle: String {
        chargesRemaining > 0 ? "\(chargesRemaining) live scans" : "Scanner cooling down"
    }
}

private struct ProspectingTileButton: View {
    let tile: ProspectingTile
    let index: Int
    let isRevealed: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tileFill)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(tileStroke, lineWidth: isRevealed ? 1.4 : 1)
                if isRevealed {
                    revealedContent
                } else {
                    hiddenContent
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .shadow(color: isRevealed ? tile.tint.opacity(0.20) : QuotaOS.Colors.logoInk.opacity(0.08), radius: isRevealed ? 10 : 5, y: 5)
            .opacity(isDisabled && !isRevealed ? 0.72 : 1)
            .scaleEffect(isRevealed ? 1.0 : 0.985)
            .animation(QuotaOS.spring, value: isRevealed)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(isRevealed ? tile.title : "Unscanned signal \(index + 1)")
    }

    private var tileFill: some ShapeStyle {
        LinearGradient(
            colors: isRevealed
                ? [tile.tint.opacity(0.86), tile.tint.opacity(0.56), Color.white.opacity(0.24)]
                : [Color.white.opacity(0.94), QuotaOS.Colors.campusBlue.opacity(0.26), QuotaOS.Colors.campusPink.opacity(0.14)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var tileStroke: Color {
        isRevealed ? tile.tint.opacity(0.70) : QuotaOS.Colors.logoInk.opacity(0.12)
    }

    private var hiddenContent: some View {
        VStack(spacing: 4) {
            Image(systemName: "dot.radiowaves.up.forward")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(QuotaOS.Colors.blue.opacity(0.74))
            Capsule()
                .fill(QuotaOS.Colors.logoInk.opacity(0.16))
                .frame(width: 20, height: 3)
        }
    }

    private var revealedContent: some View {
        VStack(spacing: 4) {
            Image(systemName: tile.icon)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)
            Text(tile.title.uppercased())
                .font(.system(size: 7.4, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.86))
                .lineLimit(1)
                .minimumScaleFactor(0.60)
        }
    }
}

struct BidDeskDungeonView: View {
    var gameState: GameState
    var onClose: () -> Void

    @State private var player = GridPoint2D(x: 0, y: 5)
    @State private var patrol = GridPoint2D(x: 3, y: 2)
    @State private var log = "Finance patrols are watching the margin."
    private let exit = GridPoint2D(x: 5, y: 0)
    private let gridSize = 6

    private var dangerCells: Set<GridPoint2D> {
        var cells = Set<GridPoint2D>()
        for y in 0..<gridSize {
            for x in 0..<gridSize {
                let point = GridPoint2D(x: x, y: y)
                if abs(point.x - patrol.x) + abs(point.y - patrol.y) <= 1 {
                    cells.insert(point)
                }
            }
        }
        return cells
    }

    var body: some View {
        ZStack {
            QuotaBackdrop(tint: QuotaOS.Colors.red, tone: .campus)
            VStack(spacing: 12) {
                QuotaHeader(title: "Bid Desk Dungeon", subtitle: log, tint: QuotaOS.Colors.red, tone: .campus, onClose: onClose)

                BidDeskStatusRail(
                    runs: gameState.bidDesk.runsCompleted,
                    recovered: gameState.bidDesk.marginRecovered,
                    spotted: gameState.bidDesk.timesSpotted
                )
                .padding(.horizontal, 16)

                BidDeskFloorPlan(player: player, patrol: patrol, exit: exit, dangerCells: dangerCells)
                    .padding(.horizontal, 16)

                BidDeskControlDeck(
                    moveUp: { move(dx: 0, dy: -1) },
                    moveLeft: { move(dx: -1, dy: 0) },
                    moveRight: { move(dx: 1, dy: 0) },
                    reset: { resetRun(message: "New basement route filed.") }
                )
                .padding(.horizontal, 16)

                Spacer(minLength: 10)
            }
        }
    }

    private func resetRun(message: String) {
        player = GridPoint2D(x: 0, y: 5)
        patrol = GridPoint2D(x: 3, y: 2)
        log = message
        QuotaOS.impact(.light)
    }

    private func move(dx: Int, dy: Int) {
        QuotaOS.impact(.light)
        player = GridPoint2D(x: min(5, max(0, player.x + dx)), y: min(5, max(0, player.y + dy)))
        patrol = GridPoint2D(x: (patrol.x + 1) % 6, y: patrol.y == 2 ? 3 : 2)

        if abs(player.x - patrol.x) + abs(player.y - patrol.y) <= 1 {
            QuotaOS.impact(.heavy)
            gameState.bidDesk.timesSpotted += 1
            gameState.commishCash = max(0, gameState.commishCash - 75)
            log = "Finance spotted you. Quote payout clipped."
            player = GridPoint2D(x: 0, y: 5)
        } else if player == exit {
            QuotaOS.impact(.heavy)
            let recovered = 250 + (gameState.compiledQuotes.map(\.qMargin).max() ?? 0)
            gameState.bidDesk.runsCompleted += 1
            gameState.bidDesk.marginRecovered += recovered
            gameState.bidDesk.bestStealthRating = max(gameState.bidDesk.bestStealthRating, 100 - gameState.bidDesk.timesSpotted * 10)
            gameState.bidDesk.lastOutcome = "Recovered \(recovered) margin."
            gameState.commishCash += recovered
            gameState.lifetimeCommishCash += recovered
            gameState.completeCareerStep(.bidDesk)
            log = "Bid Desk approved the margin. +\(recovered) Commish-Cash."
            player = GridPoint2D(x: 0, y: 5)
        } else {
            log = "Stay out of the patrol cone."
        }
        gameState.persistCareer()
    }
}

private struct BidDeskBackdrop: View {
    var body: some View {
        ZStack {
            QuotaOS.Colors.ink
            LinearGradient(
                colors: [
                    Color.black,
                    QuotaOS.Colors.red.opacity(0.25),
                    QuotaOS.Colors.orange.opacity(0.12),
                    QuotaOS.Colors.ink
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Canvas { context, size in
                let laneHeight = max(34, size.height / 11)
                for y in stride(from: laneHeight, through: size.height, by: laneHeight) {
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: y))
                    line.addLine(to: CGPoint(x: size.width, y: y - 14))
                    context.stroke(line, with: .color(.white.opacity(0.035)), lineWidth: 1)
                }

                for x in stride(from: -size.width * 0.4, through: size.width * 1.2, by: 74) {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + size.height * 0.32, y: size.height))
                    context.stroke(path, with: .color(QuotaOS.Colors.gold.opacity(0.045)), lineWidth: 1)
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct BidDeskStatusRail: View {
    let runs: Int
    let recovered: Int
    let spotted: Int

    var body: some View {
        HStack(spacing: 8) {
            BidDeskMiniStat(title: "Runs", value: "\(runs)", icon: "figure.walk.motion", tint: QuotaOS.Colors.red)
            BidDeskMiniStat(title: "Margin", value: "\(recovered)", icon: "chart.line.uptrend.xyaxis", tint: QuotaOS.Colors.green)
            BidDeskMiniStat(title: "Eyes", value: "\(spotted)", icon: "eye.fill", tint: QuotaOS.Colors.gold)
        }
        .padding(7)
        .background(Color.white.opacity(0.66), in: Capsule())
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(QuotaOS.Colors.red.opacity(0.14), lineWidth: 1))
    }
}

private struct BidDeskMiniStat: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(tint)
                .frame(width: 22, height: 22)
                .background(tint.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 7.5, weight: .black, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.52))
                Text(value)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(QuotaOS.Colors.logoInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.74), in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.16), lineWidth: 1))
    }
}

private struct BidDeskFloorPlan: View {
    let player: GridPoint2D
    let patrol: GridPoint2D
    let exit: GridPoint2D
    let dangerCells: Set<GridPoint2D>

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 6)

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Margin Vault")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(QuotaOS.Colors.logoInk)
                    Text("Patrol cone sweeps every move")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.54))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "eye.trianglebadge.exclamationmark.fill")
                    Text("Finance")
                }
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(QuotaOS.Colors.gold)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(QuotaOS.Colors.gold.opacity(0.13), in: Capsule())
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(QuotaOS.Colors.gold.opacity(0.24), lineWidth: 1))
            }

            LazyVGrid(columns: columns, spacing: 7) {
                ForEach(0..<36) { index in
                    let point = GridPoint2D(x: index % 6, y: index / 6)
                    BidDeskCell(
                        point: point,
                        isPlayer: point == player,
                        isPatrol: point == patrol,
                        isExit: point == exit,
                        isDanger: dangerCells.contains(point)
                    )
                }
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.92),
                    QuotaOS.Colors.campusPink.opacity(0.24),
                    QuotaOS.Colors.gold.opacity(0.12),
                    QuotaOS.Colors.campusBlue.opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(QuotaOS.Colors.red.opacity(0.16), lineWidth: 1.2)
        )
        .shadow(color: QuotaOS.Colors.logoInk.opacity(0.10), radius: 22, y: 12)
    }
}

private struct BidDeskCell: View {
    let point: GridPoint2D
    let isPlayer: Bool
    let isPatrol: Bool
    let isExit: Bool
    let isDanger: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(tileFill)
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(tileStroke, lineWidth: isPlayer || isPatrol || isExit ? 1.5 : 1)

            if isDanger && !isPatrol && !isPlayer {
                Image(systemName: "viewfinder")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(QuotaOS.Colors.gold.opacity(0.58))
            }

            Image(systemName: icon)
                .font(.system(size: isPlayer || isPatrol || isExit ? 18 : 11, weight: .black))
                .foregroundStyle(iconColor)
                .opacity(isEmptyTile ? 0.55 : 1)
        }
        .aspectRatio(1, contentMode: .fit)
        .shadow(color: glowColor, radius: isPlayer || isPatrol || isExit ? 12 : 4, y: 5)
        .animation(QuotaOS.spring, value: isPlayer)
        .animation(QuotaOS.spring, value: isPatrol)
        .accessibilityLabel(accessibilityLabel)
    }

    private var isEmptyTile: Bool {
        !isPlayer && !isPatrol && !isExit
    }

    private var icon: String {
        if isPlayer { return "briefcase.fill" }
        if isPatrol { return "eye.fill" }
        if isExit { return "signature" }
        return point.y.isMultiple(of: 2) ? "rectangle.stack.fill" : "square.grid.2x2.fill"
    }

    private var tileFill: LinearGradient {
        let colors: [Color]
        if isPlayer {
            colors = [QuotaOS.Colors.blue.opacity(0.95), QuotaOS.Colors.mint.opacity(0.58)]
        } else if isPatrol {
            colors = [QuotaOS.Colors.red.opacity(0.96), QuotaOS.Colors.orange.opacity(0.62)]
        } else if isExit {
            colors = [QuotaOS.Colors.green.opacity(0.95), QuotaOS.Colors.gold.opacity(0.52)]
        } else if isDanger {
            colors = [QuotaOS.Colors.gold.opacity(0.36), QuotaOS.Colors.red.opacity(0.18), Color.white.opacity(0.50)]
        } else {
            colors = [Color.white.opacity(0.90), QuotaOS.Colors.campusBlue.opacity(0.18), QuotaOS.Colors.campusPink.opacity(0.08)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var tileStroke: Color {
        if isPlayer { return QuotaOS.Colors.mint.opacity(0.75) }
        if isPatrol { return QuotaOS.Colors.gold.opacity(0.65) }
        if isExit { return QuotaOS.Colors.green.opacity(0.74) }
        if isDanger { return QuotaOS.Colors.gold.opacity(0.28) }
        return QuotaOS.Colors.logoInk.opacity(0.08)
    }

    private var iconColor: Color {
        if isPatrol || isExit || isPlayer { return .white }
        return isDanger ? QuotaOS.Colors.red.opacity(0.52) : QuotaOS.Colors.logoInk.opacity(0.30)
    }

    private var glowColor: Color {
        if isPlayer { return QuotaOS.Colors.blue.opacity(0.32) }
        if isPatrol { return QuotaOS.Colors.red.opacity(0.32) }
        if isExit { return QuotaOS.Colors.green.opacity(0.24) }
        return QuotaOS.Colors.logoInk.opacity(0.08)
    }

    private var accessibilityLabel: String {
        if isPlayer { return "Quote runner at row \(point.y + 1), column \(point.x + 1)" }
        if isPatrol { return "Finance patrol at row \(point.y + 1), column \(point.x + 1)" }
        if isExit { return "Signature vault at row \(point.y + 1), column \(point.x + 1)" }
        if isDanger { return "Watched tile at row \(point.y + 1), column \(point.x + 1)" }
        return "Bid Desk tile row \(point.y + 1), column \(point.x + 1)"
    }
}

private struct BidDeskControlDeck: View {
    let moveUp: () -> Void
    let moveLeft: () -> Void
    let moveRight: () -> Void
    let reset: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: moveLeft) {
                controlIcon("arrow.left", label: "Move left", tint: QuotaOS.Colors.slate)
            }
            .buttonStyle(.plain)

            Button(action: moveUp) {
                controlIcon("arrow.up", label: "Advance", tint: QuotaOS.Colors.red, isPrimary: true)
            }
            .buttonStyle(.plain)

            Button(action: moveRight) {
                controlIcon("arrow.right", label: "Move right", tint: QuotaOS.Colors.slate)
            }
            .buttonStyle(.plain)

            Button(action: reset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(QuotaOS.Colors.orange.opacity(0.88), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.28), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reset Bid Desk run")
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.70), in: Capsule())
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(QuotaOS.Colors.logoInk.opacity(0.10), lineWidth: 1))
    }

    private func controlIcon(_ systemName: String, label: String, tint: Color, isPrimary: Bool = false) -> some View {
        Image(systemName: systemName)
            .font(.system(size: isPrimary ? 22 : 18, weight: .black))
            .foregroundStyle(.white)
            .frame(width: isPrimary ? 64 : 54, height: isPrimary ? 64 : 54)
            .background(tint.opacity(isPrimary ? 0.95 : 0.72), in: Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.28), lineWidth: 1))
            .shadow(color: tint.opacity(isPrimary ? 0.32 : 0.20), radius: isPrimary ? 14 : 8, y: 7)
            .accessibilityLabel(label)
    }
}

private struct GridPoint2D: Equatable, Hashable {
    var x: Int
    var y: Int
}

struct ExpenseRunView: View {
    var gameState: GameState
    var onClose: () -> Void

    private let tiles = ["Water Cooler", "Copy Center", "Executive Suite", "Breakroom", "Regional Client", "Community Chest", "Kickback", "Legal"]

    var body: some View {
        ZStack {
            QuotaBackdrop(tint: QuotaOS.Colors.purple)
            VStack(spacing: 14) {
                QuotaHeader(title: "Expense Run", subtitle: gameState.expenseRun.lastBoardEvent, tint: QuotaOS.Colors.purple, onClose: onClose)
                HStack(spacing: 8) {
                    QuotaMetricPill(title: "Tile", value: "\(gameState.expenseRun.boardPosition + 1)", icon: "mappin.circle.fill", tint: QuotaOS.Colors.purple)
                    QuotaMetricPill(title: "Listings", value: "\(gameState.expenseRun.regionalListings)", icon: "building.columns.fill", tint: QuotaOS.Colors.green)
                    QuotaMetricPill(title: "Revenge", value: "\(gameState.expenseRun.revengeList.count)", icon: "exclamationmark.triangle.fill", tint: QuotaOS.Colors.red)
                }
                .padding(.horizontal, 16)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(tiles.indices, id: \.self) { index in
                        HStack {
                            Image(systemName: gameState.expenseRun.boardPosition == index ? "location.fill" : "circle")
                            Text(tiles[index])
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            Spacer()
                        }
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background((gameState.expenseRun.boardPosition == index ? QuotaOS.Colors.purple : .white.opacity(0.08)),
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 16)

                QuotaPrimaryButton(title: "Roll Decision Dice", icon: "dice.fill", tint: QuotaOS.Colors.purple) {
                    roll()
                }
                .padding(.horizontal, 16)

                ListPanel(title: "REVENGE LIST", rows: gameState.expenseRun.revengeList.isEmpty ? ["No outstanding payback."] : gameState.expenseRun.revengeList)
                    .padding(.horizontal, 16)
                Spacer(minLength: 10)
            }
        }
    }

    private func roll() {
        let amount = Int.random(in: 1...6)
        gameState.expenseRun.diceRolls += 1
        gameState.expenseRun.boardPosition = (gameState.expenseRun.boardPosition + amount) % tiles.count
        let tile = tiles[gameState.expenseRun.boardPosition]

        switch tile {
        case "Water Cooler":
            gameState.expenseRun.revengeList.append("Corporate Audit launched from Water Cooler.")
            gameState.expenseRun.lastBoardEvent = "Audit rumor logged. Revenge list updated."
        case "Copy Center":
            gameState.commishCash = max(0, gameState.commishCash - 150)
            gameState.expenseRun.revengeList.append("Database Breach clipped 150 Commish-Cash.")
            gameState.expenseRun.lastBoardEvent = "Copy Center breach hit your offline cash."
        case "Executive Suite":
            gameState.expenseRun.regionalListings += 2
            gameState.expenseRun.lastBoardEvent = "Hostile takeover secured two regional listings."
        case "Breakroom":
            gameState.spiffCoins += 5
            gameState.expenseRun.lastBoardEvent = "Coffee break restored morale. +5 SPIFF."
        case "Community Chest":
            let friendBonus = max(1, gameState.expenseRun.friendNPCs.count) * 25
            gameState.basePay += friendBonus
            gameState.expenseRun.lastBoardEvent = "Imported coworkers helped. +\(friendBonus) Base Pay."
        case "Kickback":
            gameState.commishCash += 200
            gameState.lifetimeCommishCash += 200
            gameState.expenseRun.lastBoardEvent = "Regional kickback processed. +200 Commish-Cash."
        default:
            gameState.expenseRun.lastBoardEvent = "Legal routed the packet. Nothing exploded."
        }
        gameState.completeCareerStep(.qbrSocial)
        gameState.persistCareer()
    }
}

struct CorporateTreasuryView: View {
    var gameState: GameState
    var onClose: () -> Void

    private var deployedValue: Int {
        gameState.treasury.cloudIndexUnits * 120
        + gameState.treasury.hardwareIndexUnits * 95
        + gameState.treasury.servicesIndexUnits * 105
    }

    private var totalUnits: Int {
        gameState.treasury.cloudIndexUnits
        + gameState.treasury.hardwareIndexUnits
        + gameState.treasury.servicesIndexUnits
    }

    var body: some View {
        ZStack {
            QuotaBackdrop(tint: QuotaOS.Colors.mint, tone: .campus)

            VStack(spacing: 0) {
                QuotaHeader(title: "Corporate Treasury",
                            subtitle: gameState.treasury.lastMarketEvent,
                            tint: QuotaOS.Colors.mint,
                            tone: .campus,
                            onClose: onClose)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        TreasuryPortfolioStage(
                            basePay: gameState.basePay,
                            portfolioValue: gameState.treasury.portfolioValue,
                            deployedValue: deployedValue,
                            marketDay: gameState.treasury.marketDay,
                            units: totalUnits,
                            event: gameState.treasury.lastMarketEvent
                        )

                        HStack(spacing: 8) {
                            QuotaMetricPill(title: "Reserve",
                                            value: gameState.basePay.formatted(.number.grouping(.automatic)),
                                            icon: "banknote.fill",
                                            tint: QuotaOS.Colors.green,
                                            tone: .campus)
                            QuotaMetricPill(title: "Deployed",
                                            value: deployedValue.formatted(.number.grouping(.automatic)),
                                            icon: "briefcase.fill",
                                            tint: QuotaOS.Colors.mint,
                                            tone: .campus)
                            QuotaMetricPill(title: "Day",
                                            value: "\(gameState.treasury.marketDay)",
                                            icon: "calendar",
                                            tint: QuotaOS.Colors.gold,
                                            tone: .campus)
                        }

                        VStack(spacing: 10) {
                            TreasuryAssetCard(
                                name: "Cloud Index",
                                subtitle: "Pipeline velocity hedge",
                                units: gameState.treasury.cloudIndexUnits,
                                price: 120,
                                icon: "cloud.fill",
                                tint: QuotaOS.Colors.blue,
                                sparkline: [0.18, 0.30, 0.24, 0.48, 0.42, 0.70, 0.63],
                                buy: buyCloud
                            )
                            TreasuryAssetCard(
                                name: "Hardware Index",
                                subtitle: "Procurement resilience basket",
                                units: gameState.treasury.hardwareIndexUnits,
                                price: 95,
                                icon: "memorychip.fill",
                                tint: QuotaOS.Colors.orange,
                                sparkline: [0.50, 0.44, 0.52, 0.40, 0.58, 0.54, 0.62],
                                buy: buyHardware
                            )
                            TreasuryAssetCard(
                                name: "Services Index",
                                subtitle: "Consulting demand float",
                                units: gameState.treasury.servicesIndexUnits,
                                price: 105,
                                icon: "person.2.fill",
                                tint: QuotaOS.Colors.purple,
                                sparkline: [0.28, 0.36, 0.32, 0.44, 0.57, 0.50, 0.73],
                                buy: buyServices
                            )
                        }

                        TreasuryNotice()

                        QuotaPrimaryButton(title: "Close Market Day",
                                           icon: "clock.badge.checkmark.fill",
                                           tint: QuotaOS.Colors.mint) {
                            settleMarket()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 34)
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func buyCloud() { buy(price: 120) { gameState.treasury.cloudIndexUnits += 1 } }
    private func buyHardware() { buy(price: 95) { gameState.treasury.hardwareIndexUnits += 1 } }
    private func buyServices() { buy(price: 105) { gameState.treasury.servicesIndexUnits += 1 } }

    private func buy(price: Int, mutate: () -> Void) {
        guard gameState.basePay >= price else { return }
        gameState.basePay -= price
        mutate()
        gameState.treasury.basePayReserve = gameState.basePay
        gameState.treasury.lastMarketEvent = "Position added. Totally fictional, extremely corporate."
        gameState.persistCareer()
    }

    private func settleMarket() {
        let movement = Int.random(in: -80...220)
        gameState.basePay = max(0, gameState.basePay + movement)
        gameState.treasury.basePayReserve = gameState.basePay
        gameState.treasury.marketDay += 1
        gameState.treasury.lastMarketEvent = movement >= 0 ? "B2B indices rallied. +\(movement) Base Pay." : "Procurement macro dipped. \(movement) Base Pay."
        gameState.persistCareer()
    }
}

private struct TreasuryPortfolioStage: View {
    let basePay: Int
    let portfolioValue: Int
    let deployedValue: Int
    let marketDay: Int
    let units: Int
    let event: String

    private var deployedFraction: Double {
        guard portfolioValue > 0 else { return 0 }
        return min(1, Double(deployedValue) / Double(portfolioValue))
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            TreasuryDeskIllustration(fraction: deployedFraction)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FICTIONAL PORTFOLIO DESK")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(QuotaOS.Colors.mint)
                        Text("Hedge Base Pay Against B2B Weather")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(QuotaOS.Colors.logoInk)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                    }
                    Spacer(minLength: 10)
                    TreasuryAllocationRing(fraction: deployedFraction)
                        .frame(width: 66, height: 66)
                }

                Spacer(minLength: 36)

                HStack(alignment: .bottom, spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("$\(portfolioValue.formatted(.number.grouping(.automatic)))")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(QuotaOS.Colors.logoInk)
                            .lineLimit(1)
                            .minimumScaleFactor(0.64)
                        Text(event)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.62))
                            .lineLimit(2)
                            .lineSpacing(2)
                    }
                    Spacer()
                    VStack(spacing: 7) {
                        TreasuryMiniBadge(icon: "calendar", text: "Day \(marketDay)", tint: QuotaOS.Colors.gold)
                        TreasuryMiniBadge(icon: "square.stack.3d.up.fill", text: "\(units) units", tint: QuotaOS.Colors.mint)
                    }
                }
            }
            .padding(18)
        }
        .frame(minHeight: 292)
        .background(
            LinearGradient(colors: [
                Color.white.opacity(0.92),
                QuotaOS.Colors.campusMint.opacity(0.42),
                QuotaOS.Colors.campusBlue.opacity(0.24),
                QuotaOS.Colors.campusPink.opacity(0.18)
            ], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(QuotaOS.Colors.mint.opacity(0.22), lineWidth: 1.3)
        )
        .shadow(color: QuotaOS.Colors.logoInk.opacity(0.12), radius: 20, y: 12)
    }
}

private struct TreasuryDeskIllustration: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(QuotaOS.Colors.campusBlue.opacity(0.18))
                    .frame(width: size.width * 0.66, height: size.height * 0.42)
                    .offset(x: size.width * 0.10, y: -size.height * 0.02)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(QuotaOS.Colors.campusPink.opacity(0.16))
                    .frame(width: size.width * 0.38, height: size.height * 0.35)
                    .offset(x: -size.width * 0.25, y: size.height * 0.08)
                TreasurySparkline(points: [0.24, 0.38, 0.32, 0.54, 0.48, 0.72, 0.66],
                                  tint: QuotaOS.Colors.mint,
                                  lineWidth: 5)
                    .frame(width: size.width * 0.72, height: size.height * 0.32)
                    .offset(x: size.width * 0.05, y: size.height * 0.10)
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(index == 0 ? QuotaOS.Colors.mint : Color.white.opacity(0.82))
                        .frame(width: index == 0 ? 18 : 12, height: index == 0 ? 18 : 12)
                        .overlay(Circle().stroke(.white.opacity(0.72), lineWidth: 2))
                        .position(
                            x: size.width * (0.16 + CGFloat(index) * 0.17),
                            y: size.height * (0.64 - CGFloat(index % 2) * 0.14)
                        )
                }
            }
            .opacity(0.78)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .allowsHitTesting(false)
    }
}

private struct TreasuryAllocationRing: View {
    let fraction: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(QuotaOS.Colors.logoInk.opacity(0.10), lineWidth: 8)
            Circle()
                .trim(from: 0, to: min(1, max(0, fraction)))
                .stroke(
                    LinearGradient(colors: [QuotaOS.Colors.mint, QuotaOS.Colors.blue],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("\(Int((fraction * 100).rounded()))%")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(QuotaOS.Colors.logoInk)
                .monospacedDigit()
        }
    }
}

private struct TreasuryMiniBadge: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .black))
            Text(text)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(QuotaOS.Colors.logoInk)
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.74), in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.22), lineWidth: 1))
    }
}

private struct TreasuryAssetCard: View {
    let name: String
    let subtitle: String
    let units: Int
    let price: Int
    let icon: String
    let tint: Color
    let sparkline: [Double]
    let buy: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(colors: [tint, tint.opacity(0.58)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(.white.opacity(0.26), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(name)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(QuotaOS.Colors.logoInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text("\(units)x")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(tint.opacity(0.12), in: Capsule())
                }
                Text(subtitle)
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.52))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                HStack(spacing: 8) {
                    TreasurySparkline(points: sparkline, tint: tint, lineWidth: 3)
                        .frame(width: 78, height: 24)
                    Text("\(price) Base Pay")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.56))
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(action: buy) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .black))
                Text("Buy")
                    .font(.system(size: 13, weight: .black, design: .rounded))
            }
                .foregroundStyle(.white)
                .padding(.horizontal, 13)
                .frame(height: 42)
                .background(
                    LinearGradient(colors: [tint, tint.opacity(0.64)],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing),
                    in: Capsule()
                )
                .shadow(color: tint.opacity(0.24), radius: 10, y: 6)
        }
        .padding(14)
        .background(Color.white.opacity(0.70), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: QuotaOS.Colors.logoInk.opacity(0.08), radius: 14, y: 8)
    }
}

private struct TreasurySparkline: View {
    let points: [Double]
    let tint: Color
    let lineWidth: CGFloat

    var body: some View {
        GeometryReader { proxy in
            Path { path in
                guard let first = points.first else { return }
                path.move(to: point(at: 0, value: first, in: proxy.size))
                for index in points.indices.dropFirst() {
                    path.addLine(to: point(at: index, value: points[index], in: proxy.size))
                }
            }
            .stroke(
                LinearGradient(colors: [tint, QuotaOS.Colors.campusPink],
                               startPoint: .leading,
                               endPoint: .trailing),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
            )
        }
    }

    private func point(at index: Int, value: Double, in size: CGSize) -> CGPoint {
        let count = max(1, points.count - 1)
        let x = CGFloat(index) / CGFloat(count) * size.width
        let y = (1 - CGFloat(max(0, min(1, value)))) * size.height
        return CGPoint(x: x, y: y)
    }
}

private struct TreasuryNotice: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(QuotaOS.Colors.blue)
                .frame(width: 30, height: 30)
                .background(QuotaOS.Colors.blue.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("Game economy only")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk)
                Text("These local indices are fictional hedges for Base Pay. No real money, broker, backend, or financial advice.")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.54))
                    .lineSpacing(2)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(QuotaOS.Colors.blue.opacity(0.14), lineWidth: 1)
        )
    }
}

struct CorporateOutfitterView: View {
    var gameState: GameState
    @ObservedObject var inventory: InventoryManager
    var onClose: () -> Void

    private let shopItems: [(WearableItem, Int)] = [
        (WearableCatalog.blueLightGlasses, 300),
        (WearableCatalog.aviators, 420),
        (WearableCatalog.spreadsheetSpecs, 550),
        (WearableCatalog.noiseCancelingHeadphones, 650),
        (WearableCatalog.gradCap, 900),
        (WearableCatalog.patagoniaVCFleece, 1_200),
        (WearableCatalog.mustardTie, 75),
        (WearableCatalog.diamondLanyard, 2_500),
        (WearableCatalog.foundersCrown, 4_000)
    ]

    var body: some View {
        ZStack {
            QuotaBackdrop(tint: QuotaOS.Colors.pink, tone: .campus)
            VStack(spacing: 14) {
                QuotaHeader(title: "Corporate Outfitter", subtitle: "Commish-Cash fashion desk.", tint: QuotaOS.Colors.pink, tone: .campus, onClose: onClose)

                HStack(spacing: 10) {
                    QuotaMetricPill(title: "Commish-Cash", value: "\(gameState.commishCash)", icon: "dollarsign.circle.fill", tint: QuotaOS.Colors.green, tone: .campus)
                    QuotaMetricPill(title: "Catalog", value: "\(shopItems.count)", icon: "sparkles", tint: QuotaOS.Colors.pink, tone: .campus)
                }
                .padding(.horizontal, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(shopItems, id: \.0.id) { item, price in
                            let owned = inventory.ownsItem(id: item.id)
                            let canAfford = gameState.commishCash >= price

                            HStack(spacing: 12) {
                                Image(systemName: item.imageIcon)
                                    .font(.system(size: 24, weight: .black))
                                    .foregroundStyle(item.tint.color)
                                    .frame(width: 52, height: 52)
                                    .background(item.tint.color.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(item.tint.color.opacity(0.22), lineWidth: 1))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.system(size: 15, weight: .black, design: .rounded))
                                        .foregroundStyle(QuotaOS.Colors.logoInk)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.76)
                                    Text(item.boostText)
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.56))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.76)
                                }
                                Spacer(minLength: 0)

                                Button {
                                    buy(item, price: price)
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: owned ? "checkmark" : "dollarsign.circle.fill")
                                            .font(.system(size: 11, weight: .black))
                                        Text(owned ? "Owned" : "\(price)")
                                            .font(.system(size: 13, weight: .black, design: .rounded))
                                            .monospacedDigit()
                                    }
                                    .foregroundStyle(owned ? QuotaOS.Colors.logoInk.opacity(0.56) : .white)
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 9)
                                    .background(owned ? QuotaOS.Colors.logoInk.opacity(0.08) : (canAfford ? QuotaOS.Colors.pink : QuotaOS.Colors.slate.opacity(0.58)), in: Capsule())
                                }
                                .buttonStyle(.plain)
                                .disabled(owned || !canAfford)
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(item.tint.color.opacity(0.16), lineWidth: 1))
                            .shadow(color: QuotaOS.Colors.logoInk.opacity(0.07), radius: 9, y: 5)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func buy(_ item: WearableItem, price: Int) {
        guard gameState.commishCash >= price, inventory.grant(item) else { return }
        gameState.commishCash -= price
        gameState.persistCareer()
    }
}

struct SocialLinksView: View {
    var gameState: GameState
    @ObservedObject var inventory: InventoryManager
    @ObservedObject var avatar: PlayerAvatar
    var stats: QBRStats
    var onClose: () -> Void

    @State private var importText = ""
    @State private var message = "Local Rolodex ready."

    private var payload: QBRSharePayload {
        QBRSharePayload(name: stats.name,
                        title: stats.title,
                        lifetimeCash: stats.lifetimeCash,
                        wins: stats.wins,
                        losses: stats.losses,
                        badgeTier: stats.tier,
                        outfitIDs: inventory.equippedItems.map(\.id))
    }

    var body: some View {
        ZStack {
            QuotaBackdrop(tint: QuotaOS.Colors.blue)
            VStack(spacing: 14) {
                QuotaHeader(title: "Rolodex", subtitle: message, tint: QuotaOS.Colors.blue, onClose: onClose)
                QRCodeView(text: payload.encodedString)
                    .frame(width: 180, height: 180)
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                Text(payload.encodedString)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(3)
                    .padding(.horizontal, 18)

                VStack(spacing: 10) {
                    TextField("Paste OTS friend string", text: $importText)
                        .textInputAutocapitalization(.never)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .padding(12)
                        .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(.white)
                    QuotaPrimaryButton(title: "Import Friend NPC", icon: "person.badge.plus.fill", tint: QuotaOS.Colors.blue) {
                        importFriend()
                    }
                }
                .padding(.horizontal, 16)

                ListPanel(title: "BREAKROOM NPCS",
                          rows: gameState.expenseRun.friendNPCs.isEmpty ? ["No imported coworkers yet."] : gameState.expenseRun.friendNPCs.map(\.flexLine))
                    .padding(.horizontal, 16)
                Spacer(minLength: 10)
            }
        }
    }

    private func importFriend() {
        guard let decoded = QBRSharePayload.decode(importText) else {
            message = "That friend string did not badge through security."
            return
        }
        let friend = decoded.friendNPC()
        if !gameState.expenseRun.friendNPCs.contains(where: { $0.id == friend.id }) {
            gameState.expenseRun.friendNPCs.append(friend)
        }
        gameState.completeCareerStep(.qbrSocial)
        gameState.persistCareer()
        message = "\(friend.name) now wanders your Breakroom."
    }
}

struct EndgameView: View {
    var gameState: GameState
    var onClose: () -> Void

    private var bestQuote: ContractWeapon? {
        gameState.compiledQuotes.max { $0.qMargin < $1.qMargin }
    }

    var body: some View {
        ZStack {
            QuotaBackdrop(tint: QuotaOS.Colors.gold)
            VStack(spacing: 14) {
                QuotaHeader(title: "Platinum Trip", subtitle: gameState.endgame.lastFinaleLog, tint: QuotaOS.Colors.gold, onClose: onClose)
                HStack(spacing: 8) {
                    QuotaMetricPill(title: "Lifetime", value: "\(gameState.lifetimeCommishCash)", icon: "dollarsign.circle.fill", tint: QuotaOS.Colors.green)
                    QuotaMetricPill(title: "Target", value: "\(gameState.endgame.quotaTarget)", icon: "target", tint: QuotaOS.Colors.gold)
                }
                .padding(.horizontal, 16)
                ProgressView(value: min(1, Double(gameState.lifetimeCommishCash) / Double(gameState.endgame.quotaTarget)))
                    .tint(QuotaOS.Colors.gold)
                    .padding(.horizontal, 22)

                if let bestQuote {
                    ListPanel(title: "CFO MATH WEAPON", rows: ["\(bestQuote.name)", "Q-Margin \(bestQuote.qMargin)", "Damage \(bestQuote.baseDamage)"])
                        .padding(.horizontal, 16)
                } else {
                    ListPanel(title: "CFO MATH WEAPON", rows: ["Compile a quote in Q-Bot before challenging the CFO."])
                        .padding(.horizontal, 16)
                }

                QuotaPrimaryButton(title: "Run Executive Forecast", icon: "function", tint: QuotaOS.Colors.gold, disabled: bestQuote == nil) {
                    forecast()
                }
                .padding(.horizontal, 16)
                QuotaPrimaryButton(title: "Challenge Grumpy CFO", icon: "person.crop.circle.badge.exclamationmark.fill", tint: QuotaOS.Colors.red, disabled: !canChallengeCFO) {
                    challengeCFO()
                }
                .padding(.horizontal, 16)
                Spacer(minLength: 10)
            }
        }
    }

    private var canChallengeCFO: Bool {
        gameState.lifetimeCommishCash >= gameState.endgame.quotaTarget && (bestQuote?.qMargin ?? 0) >= 500
    }

    private func forecast() {
        let boost = max(100_000, (bestQuote?.qMargin ?? 100) * 1_000)
        gameState.lifetimeCommishCash += boost
        gameState.commishCash += boost / 10
        gameState.endgame.lastFinaleLog = "Forecast math impressed the board. +\(boost) lifetime quota credit."
        gameState.persistCareer()
    }

    private func challengeCFO() {
        gameState.endgame.cfoDefeated = true
        gameState.endgame.islaUnlocked = true
        gameState.endgame.newGamePlus = true
        gameState.endgame.lastFinaleLog = "CFO defeated by pure quote math. Isla de Sinergia unlocked."
        gameState.completeCareerStep(.endgame)
        gameState.persistCareer()
    }
}

private struct ListPanel: View {
    let title: String
    let rows: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
            ForEach(rows, id: \.self) { row in
                Text(row)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(14)
        .background(.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct QRCodeView: View {
    let text: String
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        if let image = makeQRCode() {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            Color.white
        }
    }

    private func makeQRCode() -> UIImage? {
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
