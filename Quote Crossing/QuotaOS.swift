//
//  QuotaOS.swift
//  Quote Crossing
//
//  Shared visual language for the polished free-app vertical slice.
//

import SwiftUI
import UIKit

enum QuotaOS {
    enum Colors {
        static let ink = Color(red: 0.045, green: 0.055, blue: 0.072)
        static let panel = Color(red: 0.105, green: 0.118, blue: 0.145)
        static let panelRaised = Color(red: 0.155, green: 0.172, blue: 0.205)
        static let paper = Color(red: 0.965, green: 0.975, blue: 0.985)
        static let porcelain = Color(red: 0.875, green: 0.930, blue: 0.955)
        static let blue = Color(red: 0.18, green: 0.42, blue: 0.88)
        static let green = Color(red: 0.12, green: 0.64, blue: 0.44)
        static let mint = Color(red: 0.20, green: 0.76, blue: 0.66)
        static let teal = Color(red: 0.10, green: 0.50, blue: 0.56)
        static let orange = Color(red: 0.88, green: 0.47, blue: 0.18)
        static let gold = Color(red: 0.94, green: 0.70, blue: 0.18)
        static let red = Color(red: 0.82, green: 0.20, blue: 0.26)
        static let purple = Color(red: 0.48, green: 0.36, blue: 0.80)
        static let pink = Color(red: 0.82, green: 0.30, blue: 0.54)
        static let slate = Color(red: 0.34, green: 0.38, blue: 0.45)
        static let glassStroke = Color.white.opacity(0.18)
        static let logoInk = Color(red: 0.18, green: 0.10, blue: 0.24)
        static let campusPaper = Color(red: 0.97, green: 0.99, blue: 1.00)
        static let campusBlue = Color(red: 0.62, green: 0.83, blue: 0.98)
        static let campusPink = Color(red: 0.96, green: 0.62, blue: 0.78)
        static let campusMint = Color(red: 0.62, green: 0.90, blue: 0.80)
        static let campusLavender = Color(red: 0.72, green: 0.66, blue: 0.94)
    }

    static let spring = Animation.spring(response: 0.36, dampingFraction: 0.78)

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

enum QuotaOSTone {
    case night
    case campus
}

struct QuotaBackdrop: View {
    var tint: Color = QuotaOS.Colors.blue
    var tone: QuotaOSTone = .night

    var body: some View {
        ZStack {
            if tone == .campus {
                campusBackdrop
            } else {
                nightBackdrop
            }
        }
        .ignoresSafeArea()
    }

    private var nightBackdrop: some View {
        ZStack {
            QuotaOS.Colors.ink
            LinearGradient(
                colors: [
                    QuotaOS.Colors.ink,
                    tint.opacity(0.18),
                    QuotaOS.Colors.panel,
                    QuotaOS.Colors.ink
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Canvas { context, size in
                let step: CGFloat = 34
                for x in stride(from: 0, through: size.width, by: step) {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(path, with: .color(.white.opacity(0.018)), lineWidth: 1)
                }
                for y in stride(from: 0, through: size.height, by: step) {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(.white.opacity(0.018)), lineWidth: 1)
                }
            }
        }
    }

    private var campusBackdrop: some View {
        ZStack {
            LinearGradient(
                colors: [
                    QuotaOS.Colors.campusPaper,
                    QuotaOS.Colors.porcelain,
                    Color(red: 0.99, green: 0.90, blue: 0.96),
                    Color(red: 0.88, green: 0.96, blue: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Canvas { context, size in
                let step: CGFloat = 38
                for y in stride(from: 78, through: size.height + 60, by: step) {
                    var line = Path()
                    line.move(to: CGPoint(x: -20, y: y))
                    line.addLine(to: CGPoint(x: size.width + 40, y: y + size.width * 0.12))
                    context.stroke(line, with: .color(QuotaOS.Colors.logoInk.opacity(0.035)), lineWidth: 1)
                }
                for x in stride(from: -size.width, through: size.width * 1.5, by: step) {
                    var line = Path()
                    line.move(to: CGPoint(x: x, y: 0))
                    line.addLine(to: CGPoint(x: x + size.height * 0.24, y: size.height))
                    context.stroke(line, with: .color(.white.opacity(0.48)), lineWidth: 1)
                }

                let ribbons: [(Color, CGFloat, CGFloat)] = [
                    (QuotaOS.Colors.campusPink.opacity(0.32), 0.18, 8),
                    (QuotaOS.Colors.campusBlue.opacity(0.26), 0.30, 7),
                    (tint.opacity(0.18), 0.58, 10)
                ]
                for (color, yFactor, width) in ribbons {
                    var ribbon = Path()
                    let y = size.height * yFactor
                    ribbon.move(to: CGPoint(x: -40, y: y))
                    ribbon.addCurve(to: CGPoint(x: size.width + 60, y: y + 16),
                                    control1: CGPoint(x: size.width * 0.22, y: y - 74),
                                    control2: CGPoint(x: size.width * 0.72, y: y + 92))
                    context.stroke(ribbon, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
                }
            }
        }
    }
}

struct QuotaHeader: View {
    let title: String
    let subtitle: String
    let tint: Color
    var tone: QuotaOSTone = .night
    var onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(tone == .campus ? QuotaOS.Colors.logoInk : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(tone == .campus ? QuotaOS.Colors.logoInk.opacity(0.62) : .white.opacity(0.66))
                    .lineLimit(2)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tone == .campus ? tint : .white)
                    .frame(width: 38, height: 38)
                    .background(tone == .campus ? Color.white.opacity(0.82) : Color.white.opacity(0.001), in: Circle())
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(tone == .campus ? QuotaOS.Colors.logoInk.opacity(0.10) : QuotaOS.Colors.glassStroke, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 28)
        .padding(.top, 18)
        .padding(.bottom, tone == .campus ? 10 : 0)
        .background {
            if tone == .campus {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.white.opacity(0.58))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(QuotaOS.Colors.logoInk.opacity(0.07), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
        }
    }
}

struct QuotaMetricPill: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color
    var tone: QuotaOSTone = .night

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tone == .campus ? tint.opacity(0.13) : .white.opacity(0.08), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title.uppercased())
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(tone == .campus ? QuotaOS.Colors.logoInk.opacity(0.46) : .white.opacity(0.48))
                    .lineLimit(1)
                Text(value)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(tone == .campus ? QuotaOS.Colors.logoInk : .white)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(tone == .campus ? Color.white.opacity(0.72) : Color.white.opacity(0.001),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(tone == .campus ? tint.opacity(0.20) : QuotaOS.Colors.glassStroke, lineWidth: 1))
    }
}

struct QuotaSurface<Content: View>: View {
    var tint: Color
    var prominence: Double = 0.26
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(
                LinearGradient(colors: [.black.opacity(0.42 + prominence * 0.35),
                                        tint.opacity(prominence),
                                        .black.opacity(0.26)],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.22), radius: 18, y: 10)
    }
}

struct QuotaProgressBar: View {
    var fraction: Double
    var tint: Color
    var tone: QuotaOSTone = .night

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(tone == .campus ? QuotaOS.Colors.logoInk.opacity(0.10) : .white.opacity(0.12))
                Capsule()
                    .fill(
                        LinearGradient(colors: tone == .campus ? [tint, QuotaOS.Colors.campusPink, QuotaOS.Colors.campusMint] : [tint, tint.opacity(0.55), .white.opacity(0.88)],
                                       startPoint: .leading,
                                       endPoint: .trailing)
                    )
                    .frame(width: max(0, min(1, fraction)) * proxy.size.width)
            }
        }
        .frame(height: 7)
    }
}

