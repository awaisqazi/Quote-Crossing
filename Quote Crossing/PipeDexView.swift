//
//  PipeDexView.swift
//  Quote Crossing
//
//  A beautiful, premium CRM Merge-2 pipeline mini-game view (GDD §5.2).
//  Optimized for one-handed portrait play. Keeps generators and actions in the bottom thumb zone.
//  Uses custom DragGesture for bouncy 60fps spring card drag-and-drop merging and hovering.
//

import SwiftUI
import Combine

struct PipeDexView: View {
    @ObservedObject var viewModel: PipeDexViewModel
    var gameState: GameState
    @ObservedObject var inventory: InventoryManager
    var onClose: () -> Void
    
    // Grid cells layout coordinates tracking
    @State private var cellFrames: [Int: CGRect] = [:]
    
    // UI Layout constraints
    private let columnsCount = 7
    private let gridSpacing: CGFloat = 8
    
    // Bouncy animation state for dialogs
    @State private var showOutofBandwidthAlert = false
    @State private var justEarnedCash: Int? = nil
    @State private var showSuccessBanner = false
    @State private var bannerText = ""
    @State private var shakingIndex: Int? = nil
    
    // Slow passive stamina recharge ticker
    private let bandwidthRegenTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    init(viewModel: PipeDexViewModel, gameState: GameState, inventory: InventoryManager, onClose: @escaping () -> Void) {
        self.viewModel = viewModel
        self.gameState = gameState
        self.inventory = inventory
        self.onClose = onClose
    }
    
    public var body: some View {
        ZStack {
            QuotaBackdrop(tint: QuotaOS.Colors.blue, tone: .campus)
            
            VStack(spacing: 0) {
                // MARK: - Premium Glassmorphic Header
                headerView
                    .padding(.horizontal, 28)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                
                // MARK: - Active CRM Pipeline Info Bar
                pipelineSummaryView
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                // MARK: - 7x9 Merge Grid
                GeometryReader { gridGeo in
                    let cellWidth = (gridGeo.size.width - CGFloat(columnsCount - 1) * gridSpacing) / CGFloat(columnsCount)
                    let cellSize = CGSize(width: cellWidth, height: cellWidth) // Square cells
                    
                    VStack {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: gridSpacing), count: columnsCount),
                            spacing: gridSpacing
                        ) {
                            ForEach(0..<63) { index in
                                gridCell(index: index, cellSize: cellSize)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .padding(.horizontal, 16)
                .zIndex(5)
                
                Spacer()
                
                // MARK: - Bottom Thumb Zone Dashboard
                VStack(spacing: 12) {
                    leadInspectorPanel
                    
                    generatorActionsRow
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.86))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(QuotaOS.Colors.logoInk.opacity(0.10), lineWidth: 1)
                        )
                        .shadow(color: QuotaOS.Colors.logoInk.opacity(0.12), radius: 14, y: -6)
                )
                .zIndex(8)
            }
            
