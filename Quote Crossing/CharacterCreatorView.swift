//
//  CharacterCreatorView.swift
//  Quote Crossing
//
//  GDD §1 "The Badging Process". A live, expressive character creator: an
//  OTS ID-badge preview up top, customisation controls below, and a
//  "Print ID Badge" button that persists the avatar and enters the overworld.
//

import SwiftUI

struct CharacterCreatorView: View {
    /// Called once the badge is printed and the avatar has been saved.
    var onComplete: () -> Void

    @StateObject private var avatar = PlayerAvatar()
    @FocusState private var nameFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            let compactPreview = proxy.size.height < 780 || proxy.size.width < 390
            let previewHeight: CGFloat = compactPreview ? 154 : 182
            let previewTopInset = max(proxy.safeAreaInsets.top, 12)
            let previewReserve = previewHeight + previewTopInset + 18

            ZStack(alignment: .top) {
                backdrop

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        controls
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, previewReserve + 4)
                    .padding(.bottom, 136)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .scrollDismissesKeyboard(.interactively)

                pinnedPreviewDock(compact: compactPreview)
                    .frame(height: previewReserve + 24)
                    .ignoresSafeArea(edges: .top)
                    .zIndex(2)

                CreatorHeroPreview(avatar: avatar, compact: compactPreview)
                    .padding(.horizontal, 16)
                    .padding(.top, previewTopInset + 6)
                    .frame(height: previewTopInset + previewHeight, alignment: .top)
                    .zIndex(3)
            }
            .ignoresSafeArea(.container, edges: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(.light)
        .safeAreaInset(edge: .bottom) {
            printButton
                .padding(.top, 14)
                .background(alignment: .bottom) {
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.0), location: 0.0),
                            .init(color: Color(red: 0.98, green: 0.99, blue: 1.0).opacity(0.96), location: 0.26),
                            .init(color: Color.white.opacity(0.99), location: 0.62),
                            .init(color: Color.white, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .bottom)
                }
        }
    }

    // MARK: Chrome

    private var backdrop: some View {
        LogoCreatorBackdrop()
            .ignoresSafeArea()
    }

    private func pinnedPreviewDock(compact: Bool) -> some View {
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.99, blue: 1.0),
                Color(red: 0.94, green: 0.98, blue: 1.0),
                Color(red: 0.99, green: 0.93, blue: 0.98).opacity(compact ? 0.96 : 0.90),
                Color.white.opacity(0.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }

    private var header: some View {
        VStack(spacing: 2) {
            Text("THE BADGING PROCESS")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(Color(red: 0.18, green: 0.10, blue: 0.24))
            Text("Welcome to OmniTech, new hire.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 0.36, green: 0.34, blue: 0.44))
        }
        .padding(.top, 10)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.52))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(red: 0.18, green: 0.10, blue: 0.24).opacity(0.08))
                .frame(height: 1)
        }
    }

    // MARK: Controls

    private var controls: some View {
        VStack(spacing: 14) {
            nameField
            titleField

            ControlCard(title: "Presentation", systemImage: "person.2.fill") {
                ChipRow(items: AvatarPresentation.allCases, isSelected: { $0 == avatar.presentation }) { presentation in
                    withAnimation(.snappy) { avatar.setPresentation(presentation) }
                } label: { $0.label }
            }

            ControlCard(title: "Aesthetic", systemImage: "sparkles.rectangle.stack.fill") {
                VStack(spacing: 8) {
                    ForEach(AvatarAesthetic.allCases) { aesthetic in
                        AestheticRow(aesthetic: aesthetic, selected: aesthetic == avatar.aesthetic) {
                            withAnimation(.snappy) { avatar.applyAesthetic(aesthetic) }
                        }
                    }
                }
            }

            ControlCard(title: "Body Type", systemImage: "figure.stand") {
                ChipRow(items: BodyType.options(for: avatar.presentation), isSelected: { $0 == avatar.bodyType }) { bodyType in
                    withAnimation(.snappy) { avatar.bodyType = bodyType }
                } label: { $0.label }
            }

            ControlCard(title: "Face Shape", systemImage: "face.smiling") {
                ChipRow(items: FaceShape.allCases, isSelected: { $0 == avatar.faceShape }) { shape in
                    withAnimation(.snappy) { avatar.faceShape = shape }
                } label: { $0.label }
            }

            ControlCard(title: "Hair", systemImage: "comb.fill") {
                ChipRow(items: HairStyle.options(for: avatar.presentation), isSelected: { $0 == avatar.hairStyle }) { style in
                    withAnimation(.snappy) { avatar.hairStyle = style }
                } label: { $0.label }
            }

            ControlCard(title: "Hair Color", systemImage: "paintbrush.pointed.fill") {
                HStack(spacing: 12) {
                    ForEach(HairColorPreset.allCases) { preset in
                        SwatchButton(color: preset.color.color,
                                     selected: RGBAColor(avatar.hairColor) == preset.color) {
                            withAnimation(.snappy) { avatar.hairColor = preset.color.color }
                        }
                    }
                    Spacer(minLength: 0)
                }
            }

            ControlCard(title: "Skin Tone", systemImage: "paintpalette.fill") {
                HStack(spacing: 12) {
                    ForEach(Array(SkinTone.presets.enumerated()), id: \.offset) { _, tone in
                        SwatchButton(color: tone.color,
                                     selected: RGBAColor(avatar.skinTone) == tone) {
                            withAnimation(.snappy) { avatar.skinTone = tone.color }
                        }
                    }
                    Spacer(minLength: 0)
                }
            }

            ControlCard(title: "Eye Color", systemImage: "eye.fill") {
                HStack(spacing: 12) {
                    ForEach(EyeColorPreset.allCases) { preset in
                        SwatchButton(color: preset.color.color,
                                     selected: RGBAColor(avatar.eyeColor) == preset.color) {
                            withAnimation(.snappy) { avatar.eyeColor = preset.color.color }
                        }
                    }
                    Spacer(minLength: 0)
                }
            }

            if avatar.presentation != .feminine {
                ControlCard(title: "Facial Hair", systemImage: "mustache.fill") {
                    ChipRow(items: FacialHairStyle.allCases, isSelected: { $0 == avatar.facialHair }) { style in
                        withAnimation(.snappy) { avatar.facialHair = style }
                    } label: { $0.label }
                }
            }

            ControlCard(title: "Eye Bags", systemImage: "moon.zzz.fill") {
                HStack(spacing: 12) {
                    Text("Eager").font(.caption2).foregroundStyle(.secondary)
                    Slider(value: $avatar.eyeBagsLevel, in: 0...1)
                        .tint(Color(red: 0.46, green: 0.34, blue: 0.56))
                    Text("Dead Inside").font(.caption2).foregroundStyle(.secondary)
                }
            }

            ControlCard(title: "Posture", systemImage: "figure.stand") {
                ChipRow(items: CorporatePosture.allCases, isSelected: { $0 == avatar.posture }) { posture in
                    withAnimation(.snappy) { avatar.posture = posture }
                } label: { $0.label }
            }

            ControlCard(title: "Corporate Smile", systemImage: "face.smiling.fill") {
                ChipRow(items: CorporateSmile.allCases, isSelected: { $0 == avatar.corporateSmile }) { smile in
                    withAnimation(.snappy) { avatar.corporateSmile = smile }
                } label: { $0.label }
            }

            ControlCard(title: "Starter Wardrobe", systemImage: "tshirt.fill") {
                VStack(spacing: 8) {
                    ForEach(StarterOutfit.allCases) { outfit in
                        OutfitRow(outfit: outfit, selected: outfit == avatar.starterOutfit) {
                            withAnimation(.snappy) { avatar.starterOutfit = outfit }
                        }
                    }
                }
            }
        }
    }

    private var nameField: some View {
        ControlCard(title: "Name", systemImage: "person.text.rectangle.fill") {
            TextField("Your name", text: $avatar.name)
                .focused($nameFocused)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(Color.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(red: 0.18, green: 0.10, blue: 0.24).opacity(0.08), lineWidth: 1)
                )
        }
    }

    private var titleField: some View {
        ControlCard(title: "Corporate Title", systemImage: "rosette") {
            HStack {
                Text(avatar.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.30, green: 0.40, blue: 0.62))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Spacer()
                Button {
                    withAnimation(.snappy) { avatar.rerollTitle() }
                } label: {
                    Image(systemName: "die.face.5.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            LinearGradient(colors: [
                                Color(red: 0.49, green: 0.65, blue: 0.96),
                                Color(red: 0.75, green: 0.48, blue: 0.86)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: Circle()
                        )
                        .overlay(Circle().stroke(Color.white.opacity(0.72), lineWidth: 1.5))
                        .shadow(color: Color(red: 0.30, green: 0.40, blue: 0.62).opacity(0.22), radius: 7, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var printButton: some View {
        VStack(spacing: 8) {
            Button {
                nameFocused = false
                AvatarStore.save(avatar.snapshot)
                onComplete()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.22))
                        Image(systemName: "printer.fill")
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 38, height: 38)

                    Text("Print ID Badge")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(.white.opacity(0.86))
                }
                .padding(.leading, 10)
                .padding(.trailing, 18)
                .padding(.vertical, 10)
                .background {
                    Capsule()
                        .fill(
                            LinearGradient(colors: [
                                Color(red: 0.44, green: 0.68, blue: 0.96),
                                Color(red: 0.70, green: 0.50, blue: 0.90),
                                Color(red: 0.92, green: 0.47, blue: 0.67)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    Capsule()
                        .stroke(Color.white.opacity(0.74), lineWidth: 1.2)
                        .padding(1)
                }
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(Color.white.opacity(0.28))
                        .frame(height: 18)
                        .padding(.horizontal, 18)
                        .blur(radius: 5)
                        .offset(y: 3)
                }
                .shadow(color: Color(red: 0.18, green: 0.10, blue: 0.24).opacity(0.20), radius: 12, y: 7)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
}

private struct CreatorHeroPreview: View {
    @ObservedObject var avatar: PlayerAvatar
    let compact: Bool

    var body: some View {
        HStack(spacing: compact ? 10 : 14) {
            avatarStage

            VStack(alignment: .leading, spacing: compact ? 7 : 9) {
                HStack(alignment: .center, spacing: 8) {
                    Text("BADGE STUDIO")
                        .font(.system(size: compact ? 9 : 10, weight: .black, design: .rounded))
                        .tracking(1.35)
                        .foregroundStyle(Color(red: 0.18, green: 0.10, blue: 0.24).opacity(0.62))
                    livePill
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(avatar.name.isEmpty ? "New Hire" : avatar.name)
                        .font(.system(size: compact ? 24 : 28, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.13, green: 0.08, blue: 0.18))
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                    Text(avatar.title)
                        .font(.system(size: compact ? 12 : 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 0.33, green: 0.43, blue: 0.66))
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) {
                        miniPill(avatar.presentation.label, color: avatar.aesthetic.tint.color)
                        miniPill(avatar.bodyType.label, color: Color(red: 0.98, green: 0.58, blue: 0.74))
                        miniPill(avatar.hairStyle.label, color: Color(red: 0.56, green: 0.46, blue: 0.78))
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            miniPill(avatar.presentation.label, color: avatar.aesthetic.tint.color)
                            miniPill(avatar.bodyType.label, color: Color(red: 0.98, green: 0.58, blue: 0.74))
                        }
                        miniPill(avatar.hairStyle.label, color: Color(red: 0.56, green: 0.46, blue: 0.78))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(compact ? 9 : 11)
        .frame(maxWidth: .infinity, minHeight: compact ? 142 : 166, maxHeight: compact ? 142 : 166)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(colors: [
                        Color.white.opacity(0.78),
                        Color(red: 0.91, green: 0.98, blue: 1.0).opacity(0.50),
                        Color(red: 1.0, green: 0.89, blue: 0.96).opacity(0.48)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            Capsule()
                .fill(Color.white.opacity(0.56))
                .frame(width: compact ? 126 : 160, height: compact ? 34 : 42)
                .blur(radius: 16)
                .offset(x: compact ? 84 : 116, y: compact ? -54 : -66)
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color(red: 0.54, green: 0.89, blue: 0.96).opacity(0.32))
                .frame(width: compact ? 52 : 68, height: compact ? 52 : 68)
                .blur(radius: 8)
                .offset(x: compact ? 10 : 16, y: compact ? -14 : -18)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(
                    LinearGradient(colors: [
                        Color.white.opacity(0.86),
                        Color(red: 0.18, green: 0.10, blue: 0.24).opacity(0.15)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color(red: 0.18, green: 0.10, blue: 0.24).opacity(0.11), radius: 18, y: 9)
        .allowsHitTesting(false)
    }

    private var avatarStage: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [
                Color(red: 0.84, green: 0.96, blue: 1.0),
                Color(red: 0.99, green: 0.88, blue: 0.95)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            MiniCampusBackdrop()
                .opacity(0.72)
            Capsule()
                .fill(Color(red: 0.72, green: 0.94, blue: 0.82).opacity(0.72))
                .frame(width: compact ? 82 : 102, height: compact ? 18 : 24)
                .blur(radius: 1)
                .offset(y: -6)
            AvatarView(avatar: avatar)
                .scaleEffect(compact ? 0.43 : 0.54)
                .frame(width: compact ? 90 : 112, height: compact ? 126 : 154)
                .offset(y: compact ? 12 : 14)
        }
        .frame(width: compact ? 98 : 124, height: compact ? 124 : 148)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: avatar.aesthetic.tint.color.opacity(0.28), radius: 12, y: 7)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(red: 0.18, green: 0.10, blue: 0.24).opacity(0.14), lineWidth: 1)
        )
    }

    private var livePill: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color(red: 0.26, green: 0.76, blue: 0.55))
                .frame(width: 6, height: 6)
            Text("LIVE")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.65)
        }
        .foregroundStyle(Color(red: 0.18, green: 0.10, blue: 0.24).opacity(0.66))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.64), in: Capsule())
    }

    private func miniPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color, in: Capsule())
    }
}

