//
//  SalesEncounterView.swift
//  Quote Crossing
//
//  The Sales Encounter battle screen (GDD §5). Prospect on top with a
//  Skepticism bar; the player below with Patience (HP) + Jargon (MP) bars and a
//  2×2 action menu. Once the Prospect is below 20% Skepticism, the E-Sign
//  Sphere appears to close the deal.
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
        VStack(spacing: 10) {
            if viewModel.canThrowSphere {
                ESignSphereButton { viewModel.throwESignSphere() }
                    .disabled(viewModel.actionsDisabled)
                    .transition(.scale.combined(with: .opacity))
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                      spacing: 10) {
                ActionButton(title: "Pitch Synergy", subtitle: "−6 Jargon", icon: "megaphone.fill",
                             tint: Color(red: 0.30, green: 0.55, blue: 0.95)) {
                    viewModel.perform(.pitch)
                }
                ActionButton(title: "Listen", subtitle: "Heal Patience", icon: "ear.fill",
                             tint: Color(red: 0.22, green: 0.70, blue: 0.52)) {
                    viewModel.perform(.listen)
                }
                ActionButton(title: "Use Item", subtitle: "Espresso ×\(viewModel.items)",
                             icon: "cup.and.saucer.fill",
                             tint: Color(red: 0.78, green: 0.52, blue: 0.24),
                             disabled: viewModel.items == 0) {
                    viewModel.perform(.item)
                }
                ActionButton(title: "Flee", subtitle: "75% escape", icon: "figure.run",
                             tint: Color(red: 0.55, green: 0.55, blue: 0.62)) {
                    viewModel.perform(.flee)
                }
            }
            .disabled(viewModel.actionsDisabled)
            .opacity(viewModel.actionsDisabled ? 0.55 : 1)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.canThrowSphere)
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