            // MARK: - Bouncy Custom Drag Card Overlay
            if let draggedIndex = viewModel.activeDraggedIndex,
               let lead = viewModel.grid[draggedIndex],
               let frame = cellFrames[draggedIndex] {
                
                let cellSize = frame.size
                
                LeadCardView(lead: lead, size: cellSize)
                    .scaleEffect(1.18)
                    .rotationEffect(.degrees(5))
                    .shadow(color: QuotaOS.Colors.logoInk.opacity(0.24), radius: 12, y: 10)
                    .position(
                        x: frame.midX + viewModel.dragOffset.width,
                        y: frame.midY + viewModel.dragOffset.height
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .zIndex(100)
            }
            
            // MARK: - Bouncy Notifications & Banner Overlays
            if showSuccessBanner {
                successBannerOverlay
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(150)
            }
            
            if showOutofBandwidthAlert {
                bandwidthAlertOverlay
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    .zIndex(160)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(QuotaBackdrop(tint: QuotaOS.Colors.blue, tone: .campus))
        .statusBarHidden()
        .onReceive(bandwidthRegenTimer) { _ in
            if gameState.bandwidth < gameState.maxBandwidth {
                withAnimation(.easeInOut(duration: 0.3)) {
                    gameState.bandwidth = min(gameState.maxBandwidth, gameState.bandwidth + 1)
                }
            }
        }
        .onPreferenceChange(CellFramePreferenceKey.self) { frames in
            self.cellFrames = frames
        }
    }
    
    // MARK: - Header Component
    
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("PIPE-DEX CRM v3.0")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(QuotaOS.Colors.blue)
                
                Text("Casual Lead Farming")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk)
            }
            
            Spacer()
            
            // Close Button
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    onClose()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.74))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.82), in: Circle())
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(QuotaOS.Colors.logoInk.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Pipeline Info Bar
    
    private var pipelineSummaryView: some View {
        HStack(spacing: 12) {
            // Live Stats: Bandwidth stamina pill
            HStack(spacing: 8) {
                Image(systemName: "wifi")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                Text("\(gameState.bandwidth)/\(gameState.maxBandwidth)")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(LinearGradient(colors: [Color(red: 0.28, green: 0.52, blue: 0.92), Color(red: 0.18, green: 0.38, blue: 0.80)], startPoint: .top, endPoint: .bottom))
                    .overlay(Capsule().strokeBorder(.white.opacity(0.2), lineWidth: 1))
            )
            
            // Live Stats: Commish-Cash pill
            HStack(spacing: 6) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Text(gameState.commishCash.formatted(.number.grouping(.automatic)))
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(LinearGradient(colors: [Color(red: 0.18, green: 0.72, blue: 0.48), Color(red: 0.10, green: 0.58, blue: 0.38)], startPoint: .top, endPoint: .bottom))
                    .overlay(Capsule().strokeBorder(.white.opacity(0.2), lineWidth: 1))
            )
            
            Spacer()
            
            // Leads count
            Text("\(viewModel.filledCount)/63 Slots")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.60))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.76))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(QuotaOS.Colors.logoInk.opacity(0.08), lineWidth: 1))
        )
    }
    
    // MARK: - Grid Cell Layout
    
    private func gridCell(index: Int, cellSize: CGSize) -> some View {
        let isHovered = isHoveredTarget(index: index)
        let leadItem = viewModel.grid[index]
        let isShaking = shakingIndex == index
        
        return ZStack {
            if let lead = leadItem {
                // Populating actual Lead Card
                LeadCardView(lead: lead, size: cellSize)
                    .opacity(viewModel.activeDraggedIndex == index ? 0.35 : 1.0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.yellow, lineWidth: viewModel.selectedIndex == index ? 2.5 : 0)
                    )
                    .scaleEffect(isHovered ? 1.15 : (viewModel.selectedIndex == index ? 1.05 : 1.0))
                    .offset(x: isShaking ? CGFloat.random(in: -3...3) : 0, y: isShaking ? CGFloat.random(in: -3...3) : 0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isHovered)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            if lead.isWeed {
                                triggerWeedShake(index: index)
                                viewModel.tapWeed(at: index)
                            } else {
                                viewModel.selectedIndex = index
                            }
                        }
                    }
                    // Bouncy drag setup
                    .gesture(
                        DragGesture(coordinateSpace: .global)
                            .onChanged { gesture in
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                    if viewModel.activeDraggedIndex == nil {
                                        viewModel.handleDragStarted(at: index)
                                    }
                                    viewModel.dragOffset = gesture.translation
                                    viewModel.dragLocation = gesture.location
                                }
                            }
                            .onEnded { gesture in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    let finalLoc = gesture.location
                                    let targetCell = cellFrames.first(where: { $0.value.contains(finalLoc) })?.key
                                    viewModel.handleDragEnded(targetIndex: targetCell)
                                }
                            }
                    )
            } else {
                // Render Empty Slot Grid Slot
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.72),
                                QuotaOS.Colors.campusBlue.opacity(0.24),
                                QuotaOS.Colors.campusMint.opacity(0.14)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isHovered ? QuotaOS.Colors.green.opacity(0.62) : QuotaOS.Colors.logoInk.opacity(0.10),
                                style: StrokeStyle(lineWidth: isHovered ? 2.5 : 1.5, lineCap: .round, dash: isHovered ? [] : [4, 4])
                            )
                    )
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isHovered)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            viewModel.selectedIndex = nil
                        }
                    }
            }
        }
        .frame(width: cellSize.width, height: cellSize.height)
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: CellFramePreferenceKey.self, value: [index: geo.frame(in: .global)])
            }
        )
    }
    
    private func isHoveredTarget(index: Int) -> Bool {
        guard let dragIdx = viewModel.activeDraggedIndex, dragIdx != index else { return false }
        guard let frame = cellFrames[index] else { return false }
        return frame.contains(viewModel.dragLocation)
    }
    
    private func triggerWeedShake(index: Int) {
        withAnimation(.linear(duration: 0.05).repeatCount(4, autoreverses: true)) {
            shakingIndex = index
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            shakingIndex = nil
        }
    }
    
    // MARK: - Selected Lead Inspector Panel
    
    private var leadInspectorPanel: some View {
        VStack(spacing: 8) {
            if let index = viewModel.selectedIndex, let lead = viewModel.grid[index] {
                if lead.isWeed {
                    // Weed description
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color(red: 0.85, green: 0.40, blue: 0.30))
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Closed-Lost Weed")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(QuotaOS.Colors.logoInk)
                            
                            Text(lead.weedDescription)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.58))
                                .lineLimit(3)
                        }
                    }
                    .padding(14)
                } else {
                    // Valid Lead Panel
                    HStack(alignment: .center, spacing: 14) {
                        // Level Icon
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                colors: [lead.colors.top, lead.colors.bottom],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.2), lineWidth: 1.5))
                            .frame(width: 52, height: 52)
                            .overlay(
                                Image(systemName: lead.iconName)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1.5)
                            )
                        
                        // Detail Texts
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(lead.name)
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .foregroundStyle(QuotaOS.Colors.logoInk)
                                
                                Text("L\(lead.level)")
                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                    .foregroundStyle(QuotaOS.Colors.logoInk)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(QuotaOS.Colors.logoInk.opacity(0.08), in: Capsule())
                            }
                            
                            HStack(spacing: 3) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(red: 0.18, green: 0.72, blue: 0.48))
                                Text("Commission Payout: ")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.52))
                                Text("+\(lead.yield)")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(Color(red: 0.18, green: 0.72, blue: 0.48))
                            }
                            
                            // Decay bar
                            if lead.level < 10 {
                                let elapsed = Date().timeIntervalSince(lead.lastInteractedAt)
                                let remaining = max(0, lead.decayDuration - elapsed)
                                let progress = remaining / lead.decayDuration
                                
                                HStack(spacing: 8) {
                                    Text("Freshness:")
                                        .font(.system(size: 9, weight: .heavy))
                                        .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.46))
                                    
                                    GeometryReader { barGeo in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(QuotaOS.Colors.logoInk.opacity(0.10))
                                            Capsule()
                                                .fill(progress > 0.5 ? Color.green : (progress > 0.2 ? Color.orange : Color.red))
                                                .frame(width: barGeo.size.width * progress)
                                        }
                                    }
                                    .frame(height: 5)
                                    
                                    Text("\(Int(remaining))s")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.52))
                                        .monospacedDigit()
                                }
                                .frame(height: 12)
                            } else {
                                Text("👑 Enterprise Deal - Permanent asset, does not rot!")
                                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color(red: 0.98, green: 0.82, blue: 0.30))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 8)
                    
                    Divider().background(QuotaOS.Colors.logoInk.opacity(0.08))
                    
                    // Interaction Buttons: Follow Up / Claim
                    HStack(spacing: 12) {
                        // Follow up button
                        Button(action: {
                            if viewModel.followUpOnLead(state: gameState, at: index) {
                                showNotification(text: "Nurtured! Decay reset.")
                            } else {
                                showOutofBandwidthAlert = true
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise.heart.fill")
                                Text("NURTURE")
                            }
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(
                                LinearGradient(colors: [Color(red: 0.55, green: 0.42, blue: 0.92), Color(red: 0.40, green: 0.30, blue: 0.78)], startPoint: .top, endPoint: .bottom),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(.white.opacity(0.2), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .disabled(lead.level == 10) // level 10 doesn't rot, so no nurture needed
                        .opacity(lead.level == 10 ? 0.35 : 1.0)
                        
                        // Close deal button
                        Button(action: {
                            let reward = lead.yield
                            if let _ = viewModel.closeSelectedDeal(state: gameState) {
                                justEarnedCash = reward
                                bannerText = "Deal Signed! Earned +$\(reward)!"
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showSuccessBanner = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        showSuccessBanner = false
                                        justEarnedCash = nil
                                    }
                                }
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "signature")
                                Text("CLOSE DEAL")
                            }
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(
                                LinearGradient(colors: [Color(red: 0.18, green: 0.72, blue: 0.48), Color(red: 0.10, green: 0.58, blue: 0.38)], startPoint: .top, endPoint: .bottom),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(.white.opacity(0.2), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 6)
                    .padding(.horizontal, 4)
                }
            } else {
                // Placeholder inspector
                VStack(spacing: 8) {
                    Image(systemName: "funnel.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(QuotaOS.Colors.blue.opacity(0.22))
                        .padding(.top, 8)
                    
                    Text("PIPELINE INSPECTOR")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.44))
                    
                    Text("Select a card in the grid above to close contracts, nurture prospects, or check decay timelines.")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.52))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity, minHeight: 90)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.70))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(QuotaOS.Colors.logoInk.opacity(0.08), lineWidth: 1.2))
        )
    }
    
    // MARK: - Bottom Primary Action Generators Row
    
    private var generatorActionsRow: some View {
        HStack(spacing: 12) {
            // SPAM EMAIL DIALER
            Button(action: {
                if viewModel.triggerSpamEmailDialer(state: gameState) {
                    showNotification(text: "Level 1 Lead Generated!")
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        showOutofBandwidthAlert = true
                    }
                }
            }) {
                VStack(spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14))
                        Text("Spam Email")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    Text("Costs \(viewModel.spamDialerCost) Bandwidth")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.72))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.18, green: 0.52, blue: 0.92), Color(red: 0.12, green: 0.38, blue: 0.78)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.25), lineWidth: 1.5))
                .shadow(color: Color(red: 0.12, green: 0.38, blue: 0.78).opacity(0.3), radius: 6, y: 3)
            }
            .buttonStyle(BouncyButtonStyle())
            
            // AUTOMATED LEAD DIALER
            let isOnCooldown = viewModel.automatedDialerRemainingCooldown > 0
            
            Button(action: {
                if viewModel.triggerAutomatedLeadDialer() {
                    showNotification(text: "Auto-Dialer Lead Generated!")
                }
            }) {
                VStack(spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: isOnCooldown ? "timer" : "phone.bubble.left.fill")
                            .font(.system(size: 14))
                        Text(isOnCooldown ? cooldownString : "Auto Dialer")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    Text(isOnCooldown ? "On Cooldown" : "Instant Spawn (Free)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isOnCooldown ? QuotaOS.Colors.logoInk.opacity(0.42) : Color.white.opacity(0.78))
                }
                .foregroundStyle(isOnCooldown ? QuotaOS.Colors.logoInk.opacity(0.50) : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    isOnCooldown ?
                    LinearGradient(colors: [Color.white.opacity(0.72), QuotaOS.Colors.logoInk.opacity(0.10)], startPoint: .top, endPoint: .bottom) :
                    LinearGradient(colors: [QuotaOS.Colors.purple, QuotaOS.Colors.campusLavender], startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(isOnCooldown ? QuotaOS.Colors.logoInk.opacity(0.10) : Color.white.opacity(0.28), lineWidth: 1.5)
                )
                .shadow(color: QuotaOS.Colors.purple.opacity(isOnCooldown ? 0 : 0.20), radius: 6, y: 3)
            }
            .buttonStyle(BouncyButtonStyle())
            .disabled(isOnCooldown)
        }
    }
    
    private var cooldownString: String {
        let mins = Int(viewModel.automatedDialerRemainingCooldown) / 60
        let secs = Int(viewModel.automatedDialerRemainingCooldown) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func showNotification(text: String) {
        bannerText = text
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showSuccessBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                if bannerText == text { // Ensure we don't clear a newer banner
                    showSuccessBanner = false
                }
            }
        }
    }
    
    // MARK: - Banner & Alert Overlays
    
    private var successBannerOverlay: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(red: 0.18, green: 0.72, blue: 0.48))
                
                Text(bannerText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.88))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(QuotaOS.Colors.logoInk.opacity(0.10), lineWidth: 1.5))
                    .shadow(color: QuotaOS.Colors.logoInk.opacity(0.14), radius: 10, y: 6)
            )
            .padding(.horizontal, 20)
            .padding(.top, 24)
            Spacer()
        }
    }
    
    private var bandwidthAlertOverlay: some View {
        ZStack {
            QuotaOS.Colors.logoInk.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showOutofBandwidthAlert = false
                    }
                }
            
            VStack(spacing: 20) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 46, weight: .black))
                    .foregroundStyle(Color(red: 0.85, green: 0.30, blue: 0.35))
                    .padding(.top, 10)
                
                VStack(spacing: 8) {
                    Text("OUT OF BANDWIDTH!")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(QuotaOS.Colors.logoInk)
                    
                    Text("You don't have the mental stamina for cold dialing! Wait for passive recharge (+1 per 3 seconds) or use the free Automated Dialer.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.62))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showOutofBandwidthAlert = false
                    }
                }) {
                    Text("GET BACK TO GRINDING")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            LinearGradient(colors: [Color(red: 0.28, green: 0.52, blue: 0.92), Color(red: 0.18, green: 0.38, blue: 0.80)], startPoint: .top, endPoint: .bottom),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.white.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.92))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(QuotaOS.Colors.logoInk.opacity(0.12), lineWidth: 2))
                    .shadow(color: QuotaOS.Colors.logoInk.opacity(0.20), radius: 20, y: 12)
            )
            .frame(width: 320)
        }
    }
}

