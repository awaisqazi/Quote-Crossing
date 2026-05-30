//
//  QBRView.swift
//  Quote Crossing
//
//  Presents the Digital Business Card (QBR) with a live animated foil, captures
//  it at high resolution via ImageRenderer (iOS 16+), and shares it through the
//  native ShareLink (text / AirDrop / save).
//

import SwiftUI
import UIKit
import CoreTransferable
import UniformTypeIdentifiers

struct QBRView: View {
    @ObservedObject var avatar: PlayerAvatar
    var wearables: [WearableItem]
    var stats: QBRStats
    var onClose: () -> Void

    @State private var rendered: UIImage?
    @State private var cardIsSettled = false

    private let cardSize = CGSize(width: 340, height: 510)
    private var playerName: String { stats.name.isEmpty ? "New Hire" : stats.name }

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = min(310, max(292, proxy.size.width - 72))
            let cardScale = cardWidth / cardSize.width

            ZStack {
                QuotaBackdrop(tint: stats.tier.accent, tone: .campus)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        qbrHeader

                        TimelineView(.animation) { context in
                            DigitalBusinessCardView(
                                avatar: avatar,
                                wearables: wearables,
                                stats: stats,
                                foilPhase: foilPhase(context.date)
                            )
                            .frame(width: cardSize.width, height: cardSize.height)
                            .scaleEffect(cardScale)
                            .frame(width: cardWidth, height: cardSize.height * cardScale)
                            .rotation3DEffect(
                                .degrees(cardIsSettled ? 0 : -8),
                                axis: (x: 0.0, y: 1.0, z: 0.0),
                                perspective: 0.58
                            )
                            .offset(y: cardIsSettled ? 0 : 18)
                            .shadow(color: QuotaOS.Colors.logoInk.opacity(0.20), radius: 24, y: 18)
                        }
                        .padding(.top, 2)

                        shareControls
                        prestigeSummary
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, proxy.safeAreaInsets.top + 12)
                    .padding(.bottom, max(24, proxy.safeAreaInsets.bottom + 18))
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            renderCard()
            withAnimation(.spring(response: 0.58, dampingFraction: 0.78).delay(0.08)) {
                cardIsSettled = true
            }
        }
    }

    private var qbrHeader: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("QUARTERLY BRAG REPORT")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(stats.tier.accent)
                    .lineLimit(1)
                Text(playerName)
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                Text("Share your quota, badge, and friend code")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 8)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.72))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.78), in: Circle())
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(QuotaOS.Colors.logoInk.opacity(0.10), lineWidth: 1))
                    .shadow(color: QuotaOS.Colors.logoInk.opacity(0.12), radius: 10, y: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close QBR")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.68))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(QuotaOS.Colors.logoInk.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: QuotaOS.Colors.logoInk.opacity(0.10), radius: 18, y: 10)
        )
    }

    private var prestigeSummary: some View {
        HStack(spacing: 10) {
            qbrMetric(icon: "sparkles", title: "Tier", value: stats.tier.displayName, tint: stats.tier.accent)
            qbrMetric(icon: "trophy.fill", title: "Record", value: stats.record, tint: QuotaOS.Colors.gold)
            qbrMetric(icon: "person.crop.square.filled.and.at.rectangle", title: "Code", value: stats.friendString, tint: QuotaOS.Colors.purple)
        }
        .padding(.horizontal, 3)
    }

    private func qbrMetric(icon: String, title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.14), in: Circle())
            Text(title.uppercased())
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.44))
                .lineLimit(1)
            Text(value)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(QuotaOS.Colors.logoInk)
                .lineLimit(1)
                .minimumScaleFactor(0.58)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.70), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }

    @ViewBuilder private var shareControls: some View {
        if let image = rendered {
            ShareLink(
                item: QBRCardImage(image: image, playerName: stats.name),
                preview: SharePreview("\(playerName) - Quarterly Brag Report",
                                      image: Image(uiImage: image))
            ) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 17, weight: .black))
                    Text("Share QBR Card")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .black))
                        .opacity(0.72)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(maxWidth: cardSize.width)
                .frame(height: 60)
                .background(
                    LinearGradient(colors: [
                        QuotaOS.Colors.blue,
                        stats.tier.accent,
                        QuotaOS.Colors.campusPink
                    ], startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.34), lineWidth: 1)
                )
                .shadow(color: stats.tier.accent.opacity(0.32), radius: 18, y: 10)
            }
        } else {
            ProgressView()
                .tint(stats.tier.accent)
                .frame(width: cardSize.width, height: 60)
                .background(Color.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    /// 4-second foil loop, phase in 0...1.
    private func foilPhase(_ date: Date) -> Double {
        (date.timeIntervalSinceReferenceDate / 4).truncatingRemainder(dividingBy: 1)
    }

    /// Renders the card to a high-resolution UIImage (deterministic foil phase).
    @MainActor private func renderCard() {
        let card = DigitalBusinessCardView(
            avatar: avatar, wearables: wearables, stats: stats, foilPhase: 0.25
        )
        .frame(width: cardSize.width, height: cardSize.height)

        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        renderer.isOpaque = false
        rendered = renderer.uiImage
    }
}

/// Transferable wrapper so ShareLink exports the full-resolution PNG.
struct QBRCardImage: Transferable {
    let image: UIImage
    let playerName: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { card in
            card.image.pngData() ?? Data()
        }
    }
}
