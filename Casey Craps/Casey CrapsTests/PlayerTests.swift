//
//  PlayerTests.swift
//  Casey CrapsTests
//
//  Created by Claude on 12/25/25.
//

import Testing
@testable import Casey_Craps

/// Comprehensive tests for Player class bankroll and betting operations
@Suite(.serialized)
struct PlayerTests {

    // MARK: - Initialization Tests

    @Test func initialBankrollIsSetCorrectly() {
        let player = Player(bankroll: 1000)
        #expect(player.bankroll == 1000, "Initial bankroll should be set to 1000")
        #expect(player.currentBet == nil, "Should have no current bet")
        #expect(player.placeBets.isEmpty, "Should have no place bets")
    }

    @Test func customBankrollIsSetCorrectly() {
        let player = Player(bankroll: 5000)
        #expect(player.bankroll == 5000, "Custom bankroll should be set correctly")
    }

    // MARK: - placeBet Tests

    @Test func placeBetDeductsFromBankroll() {
        let player = Player(bankroll: 1000)
        let success = player.placeBet(type: .pass, amount: 100)

        #expect(success == true, "Bet should be placed successfully")
        #expect(player.bankroll == 900, "Bankroll should be reduced by bet amount")
        #expect(player.currentBet?.amount == 100, "Current bet amount should be 100")
        #expect(player.currentBet?.type == .pass, "Current bet type should be .pass")
    }

    @Test func placeBetFailsWhenInsufficientFunds() {
        let player = Player(bankroll: 50)
        let success = player.placeBet(type: .pass, amount: 100)

        #expect(success == false, "Bet should fail when insufficient funds")
        #expect(player.bankroll == 50, "Bankroll should remain unchanged")
        #expect(player.currentBet == nil, "No bet should be placed")
    }

    @Test func placeBetSucceedsWithExactBankrollAmount() {
        let player = Player(bankroll: 100)
        let success = player.placeBet(type: .pass, amount: 100)

        #expect(success == true, "Bet should succeed with exact bankroll amount")
        #expect(player.bankroll == 0, "Bankroll should be zero")
        #expect(player.currentBet?.amount == 100, "Current bet amount should be 100")
    }

    @Test func placeBetRejectsZeroAmount() {
        let player = Player(bankroll: 1000)
        let success = player.placeBet(type: .pass, amount: 0)

        #expect(success == true, "Zero bet technically succeeds but is meaningless")
        #expect(player.bankroll == 1000, "Bankroll unchanged for zero bet")
    }

    // MARK: - winBet Tests

    @Test func winBetAddsCorrectAmountToBankroll() {
        let player = Player(bankroll: 1000)
        player.placeBet(type: .pass, amount: 100)
        // Bankroll is now 900

        player.winBet()

        #expect(player.bankroll == 1100, "Bankroll should be 900 + 200 (bet + winnings)")
        #expect(player.currentBet == nil, "Current bet should be cleared")
    }

    @Test func winBetDoublesOriginalBet() {
        let player = Player(bankroll: 1000)
        player.placeBet(type: .pass, amount: 250)
        // Bankroll is now 750

        player.winBet()

        #expect(player.bankroll == 1250, "Bankroll should be 750 + 500 (original bet doubled)")
        #expect(player.currentBet == nil, "Current bet should be cleared")
    }

    @Test func winBetWithNoBetDoesNothing() {
        let player = Player(bankroll: 1000)

        player.winBet()

        #expect(player.bankroll == 1000, "Bankroll should remain unchanged")
        #expect(player.currentBet == nil, "No bet should exist")
    }

    // MARK: - loseBet Tests

    @Test func loseBetClearsBetButNoRefund() {
        let player = Player(bankroll: 1000)
        player.placeBet(type: .pass, amount: 100)
        // Bankroll is now 900

        player.loseBet()

        #expect(player.bankroll == 900, "Bankroll should remain at 900 (no refund)")
        #expect(player.currentBet == nil, "Current bet should be cleared")
    }

