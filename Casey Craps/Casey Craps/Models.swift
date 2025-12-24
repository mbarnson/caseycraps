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
enum BetType {
    case pass       // Wins on 7/11 come-out, loses on 2/3/12, then wins on point, loses on 7
    case dontPass   // Opposite of pass, 12 pushes on come-out
}

/// Represents a bet placed by the player
struct Bet {
    let type: BetType
    var amount: Int
}

/// Represents the player with bankroll and betting functionality
class Player {
    var bankroll: Int
    var currentBet: Bet?

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
}
