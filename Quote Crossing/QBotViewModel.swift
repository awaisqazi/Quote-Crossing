//
//  QBotViewModel.swift
//  Quote Crossing
//
//  ViewModel for the Q-Bot 3000 Quote Configuration Terminal (GDD §5.3).
//  Implements a 6x6 spatial inventory grid matrix, footprint overlap collision logic,
//  component 90-degree rotations, dynamic adjacency synergy/penalty margin calculators,
//  and compiled contract weapon creations.
//

import SwiftUI
import Combine

struct SKUComponent: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let baseDamage: Int // V_i value
    var width: Int
    var height: Int
    var gridX: Int? // x coordinate on the 6x6 grid, nil if in tray
    var gridY: Int? // y coordinate on the 6x6 grid, nil if in tray
    var rotationDegrees: Double
    let type: SKUComponentType
    
    init(id: UUID = UUID(), name: String, baseDamage: Int, width: Int, height: Int, gridX: Int? = nil, gridY: Int? = nil, rotationDegrees: Double = 0, type: SKUComponentType) {
        self.id = id
        self.name = name
        self.baseDamage = baseDamage
        self.width = width
        self.height = height
        self.gridX = gridX
        self.gridY = gridY
        self.rotationDegrees = rotationDegrees
        self.type = type
    }
    
    var iconName: String {
        switch type {
        case .saasLicense:       return "doc.plaintext.fill"
        case .premiumServer:     return "cpu.fill"
        case .legacyDatabase:    return "externaldrive.fill"
        case .cloudStorage:      return "cloud.fill"
        case .middlewareAdapter: return "cable.connector"
        }
    }
    
    var colors: (top: Color, bottom: Color) {
        switch type {
        case .saasLicense:       return (Color(red: 0.35, green: 0.75, blue: 0.95), Color(red: 0.18, green: 0.48, blue: 0.80)) // Soft Blue
        case .premiumServer:     return (Color(red: 0.95, green: 0.45, blue: 0.45), Color(red: 0.80, green: 0.20, blue: 0.25)) // Bold Crimson
        case .legacyDatabase:    return (Color(red: 0.55, green: 0.58, blue: 0.64), Color(red: 0.38, green: 0.40, blue: 0.45)) // Slate Gray
        case .cloudStorage:      return (Color(red: 0.30, green: 0.85, blue: 0.70), Color(red: 0.15, green: 0.65, blue: 0.50)) // Emerald Teal
        case .middlewareAdapter: return (Color(red: 0.95, green: 0.80, blue: 0.30), Color(red: 0.85, green: 0.60, blue: 0.10)) // Gold / Amber
        }
    }
}

enum SKUComponentType: String, Codable {
    case saasLicense
    case premiumServer
    case legacyDatabase
    case cloudStorage
    case middlewareAdapter
}

struct ContractWeapon: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let qMargin: Int // The final compiled quality value
    let baseDamage: Int // Damage in battle
    let jargonCost: Int // Jargon cost to deploy in battle
    
    init(id: UUID = UUID(), name: String, qMargin: Int, baseDamage: Int, jargonCost: Int = 10) {
        self.id = id
        self.name = name
        self.qMargin = qMargin
        self.baseDamage = baseDamage
        self.jargonCost = jargonCost
    }
}

final class QBotViewModel: ObservableObject {
    private static let saveKey = "player.qbot.tray.v1"
    
    // Grid size: 6 columns x 6 rows
    let gridSize = 6
    
    // Placed components on the grid
    @Published var placedComponents: [SKUComponent] = []
    // Unplaced components in the inventory tray
    @Published var tray: [SKUComponent] = []
    
    // Drag-and-Drop coordinates tracking
    @Published var activeDraggedComponent: SKUComponent? = nil
    @Published var dragOffset: CGSize = .zero
    @Published var dragLocation: CGPoint = .zero
    
    // Compiling laser diagnostics animation states
    @Published var isCompiling = false
    @Published var compilationProgress: Double = 0.0
    
    init() {
        loadState()
    }
    
    // MARK: - State Persistence
    
    private struct QBotSavedState: Codable {
        let placedComponents: [SKUComponent]
        let tray: [SKUComponent]
    }
    
