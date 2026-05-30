//
//  PipeDexViewModel.swift
//  Quote Crossing
//
//  ViewModel for the Pipe-Dex CRM pipeline mini-game (GDD §5.2).
//  Implements a 7x9 grid, casual Merge-2 mechanics, Bandwidth stamina-based generators,
//  a 5-minute cooldown Automated Dialer, real-time lead decay, and local state persistence.
//

import SwiftUI
import Combine

struct LeadItem: Codable, Identifiable, Equatable {
    let id: UUID
    var level: Int // 1 to 10
    var lastInteractedAt: Date
    var isWeed: Bool
    var weedTapsRemaining: Int
    
    init(id: UUID = UUID(), level: Int, lastInteractedAt: Date = Date(), isWeed: Bool = false, weedTapsRemaining: Int = 3) {
        self.id = id
        self.level = level
        self.lastInteractedAt = lastInteractedAt
        self.isWeed = isWeed
        self.weedTapsRemaining = weedTapsRemaining
    }
    
    // MARK: - Level Configurations
    
    var weedDescription: String {
        "This lead rotted from neglect! Tap it directly in the grid \(weedTapsRemaining) more times to weed it out and free the slot."
    }
    
    var name: String {
        if isWeed {
            return "Closed-Lost Weed"
        }
        switch level {
        case 1:  return "Cold Lead"
        case 2:  return "Warm Prospect"
        case 3:  return "Hand-Raiser"
        case 4:  return "Qualified Opportunity"
        case 5:  return "Proposal Sent"
        case 6:  return "Verbal Agreement"
        case 7:  return "Contract in Redlines"
        case 8:  return "Approved Contract"
        case 9:  return "Signed PO"
        case 10: return "Enterprise Account"
        default: return "Unknown Lead"
        }
    }
    
    var yield: Int {
        if isWeed { return 0 }
        switch level {
        case 1:  return 5
        case 2:  return 15
        case 3:  return 35
        case 4:  return 75
        case 5:  return 160
        case 6:  return 350
        case 7:  return 800
        case 8:  return 1800
        case 9:  return 4200
        case 10: return 10000
        default: return 0
        }
    }
    
    var decayDuration: TimeInterval {
        if isWeed { return 0 }
        switch level {
        case 1...3: return 120  // 2 minutes
        case 4...6: return 240  // 4 minutes
        case 7...9: return 480  // 8 minutes
        case 10:    return .infinity // Enterprise accounts never rot!
        default:    return 120
        }
    }
    
    var iconName: String {
        if isWeed { return "leaf.fill" }
        switch level {
        case 1:  return "snowflake"
        case 2:  return "flame.fill"
        case 3:  return "hand.raised.fill"
        case 4:  return "checkmark.seal.fill"
        case 5:  return "paperplane.fill"
        case 6:  return "phone.bubble.left.fill"
        case 7:  return "pencil.and.outline"
        case 8:  return "signature"
        case 9:  return "briefcase.fill"
        case 10: return "crown.fill"
        default: return "questionmark.circle"
        }
    }
    
    var colors: (top: Color, bottom: Color) {
        if isWeed {
            return (Color(red: 0.45, green: 0.38, blue: 0.35), Color(red: 0.32, green: 0.26, blue: 0.24)) // Withered brown
        }
        switch level {
        case 1: // Cold Lead
            return (Color(red: 0.40, green: 0.70, blue: 0.95), Color(red: 0.21, green: 0.48, blue: 0.82)) // Soft Blue
        case 2: // Warm Prospect
            return (Color(red: 0.95, green: 0.60, blue: 0.35), Color(red: 0.85, green: 0.42, blue: 0.18)) // Soft Orange
        case 3: // Hand-Raiser
            return (Color(red: 0.95, green: 0.80, blue: 0.30), Color(red: 0.85, green: 0.62, blue: 0.10)) // Warm Amber
        case 4: // Qualified Opportunity
            return (Color(red: 0.35, green: 0.85, blue: 0.55), Color(red: 0.18, green: 0.68, blue: 0.38)) // Bright Emerald Green
        case 5: // Proposal Sent
            return (Color(red: 0.30, green: 0.80, blue: 0.85), Color(red: 0.14, green: 0.60, blue: 0.68)) // Sleek Teal
        case 6: // Verbal Agreement
            return (Color(red: 0.65, green: 0.50, blue: 0.95), Color(red: 0.45, green: 0.32, blue: 0.80)) // Royal Indigo
        case 7: // Contract in Redlines
            return (Color(red: 0.95, green: 0.40, blue: 0.45), Color(red: 0.80, green: 0.20, blue: 0.28)) // Sharp Coral Red
        case 8: // Approved Contract
            return (Color(red: 0.80, green: 0.45, blue: 0.90), Color(red: 0.60, green: 0.25, blue: 0.75)) // Executive Violet
        case 9: // Signed PO
            return (Color(red: 0.30, green: 0.45, blue: 0.90), Color(red: 0.15, green: 0.28, blue: 0.70)) // Steel Business Blue
        case 10: // Enterprise Account
            return (Color(red: 0.98, green: 0.82, blue: 0.30), Color(red: 0.92, green: 0.58, blue: 0.10)) // Gold Crown Premium
        default:
            return (.gray, .black)
        }
    }
}

