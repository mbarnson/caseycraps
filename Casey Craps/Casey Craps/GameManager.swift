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
        player.clearPlaceBets()
    }

    /// Check if a Place bet can be placed on a specific number
    /// - Parameter number: The number to bet on
    /// - Returns: true if the bet can be placed or increased
    func canPlaceBet(on number: Int) -> Bool {
        // Only during point phase
        guard case .point(let point) = state else { return false }

        // Cannot place on the current point number
        guard number != point else { return false }

        // Must be a valid place number
        guard [4, 5, 6, 8, 9, 10].contains(number) else { return false }

        // Allowed to place new bet or increase existing bet
        return true
    }

    /// Last Place bet winnings (for UI feedback)
    @Published private(set) var lastPlaceBetWinnings: Int = 0

    /// Number that won from Place bet (for UI feedback)
    @Published private(set) var lastPlaceBetWinningNumber: Int? = nil

    // MARK: - Private Helpers

    private func handleComeOutRoll(total: Int) {
        guard let bet = player.currentBet else { return }

        switch bet.type {
        case .pass:
            handlePassComeOut(total: total)
        case .dontPass:
            handleDontPassComeOut(total: total)
        case .place:
            break  // Place bets not used in come-out phase
        }
    }

    private func handlePassComeOut(total: Int) {
        switch total {
        case 7, 11:
            // Natural - Pass wins
            print("Come-out \(total): Natural! Pass Line wins")
            player.winBet()
            state = .resolved(won: true)
        case 2, 3, 12:
            // Craps - Pass loses
            print("Come-out \(total): Craps! Pass Line loses")
            player.loseBet()
            state = .resolved(won: false)
        default:
            // Point established (4, 5, 6, 8, 9, 10)
            print("Come-out \(total): Point established")
            pointValue = total
            state = .point(total)
        }
    }

    private func handleDontPassComeOut(total: Int) {
        switch total {
        case 7, 11:
            // Natural - Don't Pass loses
            print("Come-out \(total): Natural! Don't Pass loses")
            player.loseBet()
            state = .resolved(won: false)
        case 2, 3:
            // Craps - Don't Pass wins
            print("Come-out \(total): Craps! Don't Pass wins")
            player.winBet()
            state = .resolved(won: true)
        case 12:
            // Bar 12 - Push
            print("Come-out \(total): Bar 12! Push")
            player.pushBet()
            state = .resolved(won: false)
        default:
            // Point established (4, 5, 6, 8, 9, 10)
            print("Come-out \(total): Point established")
            pointValue = total
            state = .point(total)
        }
    }

    private func handlePointRoll(total: Int, point: Int) {
        guard let bet = player.currentBet else { return }

        switch bet.type {
        case .pass:
            handlePassPointRoll(total: total, point: point)
        case .dontPass:
            handleDontPassPointRoll(total: total, point: point)
        case .place:
            break  // Place bets handled separately via placeBets array
        }
    }

    private func handlePassPointRoll(total: Int, point: Int) {
        // Reset place bet winnings tracking
        lastPlaceBetWinnings = 0
        lastPlaceBetWinningNumber = nil

        if total == point {
            // Hit the point - Pass wins
            print("Rolled \(point)! You hit the point - WIN!")
            player.winBet()
            state = .resolved(won: true)
            pointValue = nil
        } else if total == 7 {
            // Seven out - Pass loses, all place bets lose
            print("Seven out! You lose.")
            _ = player.resolvePlaceBets(rolledNumber: total, sevenOut: true)
            player.loseBet()
            state = .resolved(won: false)
            pointValue = nil
        } else {
            // Keep rolling - check for place bet wins
            let winnings = player.resolvePlaceBets(rolledNumber: total, sevenOut: false)
            if winnings > 0 {
                lastPlaceBetWinnings = winnings
                lastPlaceBetWinningNumber = total
                print("Place bet hit on \(total)! Won $\(winnings)")
            }
            print("Rolled \(total) - Point is \(point), keep rolling")
        }
    }

    private func handleDontPassPointRoll(total: Int, point: Int) {
        // Reset place bet winnings tracking
        lastPlaceBetWinnings = 0
        lastPlaceBetWinningNumber = nil

        if total == point {
            // Hit the point - Don't Pass loses
            print("Rolled \(point)! You hit the point - LOSE!")
            player.loseBet()
            state = .resolved(won: false)
            pointValue = nil
        } else if total == 7 {
            // Seven out - Don't Pass wins, but all place bets lose
            print("Seven out! You win.")
            _ = player.resolvePlaceBets(rolledNumber: total, sevenOut: true)
            player.winBet()
            state = .resolved(won: true)
            pointValue = nil
        } else {
            // Keep rolling - check for place bet wins
            let winnings = player.resolvePlaceBets(rolledNumber: total, sevenOut: false)
            if winnings > 0 {
                lastPlaceBetWinnings = winnings
                lastPlaceBetWinningNumber = total
                print("Place bet hit on \(total)! Won $\(winnings)")
            }
            print("Rolled \(total) - Point is \(point), keep rolling")
        }
    }
}