    // MARK: - pushBet Tests

    @Test func pushBetReturnsBetAmount() {
        let player = Player(bankroll: 1000)
        player.placeBet(type: .dontPass, amount: 100)
        // Bankroll is now 900

        player.pushBet()

        #expect(player.bankroll == 1000, "Bankroll should be restored to 1000")
        #expect(player.currentBet == nil, "Current bet should be cleared")
    }

    // MARK: - Bankroll Cannot Go Negative

    @Test func bankrollCannotGoNegative() {
        let player = Player(bankroll: 50)
        let success = player.placeBet(type: .pass, amount: 100)

        #expect(success == false, "Cannot place bet larger than bankroll")
        #expect(player.bankroll == 50, "Bankroll should remain positive")
    }

    // MARK: - Place Bets Tests

    @Test func placePlaceBetDeductsFromBankroll() {
        let player = Player(bankroll: 1000)
        let success = player.placePlaceBet(number: 6, amount: 60)

        #expect(success == true, "Place bet should succeed")
        #expect(player.bankroll == 940, "Bankroll should be reduced by 60")
        #expect(player.placeBets.count == 1, "Should have one place bet")
        #expect(player.hasPlaceBet(on: 6) == true, "Should have place bet on 6")
    }

    @Test func placePlaceBetFailsOnInvalidNumber() {
        let player = Player(bankroll: 1000)

        #expect(player.placePlaceBet(number: 7, amount: 50) == false, "Cannot place on 7")
        #expect(player.placePlaceBet(number: 2, amount: 50) == false, "Cannot place on 2")
        #expect(player.placePlaceBet(number: 11, amount: 50) == false, "Cannot place on 11")

        #expect(player.bankroll == 1000, "Bankroll should remain unchanged")
        #expect(player.placeBets.isEmpty, "No place bets should be placed")
    }

    @Test func placePlaceBetSucceedsOnValidNumbers() {
        let player = Player(bankroll: 1000)

        #expect(player.placePlaceBet(number: 4, amount: 50) == true, "Can place on 4")
        #expect(player.placePlaceBet(number: 5, amount: 50) == true, "Can place on 5")
        #expect(player.placePlaceBet(number: 6, amount: 50) == true, "Can place on 6")
        #expect(player.placePlaceBet(number: 8, amount: 50) == true, "Can place on 8")
        #expect(player.placePlaceBet(number: 9, amount: 50) == true, "Can place on 9")
        #expect(player.placePlaceBet(number: 10, amount: 50) == true, "Can place on 10")

        #expect(player.placeBets.count == 6, "Should have 6 place bets")
        #expect(player.bankroll == 700, "Bankroll should be reduced by 300")
    }

    @Test func cannotPlaceDuplicatePlaceBet() {
        let player = Player(bankroll: 1000)

        #expect(player.placePlaceBet(number: 6, amount: 60) == true, "First bet succeeds")
        #expect(player.placePlaceBet(number: 6, amount: 60) == false, "Duplicate bet fails")

        #expect(player.placeBets.count == 1, "Should have only one place bet")
        #expect(player.bankroll == 940, "Only first bet deducted")
    }

    @Test func takeDownPlaceBetReturnsAmount() {
        let player = Player(bankroll: 1000)
        player.placePlaceBet(number: 6, amount: 60)
        // Bankroll is now 940

        let returned = player.takeDownPlaceBet(number: 6)

        #expect(returned == 60, "Should return 60")
        #expect(player.bankroll == 1000, "Bankroll should be restored")
        #expect(player.placeBets.isEmpty, "Place bet should be removed")
        #expect(player.hasPlaceBet(on: 6) == false, "No longer has place bet on 6")
    }