// MARK: - Logo-style scenic backdrop

private struct LogoCreatorBackdrop: View {
    private let snowflakes: [(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double)] = [
        (0.10, 0.16, 24, 0.34), (0.34, 0.11, 18, 0.24),
        (0.72, 0.14, 25, 0.30), (0.90, 0.23, 19, 0.22),
        (0.18, 0.54, 16, 0.20), (0.82, 0.58, 22, 0.18)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.99, blue: 1.00),
                        Color(red: 0.91, green: 0.96, blue: 0.99),
                        Color(red: 0.96, green: 0.91, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                CampusSilhouette()
                    .frame(height: min(300, proxy.size.height * 0.38))
                    .opacity(0.78)
                    .offset(y: -proxy.size.height * 0.02)

                ForEach(Array(snowflakes.enumerated()), id: \.offset) { _, flake in
                    Image(systemName: "snowflake")
                        .font(.system(size: flake.size, weight: .bold))
                        .foregroundStyle(Color(red: 0.47, green: 0.56, blue: 0.74).opacity(flake.opacity))
                        .position(x: proxy.size.width * flake.x, y: proxy.size.height * flake.y)
                }

                RibbonStroke(color: Color(red: 0.82, green: 0.54, blue: 0.94).opacity(0.22),
                             verticalOffset: proxy.size.height * 0.16)
                RibbonStroke(color: Color(red: 0.40, green: 0.75, blue: 0.94).opacity(0.22),
                             verticalOffset: proxy.size.height * 0.24)
            }
        }
    }
}

