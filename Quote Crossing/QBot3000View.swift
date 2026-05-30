//
//  QBot3000View.swift
//  Quote Crossing
//
//  A beautiful, premium Quote Configuration Terminal view (GDD §5.3).
//  Implements spatial inventory Tetris drag-and-snap placement on a 6x6 grid.
//  Optimized for portrait play with stats and component trays in the lower thumb zone.
//  Uses a sweeping diagnostic laser scan animation for compiling quotes.
//

import SwiftUI
import Combine

struct QBot3000View: View {
    @ObservedObject var viewModel: QBotViewModel
    var gameState: GameState
    var onClose: () -> Void
    
    // Grid cells layout coordinates tracking
    @State private var cellFrames: [Int: CGRect] = [:]
    
    // UI Layout constraints
    private let gridSize = 6
    private let cellSpacing: CGFloat = 6
    
    // Alert and modal animation states
    @State private var compiledWeapon: ContractWeapon? = nil
    @State private var showSuccessModal = false
    @State private var isTrayShaking = false
    @State private var showInstructionsModal = false
    
    var body: some View {
        ZStack {
            QuotaBackdrop(tint: QuotaOS.Colors.orange, tone: .campus)
            cyberGridPattern
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Glassmorphic Header
                headerView
                    .padding(.horizontal, 28)
                    .padding(.top, 12)
                    .padding(.bottom, 14)
                
                // MARK: - Real-time Margin & Stats Scoreboard
                marginScoreboardHeader
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                // MARK: - 6x6 Spatial puzzle board
                ZStack {
                    GeometryReader { boardGeo in
                        let boardWidth = boardGeo.size.width
                        let cellWidth = (boardWidth - CGFloat(gridSize - 1) * cellSpacing) / CGFloat(gridSize)
                        let cellSize = CGSize(width: cellWidth, height: cellWidth)
                        
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<gridSize, id: \.self) { y in
                                HStack(spacing: cellSpacing) {
                                    ForEach(0..<gridSize, id: \.self) { x in
                                        gridCell(x: x, y: y, cellSize: cellSize)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        
                        // MARK: - Ghost Placement Footprint Preview
                        if let dragged = viewModel.activeDraggedComponent {
                            let dragLocation = viewModel.dragLocation
                            if let hoverCell = findCellCoordinates(at: dragLocation) {
                                let anchor = calculateAnchorCell(hoverX: hoverCell.x, hoverY: hoverCell.y, w: dragged.width, h: dragged.height)
                                let isValid = viewModel.canPlace(component: dragged, atX: anchor.x, atY: anchor.y, ignoringId: dragged.id)
                                
                                // Draw ghost footprints
                                let ghostX = CGFloat(anchor.x) * (cellWidth + cellSpacing)
                                let ghostY = CGFloat(anchor.y) * (cellWidth + cellSpacing)
                                let ghostW = CGFloat(dragged.width) * cellWidth + CGFloat(dragged.width - 1) * cellSpacing
                                let ghostH = CGFloat(dragged.height) * cellWidth + CGFloat(dragged.height - 1) * cellSpacing
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isValid ? Color.green.opacity(0.18) : Color.red.opacity(0.18))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isValid ? Color.green : Color.red, lineWidth: 2)
                                    )
                                    .frame(width: ghostW, height: ghostH)
                                    .position(x: ghostX + ghostW / 2, y: ghostY + ghostH / 2)
                                    .animation(.spring(response: 0.15, dampingFraction: 0.8), value: anchor.x * 10 + anchor.y)
                                    .allowsHitTesting(false)
                            }
                        }
                        
                        // MARK: - Render Grid Placed Component Block cards
                        ForEach(viewModel.placedComponents) { comp in
                            if let px = comp.gridX, let py = comp.gridY, viewModel.activeDraggedComponent?.id != comp.id {
                                let blockX = CGFloat(px) * (cellWidth + cellSpacing)
                                let blockY = CGFloat(py) * (cellWidth + cellSpacing)
                                let blockW = CGFloat(comp.width) * cellWidth + CGFloat(comp.width - 1) * cellSpacing
                                let blockH = CGFloat(comp.height) * cellWidth + CGFloat(comp.height - 1) * cellSpacing
                                
                                SKUBlockView(component: comp, size: CGSize(width: blockW, height: blockH))
                                    .position(x: blockX + blockW / 2, y: blockY + blockH / 2)
                                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                                    // Bouncy drag setup
                                    .gesture(
                                        DragGesture(coordinateSpace: .global)
                                            .onChanged { gesture in
                                                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                                    if viewModel.activeDraggedComponent == nil {
                                                        viewModel.handleDragStarted(comp)
                                                    }
                                                    viewModel.dragOffset = gesture.translation
                                                    viewModel.dragLocation = gesture.location
                                                }
                                            }
                                            .onEnded { gesture in
                                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                                    let finalLoc = gesture.location
                                                    let targetCoord = findCellCoordinates(at: finalLoc)
                                                    if let target = targetCoord {
                                                        let anchor = calculateAnchorCell(hoverX: target.x, hoverY: target.y, w: comp.width, h: comp.height)
                                                        viewModel.handleDragEnded(targetCell: (anchor.x, anchor.y))
                                                    } else {
                                                        viewModel.handleDragEnded(targetCell: nil)
                                                    }
                                                }
                                            }
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            let rotated = viewModel.rotateComponent(comp)
                                            if !rotated {
                                                // Shake or bounce to indicate failure
                                                isTrayShaking = true
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    isTrayShaking = false
                                                }
                                            }
                                        }
                                    }
                            }
                        }
                        
                        // MARK: - Dynamic Laser Scanning Animation Overlay
                        if viewModel.isCompiling {
                            let scanY = boardGeo.size.height * CGFloat(viewModel.compilationProgress)
                            
                            ZStack {
                                // Diagnostic laser glowing bar
                                LinearGradient(colors: [.clear, Color.cyan.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom)
                                    .frame(height: 32)
                                
                                Rectangle()
                                    .fill(Color.cyan)
                                    .frame(height: 2.5)
                                    .shadow(color: .cyan, radius: 8, y: 0)
                            }
                            .frame(width: boardWidth)
                            .position(x: boardWidth / 2, y: scanY)
                            .allowsHitTesting(false)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: UIScreen.main.bounds.width - 32)
                .zIndex(5)
                
                Spacer()
                
                // MARK: - Lower Thumb Zone Actions Tray & Scoreboard lists
                VStack(spacing: 12) {
                    marginDetailsDashboard
                    
                    unplacedInventoryTray
                    
                    compileActionButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.84))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(QuotaOS.Colors.logoInk.opacity(0.10), lineWidth: 1)
                        )
                        .shadow(color: QuotaOS.Colors.logoInk.opacity(0.12), radius: 14, y: -6)
                )
                .zIndex(8)
            }
            
            // MARK: - Custom Drag Component Visual Overlay
            if let dragged = viewModel.activeDraggedComponent,
               let frame = cellFrames[dragged.gridX != nil ? (dragged.gridY! * gridSize + dragged.gridX!) : 0] {
                
                let cellWidth = frame.size.width
                let blockW = CGFloat(dragged.width) * cellWidth + CGFloat(dragged.width - 1) * cellSpacing
                let blockH = CGFloat(dragged.height) * cellWidth + CGFloat(dragged.height - 1) * cellSpacing
                
                SKUBlockView(component: dragged, size: CGSize(width: blockW, height: blockH))
                    .scaleEffect(1.1)
                    .shadow(color: QuotaOS.Colors.logoInk.opacity(0.24), radius: 12, y: 10)
                    .position(viewModel.dragLocation)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .zIndex(100)
            }
            
            // MARK: - Q-Bot Compilation Success Modal Dialog
            if showSuccessModal, let weapon = compiledWeapon {
                successWeaponModal(weapon: weapon)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    .zIndex(150)
            }
            
            // MARK: - Q-Bot Instructions / Help Overlay Modal
            if showInstructionsModal {
                instructionsOverlayModal
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    .zIndex(160)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(QuotaBackdrop(tint: QuotaOS.Colors.orange, tone: .campus))
        .onPreferenceChange(CellFramePreferenceKey.self) { frames in
            cellFrames = frames
        }
        .statusBarHidden()
    }
    
    // MARK: - Header Component
    
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Q-BOT 3000 CONFIGURATOR")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(QuotaOS.Colors.orange)
                
                Text("B2B Spatial Quote puzzle")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(QuotaOS.Colors.logoInk)
            }
            
            Spacer()
            
            // Help / Instructions Button
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    showInstructionsModal = true
                }
            }) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(QuotaOS.Colors.orange)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.82), in: Circle())
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(QuotaOS.Colors.logoInk.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 4)

            // Info / Reset Button
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    viewModel.resetTray()
                }
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.74))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.82), in: Circle())
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(QuotaOS.Colors.logoInk.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 4)
            
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
    
    // MARK: - Cyber Grid Background
    
    private var cyberGridPattern: some View {
        Canvas { context, size in
            let cols = 15
            let rows = 25
            let dx = size.width / CGFloat(cols)
            let dy = size.height / CGFloat(rows)
            
            for y in 0...rows {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: CGFloat(y) * dy))
                path.addLine(to: CGPoint(x: size.width, y: CGFloat(y) * dy))
                context.stroke(path, with: .color(QuotaOS.Colors.logoInk.opacity(0.030)), lineWidth: 1)
            }
            for x in 0...cols {
                var path = Path()
                path.move(to: CGPoint(x: CGFloat(x) * dx, y: 0))
                path.addLine(to: CGPoint(x: CGFloat(x) * dx, y: size.height))
                context.stroke(path, with: .color(Color.white.opacity(0.56)), lineWidth: 1)
            }
        }
    }
    
    // MARK: - Scoreboard metrics
    
    private var marginScoreboardHeader: some View {
        let details = viewModel.calculateMarginDetails()
        
        return HStack(spacing: 12) {
            // Live Stats: Margin Value pill
            VStack(alignment: .leading, spacing: 2) {
                Text("QUOTE Q-MARGIN")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.52))
                
                HStack(spacing: 3) {
                    Text("$")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(Color(red: 0.18, green: 0.72, blue: 0.48))
                    Text("\(details.qMargin)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(QuotaOS.Colors.logoInk)
                        .monospacedDigit()
                }
            }
            
            Spacer()
            
            // Occupancy Status
            VStack(alignment: .trailing, spacing: 4) {
                Text("GRID STATUS")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.52))
                
                Text("\(36 - details.emptyCellsCount)/36 Cells Snapped")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(details.emptyCellsCount == 0 ? Color.green : QuotaOS.Colors.logoInk.opacity(0.76))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.76))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(QuotaOS.Colors.logoInk.opacity(0.08), lineWidth: 1))
        )
    }
    
    // MARK: - 6x6 Snap Cells grid
    
    private func gridCell(x: Int, y: Int, cellSize: CGSize) -> some View {
        let cellIndex = y * gridSize + x
        
        return RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.78),
                        QuotaOS.Colors.campusBlue.opacity(0.22),
                        QuotaOS.Colors.campusLavender.opacity(0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(QuotaOS.Colors.logoInk.opacity(0.08), lineWidth: 1.2)
            )
            .frame(width: cellSize.width, height: cellSize.height)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: CellFramePreferenceKey.self, value: [cellIndex: geo.frame(in: .global)])
                }
            )
    }
    
    // MARK: - Adjacency Margin list detail panels
    
    private var marginDetailsDashboard: some View {
        let details = viewModel.calculateMarginDetails()
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("COMPATIBILITY SCOREBOARD")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.46))
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if details.synergiesList.isEmpty && details.penaltiesList.filter({ !$0.contains("Empty") }).isEmpty {
                        // Empty/Neutral indicator
                        HStack(spacing: 6) {
                            Image(systemName: "square.dashed")
                                .font(.system(size: 11))
                            Text("No adjacent synergies active. Snap blocks adjacent to link!")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.48))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(QuotaOS.Colors.logoInk.opacity(0.05), in: Capsule())
                    }
                    
                    // Show Synergies
                    ForEach(details.synergiesList, id: \.self) { syn in
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                            Text(syn)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(Color.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1), in: Capsule())
                    }
                    
                    // Show Penalties (ignoring generic empty space listings for compactness)
                    ForEach(details.penaltiesList.filter({ !$0.contains("Empty") }), id: \.self) { pen in
                        HStack(spacing: 5) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                            Text(pen)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(Color.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1), in: Capsule())
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Unplaced Components Tray
    
    private var unplacedInventoryTray: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("COMPONENT INVENTORY TRAY (Tap to rotate 90°)")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.46))
                .padding(.horizontal, 4)
            
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.62))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(QuotaOS.Colors.logoInk.opacity(0.08), lineWidth: 1.2))
                
                if viewModel.tray.isEmpty {
                    VStack {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.green.opacity(0.6))
                        Text("All items placed on grid!")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(QuotaOS.Colors.logoInk.opacity(0.50))
                    }
                    .frame(height: 76)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.tray) { comp in
                                trayComponentCard(comp: comp)
                                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                    .frame(height: 94)
                }
            }
            .offset(x: isTrayShaking ? CGFloat.random(in: -4...4) : 0, y: isTrayShaking ? CGFloat.random(in: -4...4) : 0)
        }
    }
    
    private func trayComponentCard(comp: SKUComponent) -> some View {
        let cardW: CGFloat = 80
        let cardH: CGFloat = 72
        
        return ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [comp.colors.top.opacity(0.9), comp.colors.bottom.opacity(0.9)], startPoint: .top, endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                )
                .frame(width: cardW, height: cardH)
            
            VStack(spacing: 4) {
                Image(systemName: comp.iconName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                
                Text(comp.name)
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text("\(comp.width)x\(comp.height)")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(4)
        }
        .rotationEffect(.degrees(comp.rotationDegrees))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: comp.rotationDegrees)
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                let _ = viewModel.rotateComponent(comp)
            }
        }
        .gesture(
            DragGesture(coordinateSpace: .global)
                .onChanged { gesture in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        if viewModel.activeDraggedComponent == nil {
                            viewModel.handleDragStarted(comp)
                        }
                        viewModel.dragOffset = gesture.translation
                        viewModel.dragLocation = gesture.location
                    }
                }
                .onEnded { gesture in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        let finalLoc = gesture.location
                        let targetCoord = findCellCoordinates(at: finalLoc)
                        if let target = targetCoord {
                            let anchor = calculateAnchorCell(hoverX: target.x, hoverY: target.y, w: comp.width, h: comp.height)
                            viewModel.handleDragEnded(targetCell: (anchor.x, anchor.y))
                        } else {
                            viewModel.handleDragEnded(targetCell: nil)
                        }
                    }
                }
        )
    }
    
    // MARK: - Compile Action Button
    
    private var compileActionButton: some View {
        let hasItems = !viewModel.placedComponents.isEmpty
        let isCompiling = viewModel.isCompiling
        
        return Button(action: {
            guard hasItems && !isCompiling else { return }
            
            viewModel.compileQuote(state: gameState) { weapon in
                // Success modal callback
                self.compiledWeapon = weapon
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showSuccessModal = true
                }
            }
        }) {
            HStack(spacing: 8) {
                if isCompiling {
                    ProgressView()
                        .tint(.white)
                    Text("DIAGNOSTICS & ENCRYPTING...")
                } else {
                    Image(systemName: "cpu")
                        .font(.system(size: 15, weight: .bold))
                    Text("COMPILE CONFIGURED QUOTE")
                }
            }
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(hasItems ? Color.white : QuotaOS.Colors.logoInk.opacity(0.50))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                !hasItems ?
                LinearGradient(colors: [Color.white.opacity(0.80), QuotaOS.Colors.logoInk.opacity(0.10)], startPoint: .top, endPoint: .bottom) :
                (isCompiling ?
                 LinearGradient(colors: [Color.cyan.opacity(0.6), Color.blue.opacity(0.6)], startPoint: .top, endPoint: .bottom) :
                 LinearGradient(colors: [Color.orange, Color(red: 0.85, green: 0.45, blue: 0.10)], startPoint: .top, endPoint: .bottom)),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(hasItems && !isCompiling ? Color.white.opacity(0.25) : QuotaOS.Colors.logoInk.opacity(0.10), lineWidth: 1.5)
            )
            .shadow(color: hasItems && !isCompiling ? Color.orange.opacity(0.3) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(!hasItems || isCompiling)
    }
    
    // MARK: - Grid Snapping Math Coordinate Helpers
    
    private func findCellCoordinates(at globalPoint: CGPoint) -> (x: Int, y: Int)? {
        guard let match = cellFrames.first(where: { $0.value.contains(globalPoint) }) else {
            return nil
        }
        let index = match.key
        let x = index % gridSize
        let y = index / gridSize
        return (x, y)
    }
    
    private func calculateAnchorCell(hoverX: Int, hoverY: Int, w: Int, h: Int) -> (x: Int, y: Int) {
        // Center-align the block footprint under the finger
        let offX = (w - 1) / 2
        let offY = (h - 1) / 2
        
        let ax = hoverX - offX
        let ay = hoverY - offY
        
        // Dynamic constraint bounding snaps
        let snapX = max(0, min(gridSize - w, ax))
        let snapY = max(0, min(gridSize - h, ay))
        return (snapX, snapY)
    }
    
    // MARK: - Success Modal overlay dialog
    
    private func successWeaponModal(weapon: ContractWeapon) -> some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Glow logo ring
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: 80, height: 80)
                        .overlay(Circle().stroke(Color.orange.opacity(0.25), lineWidth: 1.5))
                    
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Color.orange)
                        .shadow(color: .orange, radius: 10, y: 0)
                }
                .padding(.top, 10)
                
                VStack(spacing: 8) {
                    Text("QUOTE COMPILED!")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("A powerful Contract Weapon was created from your configured pipeline SKUs!")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }
                
                // Weapon stats card
                VStack(spacing: 12) {
                    Text(weapon.name)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.top, 12)
                    
                    Divider().background(Color.white.opacity(0.08))
                    
                    HStack(spacing: 24) {
                        VStack(alignment: .center, spacing: 4) {
                            Text("Q-MARGIN")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                            Text("$\(weapon.qMargin)")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(Color.green)
                        }
                        
                        VStack(alignment: .center, spacing: 4) {
                            Text("PITCH DAMAGE")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                            Text("\(weapon.baseDamage) HP")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .center, spacing: 4) {
                            Text("JARGON COST")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                            Text("\(weapon.jargonCost) MP")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(Color.blue)
                        }
                    }
                    .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.03))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
                )
                .padding(.horizontal, 12)
                
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        // Append to GameState compiled weapons list
                        gameState.compiledQuotes.append(weapon)
                        gameState.saveQuotes()
                        gameState.completeCareerStep(.qBot)
                        if weapon.qMargin < 250 {
                            gameState.bidDesk.lastOutcome = "Low-margin quote routed to Bid Desk."
                        }
                        gameState.persistCareer()
                        
                        // Clear the view grid and reset puzzle tray for future configurarions
                        viewModel.resetTray()
                        
                        showSuccessModal = false
                        compiledWeapon = nil
                    }
                }) {
                    Text("EQUIP TO PORTFOLIO")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            LinearGradient(colors: [Color.orange, Color(red: 0.85, green: 0.45, blue: 0.10)], startPoint: .top, endPoint: .bottom),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.white.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.12, green: 0.14, blue: 0.18))
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 2))
                    .shadow(color: .black.opacity(0.6), radius: 24, y: 16)
            )
            .frame(width: 320)
        }
    }
    
    // MARK: - Q-Bot Instructions / Help Overlay Modal View
    
    private var instructionsOverlayModal: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showInstructionsModal = false
                    }
                }
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.orange)
                    Text("Q-BOT 3000 MANUAL")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showInstructionsModal = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                
                Divider().background(Color.white.opacity(0.15))
                
                // Instructions list
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        
                        instructionSection(
                            title: "1. GOAL",
                            desc: "Pack software & hardware components (SKU blocks) onto the 6x6 spatial grid without overlaps to maximize your Q-Margin score!"
                        )
                        
                        instructionSection(
                            title: "2. CONTROLS",
                            desc: "• TAP blocks in your tray or grid to rotate them 90°.\n• DRAG & DROP blocks from the tray onto any grid square.\n• DRAG blocks off the grid to return them to your tray."
                        )
                        
                        instructionSection(
                            title: "3. SNAPPING",
                            desc: "A GREEN ghost footprint indicates a valid snap. A RED footprint indicates blocks overlap or exceed boundaries."
                        )
                        
                        instructionSection(
                            title: "4. COMPATIBILITY & SYNERGIES",
                            desc: "Link compatible components adjacent to each other for massive Q-Margin bonuses:\n• SaaS + Cloud: 1.5x Synergy\n• SaaS + Middleware: 1.2x Synergy\n• Server + Middleware: 1.3x Synergy\n• Server + Legacy DB: 1.1x Synergy\n• Cloud + Legacy DB: 1.4x Synergy"
                        )
                        
                        instructionSection(
                            title: "5. INCOMPATIBILITIES & PENALTIES",
                            desc: "Link incompatible blocks at your own risk:\n• SaaS next to Legacy DB: -$30\n• Server Blade next to Cloud: -$20\n• Empty Grid Cell: -$10 each!"
                        )
                        
                        instructionSection(
                            title: "6. BATTLE DEPLOYMENT",
                            desc: "Once packed, tap COMPILE to diagnostic-scan your quote into a custom named Contract Weapon. Equip it to pitch it during overworld Sales Battles for massive skepticism damage!"
                        )
                    }
                    .padding(.trailing, 4)
                }
                .frame(maxHeight: 280)
                
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showInstructionsModal = false
                    }
                }) {
                    Text("UNDERSTOOD")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            LinearGradient(colors: [Color.orange, Color(red: 0.85, green: 0.45, blue: 0.10)], startPoint: .top, endPoint: .bottom),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.12, green: 0.14, blue: 0.18))
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 2))
            )
            .frame(width: 320)
        }
    }
    
    private func instructionSection(title: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(Color.orange)
                .tracking(0.5)
            Text(desc)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .lineSpacing(3)
        }
    }
}

// MARK: - Individual Placed Block Card View

struct SKUBlockView: View {
    let component: SKUComponent
    let size: CGSize
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(LinearGradient(
                colors: [component.colors.top, component.colors.bottom],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white.opacity(0.35), lineWidth: 1.5)
            )
            .overlay(
                Image(systemName: component.iconName)
                    .font(.system(size: min(size.width, size.height) * 0.45, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 2.5, y: 2)
            )
            // Overlay dynamic badge showing component dims
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(component.width)x\(component.height)")
                            .font(.system(size: min(size.width, size.height) * 0.18, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 4))
                            .padding(6)
                    }
                }
            )
            .frame(width: size.width, height: size.height)
            .shadow(color: .black.opacity(0.2), radius: 4, y: 3.5)
    }
}