final class PipeDexViewModel: ObservableObject {
    private static let saveKey = "player.pipedex.grid.v1"
    
    // Grid properties: 7 columns x 9 rows = 63 cells
    @Published var grid: [LeadItem?] = Array(repeating: nil, count: 63)
    @Published var selectedIndex: Int? = nil
    
    // Cooldown and Timers
    @Published var automatedDialerLastUsed: Date? = nil
    @Published var automatedDialerRemainingCooldown: TimeInterval = 0
    
    // Custom Drag and Drop visual feedback properties
    @Published var activeDraggedIndex: Int? = nil
    @Published var dragOffset: CGSize = .zero
    @Published var dragLocation: CGPoint = .zero
    
    private var cancellables = Set<AnyCancellable>()
    private var decayTimer: Timer? = nil
    
    // Stamina configuration
    let spamDialerCost: Int = 10
    let automatedDialerCooldownDuration: TimeInterval = 300 // 5 minutes
    
    init() {
        loadState()
        startDecayLoop()
    }
    
    deinit {
        decayTimer?.invalidate()
    }
    
    // MARK: - State Persistence
    
    private struct PipeDexSavedState: Codable {
        let grid: [LeadItem?]
        let automatedDialerLastUsed: Date?
    }
    
    func saveState() {
        let state = PipeDexSavedState(grid: grid, automatedDialerLastUsed: automatedDialerLastUsed)
        if let encoded = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(encoded, forKey: Self.saveKey)
        }
    }
    
    func loadState() {
        guard let data = UserDefaults.standard.data(forKey: Self.saveKey),
              let decoded = try? JSONDecoder().decode(PipeDexSavedState.self, from: data) else {
            // Seed a few starter leads if grid is empty
            seedStarterLeads()
            return
        }
        self.grid = decoded.grid
        self.automatedDialerLastUsed = decoded.automatedDialerLastUsed
        updateCooldowns()
    }
    
    private func seedStarterLeads() {
        grid = Array(repeating: nil, count: 63)
        // Add a few level 1 and 2 leads in the grid to guide the player
        grid[10] = LeadItem(level: 1)
        grid[11] = LeadItem(level: 1)
        grid[18] = LeadItem(level: 2)
        grid[25] = LeadItem(level: 3)
        saveState()
    }
    
    // MARK: - Cooldowns and Ticks
    
    func updateCooldowns() {
        guard let lastUsed = automatedDialerLastUsed else {
            automatedDialerRemainingCooldown = 0
            return
        }
        let elapsed = Date().timeIntervalSince(lastUsed)
        let remaining = automatedDialerCooldownDuration - elapsed
        automatedDialerRemainingCooldown = max(0, remaining)
    }
    
    private func startDecayLoop() {
        decayTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tickDecayAndCooldowns()
            }
        }
    }
    
    private func tickDecayAndCooldowns() {
        updateCooldowns()
        
        let now = Date()
        var changed = false
        
        for i in 0..<grid.count {
            guard var item = grid[i], !item.isWeed else { continue }
            
            // Check if decayed
            let elapsed = now.timeIntervalSince(item.lastInteractedAt)
            if item.decayDuration != .infinity && elapsed >= item.decayDuration {
                // Rot into Closed-Lost Weed!
                item.isWeed = true
                item.weedTapsRemaining = 3
                grid[i] = item
                changed = true
                
                // If this is currently selected, refresh selection description
                if selectedIndex == i {
                    selectedIndex = i
                }
            }
        }
        
        if changed {
            saveState()
        }
    }
    
    // MARK: - Game Actions
    
    /// Spawns a Level 1 Lead instantly, costing 10 Bandwidth
    func triggerSpamEmailDialer(state: GameState) -> Bool {
        guard state.bandwidth >= spamDialerCost else { return false }
        
        // Find empty cell
        guard let emptyIndex = firstEmptyGridIndex() else { return false }
        
        state.bandwidth -= spamDialerCost
        grid[emptyIndex] = LeadItem(level: 1)
        selectedIndex = emptyIndex
        
        saveState()
        return true
    }
    
    /// Spawns a Lead (Level 1, 2, or 3) for free, on a 5-minute cooldown
    func triggerAutomatedLeadDialer() -> Bool {
        updateCooldowns()
        guard automatedDialerRemainingCooldown == 0 else { return false }
        guard let emptyIndex = firstEmptyGridIndex() else { return false }
        
        // Random level between 1 and 3 to reward the player for unlocking a 5m cooldown!
        let rolledLevel = Int.random(in: 1...3)
        grid[emptyIndex] = LeadItem(level: rolledLevel)
        automatedDialerLastUsed = Date()
        automatedDialerRemainingCooldown = automatedDialerCooldownDuration
        selectedIndex = emptyIndex
        
        saveState()
        return true
    }
    
    /// Claims the commission yield of a selected lead and empties the slot
    func closeSelectedDeal(state: GameState) -> Int? {
        guard let index = selectedIndex, let lead = grid[index], !lead.isWeed else { return nil }
        
        let reward = lead.yield
        
        // Award to GameState
        state.commishCash += reward
        state.lifetimeCommishCash += reward
        
        // Empty slot
        grid[index] = nil
        selectedIndex = nil
        
        saveState()
        return reward
    }
    
    /// Follows up on a lead (costs 2 Bandwidth, or free but resets decay timer)
    func followUpOnLead(state: GameState, at index: Int) -> Bool {
        guard var lead = grid[index], !lead.isWeed else { return false }
        // Follow up costs 2 bandwidth if possible, or free. Let's make it cost 3 bandwidth to maintain RPG resource tension!
        let cost = 3
        guard state.bandwidth >= cost else { return false }
        
        state.bandwidth -= cost
        lead.lastInteractedAt = Date()
        grid[index] = lead
        
        // Force refresh selection binding
        if selectedIndex == index {
            selectedIndex = index
        }
        
        saveState()
        return true
    }
    
    /// Handles multiple taps required to clear a Closed-Lost Weed
    func tapWeed(at index: Int) {
        guard var item = grid[index], item.isWeed else { return }
        
        item.weedTapsRemaining -= 1
        
        if item.weedTapsRemaining <= 0 {
            grid[index] = nil
            if selectedIndex == index {
                selectedIndex = nil
            }
        } else {
            grid[index] = item
        }
        
        saveState()
    }
    
    // MARK: - Drag and Drop Merge Logic
    
    func handleDragStarted(at index: Int) {
        guard let item = grid[index], !item.isWeed else { return }
        activeDraggedIndex = index
    }
    
    func handleDragEnded(targetIndex: Int?) {
        guard let sourceIndex = activeDraggedIndex else {
            activeDraggedIndex = nil
            dragOffset = .zero
            return
        }
        
        activeDraggedIndex = nil
        dragOffset = .zero
        
        guard let destIndex = targetIndex, destIndex != sourceIndex, destIndex >= 0, destIndex < grid.count else { return }
        
        performMergeOrMove(from: sourceIndex, to: destIndex)
    }
    
    private func performMergeOrMove(from source: Int, to dest: Int) {
        guard let sourceItem = grid[source], !sourceItem.isWeed else { return }
        
        if let destItem = grid[dest] {
            if destItem.isWeed {
                // Cannot merge onto weed, do nothing
                return
            }
            
            if sourceItem.level == destItem.level && sourceItem.level < 10 {
                // MERGE! Level X + Level X = Level X + 1
                let mergedItem = LeadItem(
                    level: sourceItem.level + 1,
                    lastInteractedAt: Date() // Reset decay clock on merge!
                )
                grid[dest] = mergedItem
                grid[source] = nil
                selectedIndex = dest
            } else {
                // Swapping places if levels don't match, or both are level 10
                grid[dest] = sourceItem
                grid[source] = destItem
                selectedIndex = dest
            }
        } else {
            // Moving to empty slot
            grid[dest] = sourceItem
            grid[source] = nil
            selectedIndex = dest
        }
        
        saveState()
    }
    
    // MARK: - Helper Methods
    
    private func firstEmptyGridIndex() -> Int? {
        grid.firstIndex(where: { $0 == nil })
    }
    
    var filledCount: Int {
        grid.filter { $0 != nil }.count
    }
    
    var weedCount: Int {
        grid.filter { $0?.isWeed == true }.count
    }
}