private struct CampusSilhouette: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack(alignment: .bottom) {
                building(x: w * 0.07, width: w * 0.28, height: h * 0.58,
                         canvasWidth: w,
                         fill: Color(red: 0.98, green: 0.84, blue: 0.57))
                building(x: w * 0.30, width: w * 0.30, height: h * 0.88,
                         canvasWidth: w,
                         fill: Color(red: 0.98, green: 0.64, blue: 0.74))
                building(x: w * 0.48, width: w * 0.46, height: h * 0.70,
                         canvasWidth: w,
                         fill: Color(red: 0.72, green: 0.82, blue: 0.98))
            }
            .frame(width: w, height: h)
        }
    }

    private func building(x: CGFloat, width: CGFloat, height: CGFloat, canvasWidth: CGFloat, fill: Color) -> some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(fill.opacity(0.70))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color(red: 0.30, green: 0.34, blue: 0.56).opacity(0.28), lineWidth: 4)
            )
            .overlay {
                WindowGrid()
                    .padding(14)
            }
            .offset(x: x - canvasWidth * 0.50)
    }
}

private struct WindowGrid: View {
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 7) {
            ForEach(0..<12, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(
                        LinearGradient(colors: [Color(red: 0.72, green: 0.96, blue: 0.94),
                                                Color(red: 0.86, green: 0.96, blue: 1.0)],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .frame(height: 18)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(.white.opacity(0.56), lineWidth: 1))
            }
        }
    }
}