    func saveState() {
        let state = QBotSavedState(placedComponents: placedComponents, tray: tray)
        if let encoded = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(encoded, forKey: Self.saveKey)
        }
    }
    
    func loadState() {
        guard let data = UserDefaults.standard.data(forKey: Self.saveKey),
              let decoded = try? JSONDecoder().decode(QBotSavedState.self, from: data) else {
            resetTray()
            return
        }
        self.placedComponents = decoded.placedComponents
        self.tray = decoded.tray
    }
    
    func resetTray() {
        placedComponents = []
        // Seed exactly one of each SKUComponent type in the tray
        tray = [
            SKUComponent(name: "SaaS License", baseDamage: 45, width: 1, height: 2, type: .saasLicense),
            SKUComponent(name: "Premium Server", baseDamage: 150, width: 3, height: 1, type: .premiumServer),
            SKUComponent(name: "Legacy Database", baseDamage: 80, width: 2, height: 2, type: .legacyDatabase),
            SKUComponent(name: "Cloud Storage", baseDamage: 15, width: 1, height: 1, type: .cloudStorage),
            SKUComponent(name: "Middleware Adapter", baseDamage: 110, width: 3, height: 1, type: .middlewareAdapter)
        ]
        saveState()
    }
    
    // MARK: - Rotation Controls
    
    /// Rotates a component by 90 degrees. Swaps width and height dimensions.
    func rotateComponent(_ component: SKUComponent) -> Bool {
        var copy = component
        // Swap footprint dimensions
        let tempWidth = copy.width
        copy.width = copy.height
        copy.height = tempWidth
        copy.rotationDegrees = (copy.rotationDegrees + 90).truncatingRemainder(dividingBy: 360)
        
        if copy.gridX == nil {
            // In the tray: rotation is always allowed
            if let idx = tray.firstIndex(where: { $0.id == component.id }) {
                tray[idx] = copy
                saveState()
                return true
            }
        } else {
            // On the grid: check if the rotated bounds still fit and overlap no other blocks
            if canPlace(component: copy, atX: copy.gridX!, atY: copy.gridY!, ignoringId: copy.id) {
                if let idx = placedComponents.firstIndex(where: { $0.id == component.id }) {
                    placedComponents[idx] = copy
                    saveState()
                    return true
                }
            }
        }
        return false // Rotation blocked by bounds or collisions
    }
    
    // MARK: - Placement Math
    
    /// Checks if a component footprint fits within boundaries and has no cell overlaps
    func canPlace(component: SKUComponent, atX x: Int, atY y: Int, ignoringId: UUID? = nil) -> Bool {
        // Bounds checking
        guard x >= 0, x + component.width <= gridSize,
              y >= 0, y + component.height <= gridSize else {
            return false
        }
        
        // Scan for collisions with other placed blocks
        for placed in placedComponents {
            if let px = placed.gridX, let py = placed.gridY, placed.id != ignoringId {
                // Check cell overlap
                let compXRange = x..<(x + component.width)
                let compYRange = y..<(y + component.height)
                
                let placedXRange = px..<(px + placed.width)
                let placedYRange = py..<(py + placed.height)
                
                let overlapX = compXRange.overlaps(placedXRange)
                let overlapY = compYRange.overlaps(placedYRange)
                
                if overlapX && overlapY {
                    return false // Cell collision detected!
                }
            }
        }
        
        return true
    }
    
    func placeComponent(_ component: SKUComponent, atX x: Int, atY y: Int) -> Bool {
        var copy = component
        copy.gridX = x
        copy.gridY = y
        
        guard canPlace(component: copy, atX: x, atY: y, ignoringId: component.id) else {
            return false
        }
        
        // Remove from current locations
        removeComponent(component)
        
        placedComponents.append(copy)
        saveState()
        return true
    }
    
    func returnToTray(_ component: SKUComponent) {
        var copy = component
        copy.gridX = nil
        copy.gridY = nil
        
        // Remove from current locations
        removeComponent(component)
        
        tray.append(copy)
        saveState()
    }
    
    private func removeComponent(_ component: SKUComponent) {
        placedComponents.removeAll(where: { $0.id == component.id })
        tray.removeAll(where: { $0.id == component.id })
    }
    
    // MARK: - Drag and Drop Hooks
    
    func handleDragStarted(_ component: SKUComponent) {
        activeDraggedComponent = component
    }
    
    func handleDragEnded(targetCell: (x: Int, y: Int)?) {
        guard let dragged = activeDraggedComponent else {
            activeDraggedComponent = nil
            dragOffset = .zero
            return
        }
        
        activeDraggedComponent = nil
        dragOffset = .zero
        
        if let cell = targetCell {
            if !placeComponent(dragged, atX: cell.x, atY: cell.y) {
                // Revert to tray if placement fails
                returnToTray(dragged)
            }
        } else {
            // Dragged completely off-grid
            returnToTray(dragged)
        }
    }
    
    // MARK: - Quote Quality Calculations
    
    /// Occupancy lookup array mapping cell coordinates
    private func buildOccupancyMap() -> [SKUComponent?] {
        var map = Array<SKUComponent?>(repeating: nil, count: 36)
        for comp in placedComponents {
            if let px = comp.gridX, let py = comp.gridY {
                for dx in 0..<comp.width {
                    for dy in 0..<comp.height {
                        let cellIdx = (py + dy) * gridSize + (px + dx)
                        if cellIdx >= 0 && cellIdx < 36 {
                            map[cellIdx] = comp
                        }
                    }
                }
            }
        }
        return map
    }
    
    /// Scans adjacency grid to calculate active synergies and physical mismatch penalties
    func calculateMarginDetails() -> (qMargin: Int, emptyCellsCount: Int, synergiesList: [String], penaltiesList: [String]) {
        let occMap = buildOccupancyMap()
        
        var totalSynergyContribution = 0.0
        var totalIncompatibilityPenalties = 0
        
        var synergiesList: [String] = []
        var penaltiesList: [String] = []
        
        // Keep track of evaluated adjacency pairs to avoid double-counting
        var evaluatedPairs = Set<String>()
        
        // Helper to check cardinal neighbors
        func checkAdjacency(x1: Int, y1: Int, x2: Int, y2: Int) {
            guard x1 >= 0 && x1 < 6 && y1 >= 0 && y1 < 6,
                  x2 >= 0 && x2 < 6 && y2 >= 0 && y2 < 6 else { return }
            
            let idx1 = y1 * gridSize + x1
            let idx2 = y2 * gridSize + x2
            
            guard let compA = occMap[idx1], let compB = occMap[idx2], compA.id != compB.id else { return }
            
            // Format stable key to keep pair uniqueness
            let pairKey = compA.id.uuidString < compB.id.uuidString
                ? "\(compA.id)-\(compB.id)"
                : "\(compB.id)-\(compA.id)"
            
            guard !evaluatedPairs.contains(pairKey) else { return }
            evaluatedPairs.insert(pairKey)
            
            // Assess Adjacency Combinations
            let t1 = compA.type
            let t2 = compB.type
            
            // 1. Synergies (M_i multipliers)
            if (t1 == .saasLicense && t2 == .cloudStorage) || (t1 == .cloudStorage && t2 == .saasLicense) {
                // 1.5x SaaS + Cloud Combo
                synergiesList.append("SaaS + Cloud Cloud Cluster (1.5x Synergy)")
                totalSynergyContribution += Double(compA.baseDamage + compB.baseDamage) * 0.5
            } else if (t1 == .saasLicense && t2 == .middlewareAdapter) || (t1 == .middlewareAdapter && t2 == .saasLicense) {
                // 1.2x SaaS + Middleware Adapter
                synergiesList.append("SaaS + Middleware Integration (1.2x Synergy)")
                totalSynergyContribution += Double(compA.baseDamage + compB.baseDamage) * 0.2
            } else if (t1 == .premiumServer && t2 == .middlewareAdapter) || (t1 == .middlewareAdapter && t2 == .premiumServer) {
                // 1.3x Hardware Server + Middleware
                synergiesList.append("Server Blade Hardware Bus (1.3x Synergy)")
                totalSynergyContribution += Double(compA.baseDamage + compB.baseDamage) * 0.3
            } else if (t1 == .premiumServer && t2 == .legacyDatabase) || (t1 == .legacyDatabase && t2 == .premiumServer) {
                // 1.1x Server + Legacy DB
                synergiesList.append("Bare Metal DB Local Hosting (1.1x Synergy)")
                totalSynergyContribution += Double(compA.baseDamage + compB.baseDamage) * 0.1
            } else if (t1 == .cloudStorage && t2 == .legacyDatabase) || (t1 == .legacyDatabase && t2 == .cloudStorage) {
                // 1.4x Cloud + Legacy Database
                synergiesList.append("Legacy DB Cloud Replication (1.4x Synergy)")
                totalSynergyContribution += Double(compA.baseDamage + compB.baseDamage) * 0.4
            }
            
            // 2. Incompatibilities (C_expl charges)
            if (t1 == .saasLicense && t2 == .legacyDatabase) || (t1 == .legacyDatabase && t2 == .saasLicense) {
                // Software mismatch
                penaltiesList.append("SaaS adjacent to Legacy DB (-$30 mismatch!)")
                totalIncompatibilityPenalties += 30
            } else if (t1 == .premiumServer && t2 == .cloudStorage) || (t1 == .cloudStorage && t2 == .premiumServer) {
                // Cloud redundancy
                penaltiesList.append("Physical Blade adjacent to Cloud (-$20 mismatch!)")
                totalIncompatibilityPenalties += 20
            }
        }
        
        // Scan cardinally adjacent pairs on the grid
        for y in 0..<gridSize {
            for x in 0..<gridSize {
                checkAdjacency(x1: x, y1: y, x2: x + 1, y2: y) // Right Check
                checkAdjacency(x1: x, y1: y, x2: x, y2: y + 1) // Down Check
            }
        }
        
        // 3. Base damage values sum
        let baseValSum = placedComponents.reduce(0, { $0 + $1.baseDamage })
        
        // 4. Physical Empty Spaces Penalty ($10 each)
        let emptyCellsCount = occMap.filter({ $0 == nil }).count
        let emptySpacesPenalty = emptyCellsCount * 10
        
        if emptyCellsCount > 0 {
            penaltiesList.append("\(emptyCellsCount) Empty Spaces (-$\(emptySpacesPenalty))")
        }
        
        // Q_margin = SUM(V_i * M_i) - C_expl
        // Formulated as: Base_Val_Sum + Synergy_Bonus - Incompatible_Mismatch_Penalties - Empty_Spaces_Penalties
        let qMarginFloat = Double(baseValSum) + totalSynergyContribution - Double(totalIncompatibilityPenalties) - Double(emptySpacesPenalty)
        let qMargin = max(0, Int(qMarginFloat.rounded()))
        
        return (qMargin, emptyCellsCount, synergiesList, penaltiesList)
    }
    
    // MARK: - Compilation Sequence
    
    /// Triggers quote lasers scanning and creates final weapon
    func compileQuote(state: GameState, completion: @escaping (ContractWeapon) -> Void) {
        guard !placedComponents.isEmpty else { return }
        isCompiling = true
        compilationProgress = 0.0
        
        // 1.5s sweeps laser diagnostics
        let steps = 30
        let delay = 1.5 / Double(steps)
        var currentStep = 0
        
        Timer.scheduledTimer(withTimeInterval: delay, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            currentStep += 1
            self.compilationProgress = Double(currentStep) / Double(steps)
            
            if currentStep >= steps {
                timer.invalidate()
                self.isCompiling = false
                
                // Perform final margin compile
                let marginDetails = self.calculateMarginDetails()
                
                // Formulate a beautiful weapon name based on top elements
                let weaponName = self.generateThematicWeaponName()
                let totalBaseDamage = self.placedComponents.reduce(0, { $0 + $1.baseDamage })
                
                // Weapons Jargon cost scales with grid complexity (more elements = higher cost)
                let complexityCost = max(5, min(25, self.placedComponents.count * 4))
                
                let finalWeapon = ContractWeapon(
                    name: weaponName,
                    qMargin: marginDetails.qMargin,
                    baseDamage: max(10, totalBaseDamage + marginDetails.qMargin / 10),
                    jargonCost: complexityCost
                )
                
                completion(finalWeapon)
            }
        }
    }
    
    private func generateThematicWeaponName() -> String {
        guard !placedComponents.isEmpty else { return "Boring Quote" }
        
        let types = placedComponents.map({ $0.type })
        let hasCloud = types.contains(.cloudStorage)
        let hasHardware = types.contains(.premiumServer)
        let hasSaas = types.contains(.saasLicense)
        let hasDB = types.contains(.legacyDatabase)
        
        if hasCloud && hasSaas {
            return "Serverless Synergy Suite"
        } else if hasHardware && hasDB {
            return "Ironclad Legacy Monolith"
        } else if hasSaas && hasDB {
            return "Multi-Tenant Legacy Hack"
        } else if hasCloud && hasHardware {
            return "Hybrid Cloud Hyper-Blade"
        } else {
            return "Standard B2B SYNERGY-Quote"
        }
    }
}
