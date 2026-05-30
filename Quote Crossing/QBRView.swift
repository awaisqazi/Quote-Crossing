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

    private let cardSize = CGSize(width: 320, height: 470)

    var body: some View {
        ZStack {
            Color.black.opacity(0.64)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 22) {
                // Live, animated card (foil sheen sweeps continuously).
                TimelineView(.animation) { context in
                    DigitalBusinessCardView(
                        avatar: avatar, wearables: wearables, stats: stats,
                        foilPhase: foilPhase(context.date)
                    )
                    .frame(width: cardSize.width, height: cardSize.height)
                }
                .shadow(color: .black.opacity(0.45), radius: 22, y: 12)

                shareControls
            }
            .padding()

            // Close button.
            VStack {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(.white.opacity(0.18), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(20)
        }
        .onAppear(perform: renderCard)
    }

    @ViewBuilder private var shareControls: some View {
        if let image = rendered {
            ShareLink(
                item: QBRCardImage(image: image, playerName: stats.name),
                preview: SharePreview("\(stats.name) — Quarterly Brag Report",
                                      image: Image(uiImage: image))
            ) {
                Label("Share My QBR", systemImage: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: cardSize.width)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(colors: [Color(red: 0.30, green: 0.55, blue: 0.95),
                                                Color(red: 0.21, green: 0.42, blue: 0.86)],
                                       startPoint: .top, endPoint: .bottom),
                        in: Capsule()
                    )
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            }
        } else {
            ProgressView()
                .tint(.white)
                .frame(width: cardSize.width, height: 54)
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
        renderer.scale = 3              // ~960×1410 px export
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