private struct RibbonStroke: View {
    let color: Color
    let verticalOffset: CGFloat

    var body: some View {
        GeometryReader { proxy in
            Path { path in
                path.move(to: CGPoint(x: -30, y: verticalOffset))
                path.addCurve(to: CGPoint(x: proxy.size.width + 40, y: verticalOffset + 8),
                              control1: CGPoint(x: proxy.size.width * 0.25, y: verticalOffset - 70),
                              control2: CGPoint(x: proxy.size.width * 0.68, y: verticalOffset + 90))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
        }
    }
}

// MARK: - ID Badge card

private struct IDBadgeCard: View {
    @ObservedObject var avatar: PlayerAvatar

    var body: some View {
        VStack(spacing: 0) {
            // Badge header strip.
            HStack(spacing: 8) {
                Image(systemName: "building.2.crop.circle.fill")
                    .foregroundStyle(.white)
                Text("OmniTech Solutions")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text("OTS")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(red: 0.18, green: 0.10, blue: 0.24))

            HStack(spacing: 14) {
                // Avatar photo well.
                AvatarView(avatar: avatar)
                    .scaleEffect(0.62)
                    .frame(width: 124, height: 150)
                    .background(
                        ZStack {
                            LinearGradient(colors: [Color(red: 0.94, green: 0.99, blue: 1.0),
                                                    Color(red: 0.98, green: 0.90, blue: 0.96)],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                            MiniCampusBackdrop()
                                .opacity(0.54)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(red: 0.18, green: 0.10, blue: 0.24).opacity(0.18), lineWidth: 2))

                VStack(alignment: .leading, spacing: 6) {
                    Text(avatar.name.isEmpty ? "New Hire" : avatar.name)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(avatar.title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.35, green: 0.45, blue: 0.68))
                        .lineLimit(2)

                    Spacer(minLength: 4)

                    // Faux barcode.
                    HStack(spacing: 2) {
                        ForEach(0..<26, id: \.self) { i in
                            Rectangle()
                                .fill(.black.opacity(0.78))
                                .frame(width: i.isMultiple(of: 3) ? 3 : 1.5, height: 26)
                        }
                    }
                    Text("EMPLOYEE ID • \(String(format: "%05d", abs(avatar.title.hashValue) % 100000))")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(Color(red: 0.18, green: 0.10, blue: 0.24).opacity(0.12), lineWidth: 2))
        .shadow(color: Color(red: 0.18, green: 0.10, blue: 0.24).opacity(0.12), radius: 12, y: 6)
    }
}

private struct MiniCampusBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(red: 0.99, green: 0.68, blue: 0.76).opacity(0.72))
                    .frame(width: w * 0.34, height: h * 0.62)
                    .offset(x: -w * 0.28)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(red: 0.66, green: 0.82, blue: 0.98).opacity(0.80))
                    .frame(width: w * 0.54, height: h * 0.52)
                    .offset(x: w * 0.20)
                Rectangle()
                    .fill(Color(red: 0.68, green: 0.90, blue: 0.78).opacity(0.58))
                    .frame(height: h * 0.17)
            }
        }
    }
}

