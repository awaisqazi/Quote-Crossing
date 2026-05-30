//
//  SalesEncounterView.swift
//  Quote Crossing
//
//  The Sales Encounter battle screen (GDD §5). Prospect on top with a
//  Skepticism bar; the player below with Patience (HP) + Jargon (MP), Jargon
//  Cards, combo state, and the E-Sign Sphere capture overlay.
//

import SwiftUI

struct SalesEncounterView: View {
    @ObservedObject var viewModel: EncounterViewModel
    @ObservedObject var avatar: PlayerAvatar
    var wearables: [WearableItem]
    var playerName: String

    var body: some View {
        ZStack {
            background

            VStack(spacing: 12) {
                prospectRow
                logBanner
                Spacer(minLength: 0)
                playerRow
                actionArea
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
            .padding(.bottom, 18)

            if viewModel.isThrowingSphere {
                SphereThrowOverlay()
                    .transition(.opacity)
            }
            if let outcome = viewModel.outcome {
                ResultOverlay(outcome: outcome, reward: rewardValue(outcome))
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .ignoresSafeArea()
    }

    private func rewardValue(_ o: EncounterViewModel.Outcome) -> Int {
        if case .win(let r) = o { return r }
        return 0
    }

    // MARK: Background

    private var background: some View {
        LinearGradient(
            colors: [Color(red: 0.16, green: 0.18, blue: 0.30),
                     Color(red: 0.28, green: 0.24, blue: 0.40)],
            startPoint: .top, endPoint: .bottom
        )
    }

    // MARK: Prospect (top)

    private var prospectRow: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.prospect.name)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                ElementPill(element: viewModel.prospect.element)
                StatusBadgeStrip(statuses: viewModel.prospectStatuses)
                BattleBar(label: "Skepticism", value: viewModel.skepticism,
                          maxValue: viewModel.maxSkepticism,
                          tint: Color(red: 0.92, green: 0.42, blue: 0.40),
                          icon: "exclamationmark.bubble.fill")
            }
            EnemyAvatarView(prospect: viewModel.prospect)
        }
        .padding(14)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: Log

    private var logBanner: some View {
        Text(viewModel.logMessage)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .animation(.easeInOut(duration: 0.2), value: viewModel.logMessage)
    }

    // MARK: Player (bottom)

    private var playerRow: some View {
        HStack(alignment: .center, spacing: 14) {
            AvatarView(avatar: avatar, wearables: wearables)
                .scaleEffect(0.5)
                .frame(width: 100, height: 120)
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(playerName)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    ElementPill(element: viewModel.playerElement)
                    Text("Combo \(viewModel.alphaSynergyLabel)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.24), in: Capsule())
                }
                StatusBadgeStrip(statuses: viewModel.playerStatuses)
                BattleBar(label: "Patience", value: viewModel.patience,
                          maxValue: viewModel.maxPatience,
                          tint: Color(red: 0.36, green: 0.82, blue: 0.50),
                          icon: "heart.fill")
                BattleBar(label: "Jargon", value: viewModel.jargon,
                          maxValue: viewModel.maxJargon,
                          tint: Color(red: 0.58, green: 0.45, blue: 0.92),
                          icon: "text.bubble.fill")
            }
        }
        .padding(14)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: Actions

    private var actionArea: some View {
        VStack(spacing: 12) {
            jargonCardArea

            if let state = viewModel.gameState, !state.compiledQuotes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ACTIVE PORTFOLIO (TAP TO PITCH)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .tracking(0.8)
                        .padding(.horizontal, 4)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(state.compiledQuotes) { weapon in
                                QuoteWeaponCard(
                                    weapon: weapon,
                                    currentJargon: viewModel.jargon,
                                    canPlay: viewModel.canDeployQuote(weapon)
                                ) {
                                    viewModel.perform(.deployQuote(weapon))
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 2)
                    }
                }
                .disabled(viewModel.actionsDisabled)
                .opacity(viewModel.actionsDisabled ? 0.55 : 1.0)
            }