struct QuotaSectionLabel: View {
    var title: String
    var detail: String? = nil
    var tone: QuotaOSTone = .night

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(tone == .campus ? QuotaOS.Colors.logoInk.opacity(0.82) : .white.opacity(0.88))
            Spacer()
            if let detail {
                Text(detail)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(tone == .campus ? QuotaOS.Colors.logoInk.opacity(0.46) : .white.opacity(0.48))
                    .lineLimit(1)
            }
        }
    }
}

struct QuotaPrimaryButton: View {
    let title: String
    let icon: String
    let tint: Color
    var disabled = false
    var action: () -> Void

    var body: some View {
        Button {
            guard !disabled else { return }
            QuotaOS.impact(.light)
            action()
        } label: {
            Label(title, systemImage: icon)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(disabled ? .white.opacity(0.45) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    LinearGradient(colors: disabled ? [.gray.opacity(0.45), .gray.opacity(0.28)] : [tint, tint.opacity(0.68)],
                                   startPoint: .top,
                                   endPoint: .bottom),
                    in: Capsule()
                )
                .overlay(Capsule().stroke(.white.opacity(disabled ? 0.08 : 0.22), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

struct RouteBubbleButton: View {
    let route: GameRoute
    let compact: Bool
    var action: () -> Void

    var body: some View {
        Button {
            QuotaOS.impact(.light)
            action()
        } label: {
            VStack(spacing: compact ? 2 : 6) {
                Image(systemName: route.systemImage)
                    .font(.system(size: compact ? 17 : 22, weight: .semibold))
                    .foregroundStyle(compact ? route.tint : .white)
                Text(compact ? route.compactTitle : route.title)
                    .font(.system(size: compact ? 8 : 10.5, weight: .semibold, design: .rounded))
                    .lineLimit(compact ? 2 : 1)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.65)
                    .foregroundStyle(compact ? QuotaOS.Colors.logoInk.opacity(0.74) : .white)
            }
            .frame(width: compact ? 48 : 74, height: compact ? 54 : 74)
            .background(
                compact
                ? LinearGradient(colors: [Color.white.opacity(0.90), route.tint.opacity(0.12), QuotaOS.Colors.campusPink.opacity(0.10)], startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [route.tint, route.tint.opacity(0.62)], startPoint: .top, endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: compact ? 17 : 20, style: .continuous)
            )
            .background(compact ? .ultraThinMaterial : .regularMaterial,
                        in: RoundedRectangle(cornerRadius: compact ? 17 : 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: compact ? 17 : 20, style: .continuous)
                .stroke(compact ? route.tint.opacity(0.20) : .white.opacity(0.26), lineWidth: 1))
            .shadow(color: QuotaOS.Colors.logoInk.opacity(compact ? 0.10 : 0.25), radius: compact ? 5 : 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}