    @Test func takeDownNonexistentPlaceBetReturnsZero() {
        let player = Player(bankroll: 1000)

        let returned = player.takeDownPlaceBet(number: 6)

        #expect(returned == 0, "Should return 0 for nonexistent bet")
        #expect(player.bankroll == 1000, "Bankroll unchanged")
    }

    // MARK: - Multiple Bets Tracking

    @Test func multipleBetsCanBeTrackedSimultaneously() {
        let player = Player(bankroll: 1000)

        // Place line bet
        #expect(player.placeBet(type: .pass, amount: 100) == true)

        // Place multiple place bets
        #expect(player.placePlaceBet(number: 6, amount: 60) == true)
        #expect(player.placePlaceBet(number: 8, amount: 60) == true)
        #expect(player.placePlaceBet(number: 5, amount: 50) == true)

        #expect(player.bankroll == 730, "Bankroll should be 1000 - 100 - 60 - 60 - 50")
        #expect(player.currentBet != nil, "Should have line bet")
        #expect(player.placeBets.count == 3, "Should have 3 place bets")
    }

    // MARK: - resolvePlaceBets Tests

    @Test func resolvePlaceBetsWinOnCorrectNumber() {
        let player = Player(bankroll: 1000)
        player.placePlaceBet(number: 6, amount: 60)
        // Bankroll is now 940

        // Roll a 6 (7:6 payout)
        let winnings = player.resolvePlaceBets(rolledNumber: 6, sevenOut: false)

        // Payout: 60 * 7/6 = 70, total return = 60 + 70 = 130
        #expect(winnings == 130, "Should win 130 (bet + payout)")
        #expect(player.bankroll == 1070, "Bankroll should be 940 + 130")
        #expect(player.placeBets.isEmpty, "Winning bet should be removed")
    }

    @Test func resolvePlaceBetsLoseOnSevenOut() {
        let player = Player(bankroll: 1000)
        player.placePlaceBet(number: 6, amount: 60)
        player.placePlaceBet(number: 8, amount: 60)
        player.placePlaceBet(number: 5, amount: 50)
        // Bankroll is now 830

        // Seven out - all place bets lose
        let winnings = player.resolvePlaceBets(rolledNumber: 7, sevenOut: true)

        #expect(winnings == 0, "No winnings on seven out")
        #expect(player.bankroll == 830, "Bankroll unchanged (money already deducted)")
        #expect(player.placeBets.isEmpty, "All place bets should be removed")
    }

    @Test func resolvePlaceBetsNoActionOnNonmatch() {
        let player = Player(bankroll: 1000)
        player.placePlaceBet(number: 6, amount: 60)
        player.placePlaceBet(number: 8, amount: 60)
        // Bankroll is now 880

        // Roll a 4 (no place bet on it)
        let winnings = player.resolvePlaceBets(rolledNumber: 4, sevenOut: false)

        #expect(winnings == 0, "No winnings on non-matching roll")
        #expect(player.bankroll == 880, "Bankroll unchanged")
        #expect(player.placeBets.count == 2, "Place bets remain")
    }

    @Test func clearPlaceBetsReturnsAllMoney() {
        let player = Player(bankroll: 1000)
        player.placePlaceBet(number: 6, amount: 60)
        player.placePlaceBet(number: 8, amount: 60)
        player.placePlaceBet(number: 5, amount: 50)
        // Bankroll is now 830

        player.clearPlaceBets()

        #expect(player.bankroll == 1000, "All place bet money should be returned")
        #expect(player.placeBets.isEmpty, "All place bets should be removed")
    }

    @Test func loseAllPlaceBetsRemovesBetsButNoRefund() {
        let player = Player(bankroll: 1000)
        player.placePlaceBet(number: 6, amount: 60)
        player.placePlaceBet(number: 8, amount: 60)
        // Bankroll is now 880

        player.loseAllPlaceBets()

        #expect(player.bankroll == 880, "No money returned")
        #expect(player.placeBets.isEmpty, "All place bets should be removed")
    }
}
