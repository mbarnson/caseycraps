//
//  Models.swift
//  Casey Craps
//
//  Created by Matthew Barnson on 12/24/25.
//

import Foundation

/// Represents a single die
struct Die {
    var value: Int

    /// Roll a die and return a random value between 1-6
    static func roll() -> Int {
        return Int.random(in: 1...6)
    }
}

/// Types of bets available in craps
enum BetType: Equatable {
    case pass           // Wins on 7/11 come-out, loses on 2/3/12, then wins on point, loses on 7
    case dontPass       // Opposite of pass, 12 pushes on come-out
    case place(Int)     // Place bet on specific number (4, 5, 6, 8, 9, 10)
}

/// Calculate payout for a Place bet (rounded to nearest dollar)
/// - 6 and 8 pay 7:6
/// - 5 and 9 pay 7:5
/// - 4 and 10 pay 9:5
func placeBetPayout(number: Int, betAmount: Int) -> Int {
    switch number {
    case 6, 8:
        // 7:6 odds - bet $6, win $7
        return Int(round(Double(betAmount) * 7.0 / 6.0))
    case 5, 9:
        // 7:5 odds - bet $5, win $7
        return Int(round(Double(betAmount) * 7.0 / 5.0))
    case 4, 10:
        // 9:5 odds - bet $5, win $9
        return Int(round(Double(betAmount) * 9.0 / 5.0))
    default:
        return 0
    }
}

/// Represents a bet placed by the player
struct Bet {
    let type: BetType
    var amount: Int
}

/// Represents the player with bankroll and betting functionality
class Player {
    var bankroll: Int
    var currentBet: Bet?       // Pass/Don't Pass line bet
    var placeBets: [Bet] = []  // Place bets on point numbers

    init(bankroll: Int = 1000) {
        self.bankroll = bankroll
    }

    /// Place a bet if the player has sufficient funds
    /// - Parameters:
    ///   - type: The type of bet to place
    ///   - amount: The amount to bet
    /// - Returns: true if bet was placed successfully, false if insufficient funds
    func placeBet(type: BetType, amount: Int) -> Bool {
        guard amount <= bankroll else {
            return false
        }

        bankroll -= amount
        currentBet = Bet(type: type, amount: amount)
        return true
    }

    /// Player wins the bet - doubles bet amount and adds to bankroll
    func winBet() {
        guard let bet = currentBet else { return }
        bankroll += bet.amount * 2
        currentBet = nil
    }

    /// Player loses the bet - money already deducted on placement
    func loseBet() {
        currentBet = nil
    }

    /// Push - return bet amount to bankroll
    func pushBet() {
        guard let bet = currentBet else { return }
        bankroll += bet.amount
        currentBet = nil
    }

    // MARK: - Place Bets

    /// Place a bet on a specific number (4, 5, 6, 8, 9, 10)
    /// - Parameters:
    ///   - number: The number to bet on
    ///   - amount: The amount to bet
    /// - Returns: true if bet was placed successfully
    func placePlaceBet(number: Int, amount: Int) -> Bool {
        guard amount <= bankroll else { return false }
        guard [4, 5, 6, 8, 9, 10].contains(number) else { return false }

        // Check if already have a bet on this number
        if placeBets.contains(where: { if case .place(let n) = $0.type { return n == number } else { return false } }) {
            return false
        }

        bankroll -= amount
        placeBets.append(Bet(type: .place(number), amount: amount))
        return true
    }

    /// Check if player has a place bet on a specific number
    func hasPlaceBet(on number: Int) -> Bool {
        return placeBets.contains {
            if case .place(let n) = $0.type { return n == number }
            return false
        }
    }

    /// Get the amount of a place bet on a specific number
    /// - Parameter number: The number to check
    /// - Returns: The bet amount, or nil if no bet exists
    func getPlaceBetAmount(on number: Int) -> Int? {
        for bet in placeBets {
            if case .place(let n) = bet.type, n == number {
                return bet.amount
            }
        }
        return nil
    }

    /// Take down (remove) a place bet and return the money
    /// - Parameter number: The number to remove the bet from
    /// - Returns: The amount returned, or 0 if no bet existed
    func takeDownPlaceBet(number: Int) -> Int {
        if let index = placeBets.firstIndex(where: {
            if case .place(let n) = $0.type { return n == number }
            return false
        }) {
            let amount = placeBets[index].amount
            bankroll += amount
            placeBets.remove(at: index)
            return amount
        }
        return 0
    }

    /// Resolve place bets based on the rolled number
    /// - Parameters:
    ///   - rolledNumber: The total of the dice roll
    ///   - sevenOut: Whether a 7 was rolled (all place bets lose)
    /// - Returns: Total winnings from place bets
    func resolvePlaceBets(rolledNumber: Int, sevenOut: Bool) -> Int {
        var winnings = 0

        if sevenOut {
            // All place bets lose - money already deducted when placed
            placeBets.removeAll()
        } else {
            // Check if any place bet hit
            if let index = placeBets.firstIndex(where: {
                if case .place(let n) = $0.type { return n == rolledNumber }
                return false
            }) {
                let bet = placeBets[index]
                let payout = placeBetPayout(number: rolledNumber, betAmount: bet.amount)
                winnings = bet.amount + payout  // Return original bet + winnings
                bankroll += winnings
                placeBets.remove(at: index)
            }
        }

        return winnings
    }

    /// Clear all place bets and return money to player (bets "taken down", not lost)
    func clearPlaceBets() {
        for bet in placeBets {
            bankroll += bet.amount
        }
        placeBets.removeAll()
    }

    /// Lose all place bets (seven-out scenario - money already deducted)
    func loseAllPlaceBets() {
        placeBets.removeAll()
    }

    /// Reset bankroll to starting amount for a new game
    func resetBankroll() {
        bankroll = 1000
        currentBet = nil
        placeBets.removeAll()
    }
}