// MARK: - Reusable controls

private struct ControlCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(Color(red: 0.36, green: 0.50, blue: 0.72))
                    .frame(width: 24, height: 24)
                    .background(Color(red: 0.90, green: 0.96, blue: 1.0), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.86), lineWidth: 1)
                    )
                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.18, green: 0.10, blue: 0.24).opacity(0.62))
                    .tracking(0.2)
                Spacer(minLength: 0)
            }
            content
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(colors: [
                        Color.white.opacity(0.82),
                        Color(red: 0.95, green: 0.99, blue: 1.0).opacity(0.72),
                        Color(red: 1.0, green: 0.94, blue: 0.98).opacity(0.56)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(red: 0.18, green: 0.10, blue: 0.24).opacity(0.07), lineWidth: 1)
        )
        .shadow(color: Color(red: 0.18, green: 0.10, blue: 0.24).opacity(0.055), radius: 10, y: 5)
    }
}

private struct ChipRow<Item: Identifiable>: View {
    let items: [Item]
    let isSelected: (Item) -> Bool
    let action: (Item) -> Void
    let label: (Item) -> String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items) { item in
                    let on = isSelected(item)
                    Button { action(item) } label: {
                        Text(label(item))
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(on ? Color.white : Color(red: 0.16, green: 0.11, blue: 0.20))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background {
                                Capsule()
                                    .fill(
                                        on
                                        ? LinearGradient(colors: [
                                            Color(red: 0.43, green: 0.66, blue: 0.96),
                                            Color(red: 0.72, green: 0.49, blue: 0.88)
                                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [
                                            Color.white.opacity(0.92),
                                            Color(red: 0.95, green: 0.96, blue: 0.98)
                                        ], startPoint: .top, endPoint: .bottom)
                                    )
                            }
                            .overlay(
                                Capsule()
                                    .stroke(on ? Color.white.opacity(0.68) : Color(red: 0.18, green: 0.10, blue: 0.24).opacity(0.06), lineWidth: 1)
                            )
                            .shadow(color: on ? Color(red: 0.34, green: 0.45, blue: 0.76).opacity(0.18) : .clear, radius: 7, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 1)
        }
    }
}