            if viewModel.canThrowSphere {
                ESignSphereButton { viewModel.throwESignSphere() }
                    .disabled(viewModel.actionsDisabled)
                    .transition(.scale.combined(with: .opacity))
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                      spacing: 10) {
                ActionButton(title: "Listen", subtitle: "Heal Patience", icon: "ear.fill",
                             tint: Color(red: 0.22, green: 0.70, blue: 0.52),
                             disabled: viewModel.comboOpener != nil) {
                    viewModel.perform(.listen)
                }
                ActionButton(title: "Use Item", subtitle: "Espresso ×\(viewModel.items)",
                             icon: "cup.and.saucer.fill",
                             tint: Color(red: 0.78, green: 0.52, blue: 0.24),
                             disabled: viewModel.items == 0 || viewModel.comboOpener != nil) {
                    viewModel.perform(.item)
                }
                ActionButton(title: "Flee", subtitle: "75% escape", icon: "figure.run",
                             tint: Color(red: 0.55, green: 0.55, blue: 0.62),
                             disabled: viewModel.comboOpener != nil) {
                    viewModel.perform(.flee)
                }
            }
            .disabled(viewModel.actionsDisabled)
            .opacity(viewModel.actionsDisabled ? 0.55 : 1)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.canThrowSphere)
    }

    private var jargonCardArea: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("JARGON CARDS")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .tracking(0.8)
                Spacer()
                if let opener = viewModel.comboOpener {
                    Text("Opener: \(opener.name)")
                        .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.jargonCards) { card in
                        JargonCardButton(
                            card: card,
                            currentJargon: viewModel.jargon,
                            isQueued: viewModel.comboOpener?.id == card.id,
                            canPlay: viewModel.canPlay(card)
                        ) {
                            viewModel.perform(.playCard(card))
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 2)
            }

            if let opener = viewModel.comboOpener {
                ComboOpenerBanner(
                    opener: opener,
                    alphaLabel: viewModel.alphaSynergyLabel,
                    canCommit: viewModel.canCommitComboOpener
                ) {
                    viewModel.commitComboOpener()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .disabled(viewModel.actionsDisabled)
        .opacity(viewModel.actionsDisabled ? 0.55 : 1.0)
    }
}

// MARK: - Battle bar

private struct BattleBar: View {
    var label: String
    var value: Int
    var maxValue: Int
    var tint: Color
    var icon: String

    private var fraction: CGFloat {
        maxValue <= 0 ? 0 : max(0, min(1, CGFloat(value) / CGFloat(maxValue)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 11, weight: .bold))
                Text(label).font(.system(size: 11, weight: .heavy, design: .rounded)).tracking(0.3)
                Spacer()
                Text("\(value)/\(maxValue)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(.white.opacity(0.9))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.black.opacity(0.28))
                    Capsule().fill(tint)
                        .frame(width: fraction * geo.size.width)
                        .animation(.easeOut(duration: 0.35), value: value)
                }
            }
            .frame(height: 10)
        }
    }
}

// MARK: - Element / status badges

private struct ElementPill: View {
    let element: JargonElement

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: element.symbolName)
                .font(.system(size: 9, weight: .black))
            Text(element.rawValue)
                .font(.system(size: 10, weight: .black, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(element.color.opacity(0.82), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 1))
    }
}

private struct StatusBadgeStrip: View {
    let statuses: [ActiveStatusEffect]

    var body: some View {
        if !statuses.isEmpty {
            HStack(spacing: 5) {
                ForEach(statuses) { status in
                    HStack(spacing: 3) {
                        Image(systemName: status.effect.symbolName)
                            .font(.system(size: 8, weight: .black))
                        Text("\(status.effect.rawValue) \(status.turnsRemaining)")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(status.effect.color.opacity(0.8), in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 1))
                }
            }
        }
    }
}

// MARK: - Jargon card

private struct JargonCardButton: View {
    let card: JargonCard
    let currentJargon: Int
    let isQueued: Bool
    let canPlay: Bool
    let action: () -> Void