// MARK: - Individual Card View Component

struct LeadCardView: View {
    let lead: LeadItem
    let size: CGSize
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(LinearGradient(
                colors: [lead.colors.top, lead.colors.bottom],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(.white.opacity(lead.isWeed ? 0.1 : 0.3), lineWidth: 1.5)
            )
            .overlay(
                Image(systemName: lead.iconName)
                    .font(.system(size: size.width * 0.44, weight: .bold))
                    .foregroundStyle(lead.isWeed ? Color(red: 0.18, green: 0.14, blue: 0.12) : .white)
                    .shadow(color: .black.opacity(lead.isWeed ? 0.0 : 0.25), radius: 2, y: 1.5)
            )
            // Level indicators
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if !lead.isWeed {
                            Text("L\(lead.level)")
                                .font(.system(size: size.width * 0.21, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 3)
                                .padding(.vertical, 1)
                                .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 4))
                                .padding(3)
                        } else {
                            // Taps badge for weed
                            Text("\(lead.weedTapsRemaining)")
                                .font(.system(size: size.width * 0.21, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(3)
                                .background(Color(red: 0.8, green: 0.2, blue: 0.2), in: Circle())
                                .padding(3)
                        }
                    }
                }
            )
            .shadow(color: .black.opacity(0.2), radius: 3, y: 2.5)
    }
}

// MARK: - SwiftUI Helper Layout Preference Key

struct CellFramePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Interactive Button Animations

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