private struct SwatchButton: View {
    let color: Color
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 36, height: 36)
                .shadow(color: color.opacity(0.26), radius: selected ? 7 : 2, y: selected ? 4 : 1)
                .overlay(Circle().stroke(.white.opacity(0.82), lineWidth: 2))
                .overlay(Circle().stroke(.black.opacity(0.10), lineWidth: 1))
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(colors: [
                                Color(red: 0.18, green: 0.10, blue: 0.24),
                                Color(red: 0.52, green: 0.68, blue: 0.94)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 3
                        )
                        .padding(-5)
                        .opacity(selected ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct OutfitRow: View {
    let outfit: StarterOutfit
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(outfit.torso.color)
                    .frame(width: 34, height: 34)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.1), lineWidth: 1))
                VStack(alignment: .leading, spacing: 2) {
                    Text(outfit.label)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(outfit.blurb)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selected ? Color(red: 0.44, green: 0.65, blue: 0.95) : .secondary.opacity(0.32))
            }
            .padding(11)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        selected
                        ? LinearGradient(colors: [
                            Color(red: 0.88, green: 0.95, blue: 1.0),
                            Color(red: 1.0, green: 0.91, blue: 0.96)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [
                            Color.white.opacity(0.76),
                            Color.white.opacity(0.48)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? Color.white.opacity(0.72) : Color(red: 0.18, green: 0.10, blue: 0.24).opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AestheticRow: View {
    let aesthetic: AvatarAesthetic
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(aesthetic.tint.color)
                    .frame(width: 34, height: 34)
                    .overlay(Circle().stroke(.black.opacity(0.10), lineWidth: 1))
                VStack(alignment: .leading, spacing: 2) {
                    Text(aesthetic.label)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(aesthetic.blurb)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selected ? Color(red: 0.44, green: 0.65, blue: 0.95) : .secondary.opacity(0.32))
            }
            .padding(11)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        selected
                        ? LinearGradient(colors: [
                            aesthetic.tint.color.opacity(0.18),
                            Color.white.opacity(0.72)
                        ], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [
                            Color.white.opacity(0.76),
                            Color.white.opacity(0.48)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? aesthetic.tint.color.opacity(0.26) : Color(red: 0.18, green: 0.10, blue: 0.24).opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CharacterCreatorView(onComplete: {})
}
