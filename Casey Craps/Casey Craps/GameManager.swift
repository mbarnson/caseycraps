//
//  GameManager.swift
//  Casey Craps
//
//  Created by Matthew Barnson on 12/24/25.
//

import Foundation
import Combine

/// Represents the different states of a craps game
enum GameState: Equatable {
    case waitingForBet          // Initial state - player must place a bet
    case comeOut                // Come-out roll - 7/11 wins, 2/3/12 loses, other sets point
    case point(Int)             // Point established - hit point wins, 7 loses
    case resolved(won: Bool)    // Roll resolved - shows result before reset
}

/// Singleton game manager that controls the craps game state machine
class GameManager: ObservableObject {
    static let shared = GameManager()

    /// Current game state
    @Published private(set) var state: GameState = .waitingForBet

    /// Current point value when in point phase
    @Published private(set) var pointValue: Int?

    /// Player with bankroll and betting
    let player = Player()

    private init() {}

    /// Place a bet and transition to come-out roll phase
    func placeBet() {
        guard state == .waitingForBet else { return }
        state = .comeOut
    }

    /// Process a dice roll and handle state transitions
    /// - Parameters:
    ///   - die1: First die value (1-6)
    ///   - die2: Second die value (1-6)
    func roll(die1: Int, die2: Int) {
        let total = die1 + die2

        switch state {
        case .comeOut:
            handleComeOutRoll(total: total)
        case .point(let point):
            handlePointRoll(total: total, point: point)
        default:
            break
        }
    }

    /// Reset the game to initial state
    func reset() {
        state = .waitingForBet
        pointValue = nil
    }

    // MARK: - Private Helpers

    private func handleComeOutRoll(total: Int) {
        switch total {
        case 7, 11:
            // Natural - player wins
            state = .resolved(won: true)
        case 2, 3, 12:
            // Craps - player loses
            state = .resolved(won: false)
        default:
            // Point established
            pointValue = total
            state = .point(total)
        }
    }

    private func handlePointRoll(total: Int, point: Int) {
        if total == point {
            // Hit the point - player wins
            state = .resolved(won: true)
            pointValue = nil
        } else if total == 7 {
            // Seven out - player loses
            state = .resolved(won: false)
            pointValue = nil
        }
        // Any other roll continues the point phase
    }
}
