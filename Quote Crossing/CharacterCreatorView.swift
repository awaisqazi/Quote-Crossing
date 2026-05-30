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
        ZStack {
            backdrop

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 18) {
                        IDBadgeCard(avatar: avatar)
                            .padding(.top, 6)
                        controls
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 24)
                }
            }
        }
        .preferredColorScheme(.light)
        .safeAreaInset(edge: .bottom) {
            printButton
                .padding(.top, 8)
                .background(.ultraThinMaterial)
        }
        // Tap anywhere to dismiss the keyboard.
        .contentShape(Rectangle())
        .onTapGesture { nameFocused = false }
    }

    // MARK: Chrome

    private var backdrop: some View {
        LinearGradient(
            colors: [Color(red: 0.95, green: 0.96, blue: 0.99),
                     Color(red: 0.88, green: 0.91, blue: 0.98)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(spacing: 2) {
            Text("THE BADGING PROCESS")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(Color(red: 0.30, green: 0.40, blue: 0.62))
            Text("Welcome to OmniTech, new hire.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    // MARK: Controls

    private var controls: some View {
        VStack(spacing: 14) {
            nameField
            titleField

            ControlCard(title: "Hair", systemImage: "comb.fill") {
                ChipRow(items: HairStyle.allCases, isSelected: { $0 == avatar.hairStyle }) { style in
                    withAnimation(.snappy) { avatar.hairStyle = style }
                } label: { $0.label }
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

            ControlCard(title: "Eye Bags", systemImage: "moon.zzz.fill") {
                HStack(spacing: 12) {
                    Text("Eager").font(.caption2).foregroundStyle(.secondary)
                    Slider(value: $avatar.eyeBagsLevel, in: 0...1)
                        .tint(Color(red: 0.46, green: 0.34, blue: 0.56))
                    Text("Dead Inside").font(.caption2).foregroundStyle(.secondary)
                }
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

            ControlCard(title: "Accessories", systemImage: "sparkles") {
                AccessoryGrid(avatar: avatar)
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
                .background(Color(white: 0.96), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                        .background(Color(red: 0.30, green: 0.40, blue: 0.62), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var printButton: some View {
        Button {
            nameFocused = false
            AvatarStore.save(avatar.snapshot)
            onComplete()
        } label: {
            Label("Print ID Badge", systemImage: "printer.fill")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [Color(red: 0.30, green: 0.55, blue: 0.95),
                                            Color(red: 0.21, green: 0.42, blue: 0.86)],
                                   startPoint: .top, endPoint: .bottom),
                    in: Capsule()
                )
                .shadow(color: .black.opacity(0.22), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.bottom, 14)
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
            .background(Color(red: 0.20, green: 0.28, blue: 0.46))

            HStack(spacing: 14) {
                // Avatar photo well.
                AvatarView(avatar: avatar)
                    .scaleEffect(0.62)
                    .frame(width: 124, height: 150)
                    .background(
                        LinearGradient(colors: [Color(red: 0.93, green: 0.95, blue: 0.99),
                                                Color(red: 0.85, green: 0.89, blue: 0.97)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.black.opacity(0.08), lineWidth: 1))

                VStack(alignment: .leading, spacing: 6) {
                    Text(avatar.name.isEmpty ? "New Hire" : avatar.name)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(avatar.title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.30, green: 0.40, blue: 0.62))
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
            .stroke(.black.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
    }
}

// MARK: - Reusable controls

private struct ControlCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.secondary)
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(.black.opacity(0.05), lineWidth: 1))
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
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(on ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                Capsule().fill(on ? Color(red: 0.30, green: 0.55, blue: 0.95)
                                                  : Color(white: 0.94))
                            )
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
                .frame(width: 34, height: 34)
                .overlay(Circle().stroke(.black.opacity(0.12), lineWidth: 1))
                .overlay(
                    Circle()
                        .stroke(Color(red: 0.30, green: 0.55, blue: 0.95), lineWidth: 3)
                        .padding(-4)
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
                    .foregroundStyle(selected ? Color(red: 0.30, green: 0.55, blue: 0.95) : .secondary.opacity(0.4))
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? Color(red: 0.30, green: 0.55, blue: 0.95).opacity(0.08) : Color(white: 0.97))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AccessoryGrid: View {
    @ObservedObject var avatar: PlayerAvatar

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Accessory.allCases) { acc in
                let on = avatar.isEquipped(acc)
                Button {
                    withAnimation(.snappy) { avatar.toggle(acc) }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: acc.symbol)
                            .font(.system(size: 16))
                            .frame(width: 22)
                        Text(acc.label)
                            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(on ? .white : .primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(on ? Color(red: 0.22, green: 0.62, blue: 0.55) : Color(white: 0.95))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    CharacterCreatorView(onComplete: {})
}