    private var isUnaffordable: Bool { currentJargon < card.cost }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .top, spacing: 6) {
                    Text(card.name)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                    Spacer(minLength: 0)
                    Image(systemName: card.element.symbolName)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(card.element.color)
                }

                HStack(spacing: 7) {
                    statChip(icon: "text.bubble.fill", text: "\(card.cost)",
                             color: isUnaffordable ? Color(red: 0.96, green: 0.42, blue: 0.42) : Color(red: 0.75, green: 0.65, blue: 1.0))
                    if card.isOffensive {
                        statChip(icon: card.damageType.symbolName, text: "\(card.damage)",
                                 color: Color(red: 0.96, green: 0.47, blue: 0.42))
                    }
                    if card.isHealing {
                        statChip(icon: "heart.fill", text: "+\(card.healing)",
                                 color: Color(red: 0.38, green: 0.86, blue: 0.55))
                    }
                }

                HStack(spacing: 5) {
                    Text(card.element.rawValue)
                        .font(.system(size: 9, weight: .black, design: .rounded))
                    if isQueued {
                        Text("OPENER")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                    }
                }
                .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(width: 158, alignment: .topLeading)
            .frame(minHeight: 96, alignment: .topLeading)
            .background(
                LinearGradient(
                    colors: cardBackground,
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isQueued ? Color.white.opacity(0.7) : card.element.color.opacity(0.55),
                            lineWidth: isQueued ? 2 : 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canPlay)
        .opacity(canPlay ? 1.0 : 0.48)
    }

    private var cardBackground: [Color] {
        if !canPlay {
            return [Color(red: 0.16, green: 0.16, blue: 0.20),
                    Color(red: 0.09, green: 0.09, blue: 0.12)]
        }
        return [card.element.color.opacity(0.52),
                Color(red: 0.10, green: 0.12, blue: 0.18)]
    }

    private func statChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .black))
            Text(text)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(color)
    }
}

private struct ComboOpenerBanner: View {
    let opener: JargonCard
    let alphaLabel: String
    let canCommit: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "link")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(opener.element.color)
            VStack(alignment: .leading, spacing: 1) {
                Text(opener.name)
                    .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("Catalyst bonus \(alphaLabel)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }
            Spacer(minLength: 0)
            Button(action: action) {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .black))
                    Text("Commit")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                }
                .foregroundStyle(Color(red: 0.16, green: 0.14, blue: 0.08))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(red: 0.98, green: 0.78, blue: 0.28), in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canCommit)
            .opacity(canCommit ? 1 : 0.45)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(.white.opacity(0.16), lineWidth: 1))
    }
}

// MARK: - Enemy avatar

private struct EnemyAvatarView: View {
    let prospect: EnemyProspect

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(prospect.tint.color)
                .frame(width: 92, height: 92)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.25), lineWidth: 2))
            Image(systemName: prospect.symbol)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
        }
        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
    }
}

// MARK: - Action button

private struct ActionButton: View {
    var title: String
    var subtitle: String
    var icon: String
    var tint: Color
    var disabled: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 14, weight: .heavy, design: .rounded))
                    Text(subtitle).font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        .opacity(0.85)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [tint, tint.opacity(0.78)],
                               startPoint: .top, endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }
}

// MARK: - E-Sign Sphere button

private struct ESignSphereButton: View {
    var action: () -> Void
    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "signature")
                    .font(.system(size: 20, weight: .bold))
                Text("Throw E-Sign Sphere")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(Color(red: 0.20, green: 0.16, blue: 0.05))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                LinearGradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.35),
                                        Color(red: 0.98, green: 0.72, blue: 0.18)],
                               startPoint: .top, endPoint: .bottom),
                in: Capsule()
            )
            .overlay(Capsule().stroke(.white.opacity(0.6), lineWidth: 2))
            .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.3).opacity(0.7),
                    radius: pulse ? 16 : 6)
            .scaleEffect(pulse ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Sphere throw animation

private struct SphereThrowOverlay: View {
    @State private var fly = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(colors: [.white, Color(red: 0.35, green: 0.62, blue: 0.98)],
                                       center: .topLeading, startRadius: 2, endRadius: 40)
                    )
                    .overlay(
                        Image(systemName: "signature")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color(red: 0.16, green: 0.30, blue: 0.62))
                    )
                    .overlay(Circle().stroke(.white, lineWidth: 3))
                    .frame(width: 56, height: 56)
                    .scaleEffect(fly ? 0.7 : 1.0)
                    .rotationEffect(.degrees(fly ? 540 : 0))
                    .position(x: geo.size.width / 2,
                              y: fly ? geo.size.height * 0.2 : geo.size.height * 0.78)
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 4)
            }
            .onAppear {
                withAnimation(.easeIn(duration: 0.55)) { fly = true }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Result overlay

private struct ResultOverlay: View {
    let outcome: EncounterViewModel.Outcome
    let reward: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                if reward > 0 {
                    Text("+\(reward) Commish-Cash")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 0.22, green: 0.85, blue: 0.56))
                }
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    private var title: String {
        switch outcome {
        case .win:  "DEAL CLOSED!"
        case .lose: "DEAL LOST"
        case .fled: "GOT AWAY!"
        }
    }
    private var symbol: String {
        switch outcome {
        case .win:  "checkmark.seal.fill"
        case .lose: "xmark.seal.fill"
        case .fled: "figure.run"
        }
    }
    private var tint: Color {
        switch outcome {
        case .win:  Color(red: 0.30, green: 0.85, blue: 0.55)
        case .lose: Color(red: 0.92, green: 0.42, blue: 0.40)
        case .fled: Color(red: 0.85, green: 0.85, blue: 0.5)
        }
    }
}

// MARK: - Quote weapon card

private struct QuoteWeaponCard: View {
    let weapon: ContractWeapon
    let currentJargon: Int
    let canPlay: Bool
    let action: () -> Void

    private var card: JargonCard { JargonCard(contractWeapon: weapon) }
    private var isUnaffordable: Bool { currentJargon < weapon.jargonCost }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                // Header name
                HStack(spacing: 6) {
                    Text(weapon.name)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: card.element.symbolName)
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(card.element.color)
                }

                HStack(spacing: 8) {
                    // Jargon Cost badge
                    HStack(spacing: 3) {
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 9))
                        Text("\(weapon.jargonCost)")
                            .font(.system(size: 10, weight: .heavy))
                    }
                    .foregroundStyle(isUnaffordable ? Color(red: 0.95, green: 0.45, blue: 0.45) : Color(red: 0.75, green: 0.65, blue: 1.0))

                    // Damage badge
                    HStack(spacing: 3) {
                        Image(systemName: card.damageType.symbolName)
                            .font(.system(size: 9))
                        Text("\(weapon.baseDamage)")
                            .font(.system(size: 10, weight: .heavy))
                    }
                    .foregroundStyle(Color(red: 0.95, green: 0.45, blue: 0.45))

                    // Margin badge
                    HStack(spacing: 3) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 9))
                        Text("$\(weapon.qMargin)")
                            .font(.system(size: 10, weight: .heavy))
                    }
                    .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.60))
                }

                HStack(spacing: 5) {
                    Text(card.element.rawValue)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                    if isUnaffordable {
                        Text("NEEDS JARGON")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                    }
                }
                .foregroundStyle(isUnaffordable ? Color(red: 0.95, green: 0.45, blue: 0.45).opacity(0.9) : .white.opacity(0.74))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(width: 170)
            .background(
                LinearGradient(
                    colors: !canPlay
                        ? [Color(red: 0.25, green: 0.12, blue: 0.12), Color(red: 0.15, green: 0.06, blue: 0.06)]
                        : [card.element.color.opacity(0.38), Color(red: 0.10, green: 0.12, blue: 0.18)],
                    startPoint: .top, endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        !canPlay
                            ? Color(red: 0.95, green: 0.45, blue: 0.45).opacity(0.6)
                            : card.element.color.opacity(0.5),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!canPlay)
        .opacity(canPlay ? 1 : 0.5)
    }
}
