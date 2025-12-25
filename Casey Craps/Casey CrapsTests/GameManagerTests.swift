//
//  GameManagerTests.swift
//  Casey CrapsTests
//
//  Created by Claude on 12/25/25.
//

import Testing
@testable import Casey_Craps

/// Comprehensive tests for GameManager state machine and betting logic
@Suite(.serialized)
struct GameManagerTests {

    // Helper to reset game state before each test
    func resetGame() -> (GameManager, Player) {
        let gameManager = GameManager.shared
        let player = gameManager.player
        gameManager.reset()
        player.bankroll = 1000
        player.currentBet = nil
        player.placeBets = []
        return (gameManager, player)
    }

    // MARK: - Initial State Tests

    @Test func initialStateIsWaitingForBet() {
        let (gameManager, _) = resetGame()
        #expect(gameManager.state == .waitingForBet, "Initial state should be waitingForBet")
        #expect(gameManager.pointValue == nil, "Point value should be nil initially")
    }

    // MARK: - State Transition Tests

    @Test func transitionToComeOutWhenBetPlaced() {
        let (gameManager, player) = resetGame()
        // Place a Pass line bet
        #expect(player.placeBet(type: .pass, amount: 100))

        // Transition to come-out
        gameManager.placeBet()

        #expect(gameManager.state == .comeOut, "State should transition to comeOut after placing bet")
    }

    @Test func cannotPlaceBetInWrongState() {
        let (gameManager, player) = resetGame()
        // Place a bet and transition to come-out
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()
        #expect(gameManager.state == .comeOut)

        // Try to place bet again
        let originalState = gameManager.state
        gameManager.placeBet()

        // State should not change
        #expect(gameManager.state == originalState, "Should not transition from comeOut state")
    }

    // MARK: - Come-Out Roll Tests - Pass Line

    @Test func passLineWinsOnNatural7() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        let initialBankroll = player.bankroll
        gameManager.roll(die1: 3, die2: 4) // Total 7

        #expect(gameManager.state == .resolved(won: true), "Should resolve as won on natural 7")
        #expect(player.bankroll == initialBankroll + 200, "Should win 2x bet amount")
        #expect(player.currentBet == nil, "Bet should be cleared after resolution")
    }

    @Test func passLineWinsOnNatural11() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        let initialBankroll = player.bankroll
        gameManager.roll(die1: 5, die2: 6) // Total 11

        #expect(gameManager.state == .resolved(won: true), "Should resolve as won on natural 11")
        #expect(player.bankroll == initialBankroll + 200, "Should win 2x bet amount")
    }

    @Test func passLineLosesOnCraps2() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        let initialBankroll = player.bankroll
        gameManager.roll(die1: 1, die2: 1) // Total 2

        #expect(gameManager.state == .resolved(won: false), "Should resolve as lost on craps 2")
        #expect(player.bankroll == initialBankroll, "Should not win any money")
        #expect(player.currentBet == nil, "Bet should be cleared after resolution")
    }

    @Test func passLineLosesOnCraps3() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        gameManager.roll(die1: 1, die2: 2) // Total 3

        #expect(gameManager.state == .resolved(won: false), "Should resolve as lost on craps 3")
    }

    @Test func passLineLosesOnCraps12() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        gameManager.roll(die1: 6, die2: 6) // Total 12

        #expect(gameManager.state == .resolved(won: false), "Should resolve as lost on craps 12")
    }

    @Test func passLineEstablishesPoint4() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        gameManager.roll(die1: 2, die2: 2) // Total 4

        #expect(gameManager.state == .point(4), "Should establish point at 4")
        #expect(gameManager.pointValue == 4, "Point value should be set to 4")
        #expect(player.currentBet != nil, "Bet should remain active in point phase")
    }

    @Test func passLineEstablishesPoint5() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        gameManager.roll(die1: 2, die2: 3) // Total 5

        #expect(gameManager.state == .point(5), "Should establish point at 5")
        #expect(gameManager.pointValue == 5)
    }

    @Test func passLineEstablishesPoint6() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        gameManager.roll(die1: 3, die2: 3) // Total 6

        #expect(gameManager.state == .point(6), "Should establish point at 6")
        #expect(gameManager.pointValue == 6)
    }

    @Test func passLineEstablishesPoint8() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        gameManager.roll(die1: 4, die2: 4) // Total 8

        #expect(gameManager.state == .point(8), "Should establish point at 8")
        #expect(gameManager.pointValue == 8)
    }

    @Test func passLineEstablishesPoint9() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        gameManager.roll(die1: 4, die2: 5) // Total 9

        #expect(gameManager.state == .point(9), "Should establish point at 9")
        #expect(gameManager.pointValue == 9)
    }

    @Test func passLineEstablishesPoint10() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        gameManager.roll(die1: 5, die2: 5) // Total 10

        #expect(gameManager.state == .point(10), "Should establish point at 10")
        #expect(gameManager.pointValue == 10)
    }

    // MARK: - Come-Out Roll Tests - Don't Pass

    @Test func dontPassLosesOnNatural7() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .dontPass, amount: 100)
        gameManager.placeBet()

        let initialBankroll = player.bankroll
        gameManager.roll(die1: 3, die2: 4) // Total 7

        #expect(gameManager.state == .resolved(won: false), "Should resolve as lost on natural 7")
        #expect(player.bankroll == initialBankroll, "Should not win any money")
    }

    @Test func dontPassLosesOnNatural11() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .dontPass, amount: 100)
        gameManager.placeBet()

        gameManager.roll(die1: 5, die2: 6) // Total 11

        #expect(gameManager.state == .resolved(won: false), "Should resolve as lost on natural 11")
    }

    @Test func dontPassWinsOnCraps2() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .dontPass, amount: 100)
        gameManager.placeBet()

        let initialBankroll = player.bankroll
        gameManager.roll(die1: 1, die2: 1) // Total 2

        #expect(gameManager.state == .resolved(won: true), "Should resolve as won on craps 2")
        #expect(player.bankroll == initialBankroll + 200, "Should win 2x bet amount")
    }

    @Test func dontPassWinsOnCraps3() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .dontPass, amount: 100)
        gameManager.placeBet()

        let initialBankroll = player.bankroll
        gameManager.roll(die1: 1, die2: 2) // Total 3

        #expect(gameManager.state == .resolved(won: true), "Should resolve as won on craps 3")
        #expect(player.bankroll == initialBankroll + 200, "Should win 2x bet amount")
    }

    @Test func dontPassPushesOnBar12() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .dontPass, amount: 100)
        gameManager.placeBet()

        let initialBankroll = player.bankroll
        gameManager.roll(die1: 6, die2: 6) // Total 12

        #expect(gameManager.state == .resolved(won: false), "Should resolve (but as push)")
        #expect(player.bankroll == initialBankroll + 100, "Should push - return original bet")
    }

    @Test func dontPassEstablishesPoint() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .dontPass, amount: 100)
        gameManager.placeBet()

        gameManager.roll(die1: 2, die2: 2) // Total 4

        #expect(gameManager.state == .point(4), "Should establish point at 4")
        #expect(gameManager.pointValue == 4)
    }

    // MARK: - Point Phase Tests - Pass Line

    @Test func passLineWinsWhenPointHit() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        // Establish point at 6
        gameManager.roll(die1: 3, die2: 3) // Total 6
        #expect(gameManager.state == .point(6))

        let initialBankroll = player.bankroll

        // Hit the point
        gameManager.roll(die1: 2, die2: 4) // Total 6

        #expect(gameManager.state == .resolved(won: true), "Should win when point is hit")
        #expect(player.bankroll == initialBankroll + 200, "Should win 2x bet amount")
        #expect(gameManager.pointValue == nil, "Point value should be cleared")
    }

    @Test func passLineLosesOnSevenOut() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        // Establish point at 8
        gameManager.roll(die1: 4, die2: 4) // Total 8
        #expect(gameManager.state == .point(8))

        let initialBankroll = player.bankroll

        // Seven out
        gameManager.roll(die1: 3, die2: 4) // Total 7

        #expect(gameManager.state == .resolved(won: false), "Should lose on seven out")
        #expect(player.bankroll == initialBankroll, "Should not win any money")
        #expect(gameManager.pointValue == nil, "Point value should be cleared")
    }

    @Test func passLineStaysInPointPhaseOnOtherRolls() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        // Establish point at 5
        gameManager.roll(die1: 2, die2: 3) // Total 5
        #expect(gameManager.state == .point(5))

        // Roll other numbers
        gameManager.roll(die1: 2, die2: 2) // Total 4
        #expect(gameManager.state == .point(5), "Should stay in point phase")

        gameManager.roll(die1: 3, die2: 3) // Total 6
        #expect(gameManager.state == .point(5), "Should stay in point phase")

        gameManager.roll(die1: 4, die2: 4) // Total 8
        #expect(gameManager.state == .point(5), "Should stay in point phase")
    }

    // MARK: - Point Phase Tests - Don't Pass

    @Test func dontPassLosesWhenPointHit() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .dontPass, amount: 100)
        gameManager.placeBet()

        // Establish point at 6
        gameManager.roll(die1: 3, die2: 3) // Total 6
        #expect(gameManager.state == .point(6))

        let initialBankroll = player.bankroll

        // Hit the point
        gameManager.roll(die1: 2, die2: 4) // Total 6

        #expect(gameManager.state == .resolved(won: false), "Should lose when point is hit")
        #expect(player.bankroll == initialBankroll, "Should not win any money")
    }

    @Test func dontPassWinsOnSevenOut() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .dontPass, amount: 100)
        gameManager.placeBet()

        // Establish point at 8
        gameManager.roll(die1: 4, die2: 4) // Total 8
        #expect(gameManager.state == .point(8))

        let initialBankroll = player.bankroll

        // Seven out
        gameManager.roll(die1: 3, die2: 4) // Total 7

        #expect(gameManager.state == .resolved(won: true), "Should win on seven out")
        #expect(player.bankroll == initialBankroll + 200, "Should win 2x bet amount")
    }

    // MARK: - Place Bet Payout Tests

    @Test func placeBetPayout6Pays7to6() {
        let betAmount = 60
        let payout = placeBetPayout(number: 6, betAmount: betAmount)
        // 7:6 odds - bet $60, win $70
        #expect(payout == 70, "Place bet on 6 should pay 7:6 (60 * 7/6 = 70)")
    }

    @Test func placeBetPayout8Pays7to6() {
        let betAmount = 60
        let payout = placeBetPayout(number: 8, betAmount: betAmount)
        #expect(payout == 70, "Place bet on 8 should pay 7:6")
    }

    @Test func placeBetPayout5Pays7to5() {
        let betAmount = 50
        let payout = placeBetPayout(number: 5, betAmount: betAmount)
        // 7:5 odds - bet $50, win $70
        #expect(payout == 70, "Place bet on 5 should pay 7:5 (50 * 7/5 = 70)")
    }

    @Test func placeBetPayout9Pays7to5() {
        let betAmount = 50
        let payout = placeBetPayout(number: 9, betAmount: betAmount)
        #expect(payout == 70, "Place bet on 9 should pay 7:5")
    }

    @Test func placeBetPayout4Pays9to5() {
        let betAmount = 50
        let payout = placeBetPayout(number: 4, betAmount: betAmount)
        // 9:5 odds - bet $50, win $90
        #expect(payout == 90, "Place bet on 4 should pay 9:5 (50 * 9/5 = 90)")
    }

    @Test func placeBetPayout10Pays9to5() {
        let betAmount = 50
        let payout = placeBetPayout(number: 10, betAmount: betAmount)
        #expect(payout == 90, "Place bet on 10 should pay 9:5")
    }

    // MARK: - Place Bet Integration Tests

    @Test func placeBetWinsWhenNumberRolled() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        // Establish point at 5
        gameManager.roll(die1: 2, die2: 3) // Total 5
        #expect(gameManager.state == .point(5))

        // Place bet on 6
        player.placePlaceBet(number: 6, amount: 60)
        let bankrollAfterPlaceBet = player.bankroll

        // Roll 6
        gameManager.roll(die1: 3, die2: 3) // Total 6

        // Should stay in point phase
        #expect(gameManager.state == .point(5))

        // Place bet should win: return $60 + win $70 = $130
        #expect(player.bankroll == bankrollAfterPlaceBet + 130, "Should win place bet")
        #expect(gameManager.lastPlaceBetWinnings == 130, "Should track winnings")
        #expect(gameManager.lastPlaceBetWinningNumber == 6, "Should track winning number")
    }

    @Test func placeBetsLoseOnSevenOut() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        // Establish point at 5
        gameManager.roll(die1: 2, die2: 3) // Total 5
        #expect(gameManager.state == .point(5))

        // Place bets on multiple numbers
        player.placePlaceBet(number: 6, amount: 60)
        player.placePlaceBet(number: 8, amount: 60)
        player.placePlaceBet(number: 9, amount: 50)

        let bankrollAfterPlaceBets = player.bankroll

        // Seven out
        gameManager.roll(die1: 3, die2: 4) // Total 7

        #expect(gameManager.state == .resolved(won: false), "Should resolve as lost")
        #expect(player.bankroll == bankrollAfterPlaceBets, "Place bets should be lost (not returned)")
        #expect(player.placeBets.count == 0, "All place bets should be removed")
    }

    @Test func placeBetsReturnedOnPointHit() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        // Establish point at 5
        gameManager.roll(die1: 2, die2: 3) // Total 5
        #expect(gameManager.state == .point(5))

        // Place bets on multiple numbers
        player.placePlaceBet(number: 6, amount: 60)
        player.placePlaceBet(number: 8, amount: 60)

        // Hit the point
        gameManager.roll(die1: 2, die2: 3) // Total 5

        #expect(gameManager.state == .resolved(won: true), "Should win")

        // Reset should return place bets
        gameManager.reset()

        // Place bets should have been returned
        #expect(player.placeBets.count == 0, "Place bets should be cleared")
    }

    @Test func cannotPlaceBetOnPointNumber() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        // Establish point at 6
        gameManager.roll(die1: 3, die2: 3) // Total 6
        #expect(gameManager.state == .point(6))

        // Try to place bet on the point number
        #expect(gameManager.canPlaceBet(on: 6) == false, "Cannot place bet on current point")

        // Can place on other numbers
        #expect(gameManager.canPlaceBet(on: 5) == true, "Can place bet on non-point numbers")
        #expect(gameManager.canPlaceBet(on: 8) == true, "Can place bet on non-point numbers")
    }

    @Test func cannotPlaceBetDuringComeOut() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        #expect(gameManager.state == .comeOut)

        // Cannot place bet during come-out
        #expect(gameManager.canPlaceBet(on: 6) == false, "Cannot place bet during come-out")
        #expect(gameManager.canPlaceBet(on: 8) == false, "Cannot place bet during come-out")
    }

    @Test func cannotPlaceBetOnInvalidNumbers() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        // Establish point
        gameManager.roll(die1: 2, die2: 3) // Total 5
        #expect(gameManager.state == .point(5))

        // Invalid numbers
        #expect(gameManager.canPlaceBet(on: 2) == false, "Cannot place bet on 2")
        #expect(gameManager.canPlaceBet(on: 3) == false, "Cannot place bet on 3")
        #expect(gameManager.canPlaceBet(on: 7) == false, "Cannot place bet on 7")
        #expect(gameManager.canPlaceBet(on: 11) == false, "Cannot place bet on 11")
        #expect(gameManager.canPlaceBet(on: 12) == false, "Cannot place bet on 12")
    }

    @Test func cannotPlaceDuplicatePlaceBet() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        // Establish point
        gameManager.roll(die1: 2, die2: 3) // Total 5
        #expect(gameManager.state == .point(5))

        // Place bet on 6
        #expect(player.placePlaceBet(number: 6, amount: 60))

        // Try to place another bet on 6
        #expect(gameManager.canPlaceBet(on: 6) == false, "Cannot place duplicate bet on same number")
    }

    // MARK: - Pass/Don't Pass Payout Tests

    @Test func passLinePayout1to1() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        let initialBankroll = player.bankroll
        gameManager.roll(die1: 3, die2: 4) // Natural 7

        // 1:1 payout means return original $100 + win $100 = $200
        #expect(player.bankroll == initialBankroll + 200, "Pass line should pay 1:1")
    }

    @Test func dontPassPayout1to1() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .dontPass, amount: 100)
        gameManager.placeBet()

        let initialBankroll = player.bankroll
        gameManager.roll(die1: 1, die2: 1) // Craps 2

        // 1:1 payout
        #expect(player.bankroll == initialBankroll + 200, "Don't Pass should pay 1:1")
    }

    // MARK: - Reset Tests

    @Test func resetClearsState() {
        let (gameManager, player) = resetGame()
        player.placeBet(type: .pass, amount: 100)
        gameManager.placeBet()

        // Establish point
        gameManager.roll(die1: 3, die2: 3) // Total 6

        // Add place bets
        player.placePlaceBet(number: 8, amount: 60)

        let bankrollBeforeReset = player.bankroll

        // Reset
        gameManager.reset()

        #expect(gameManager.state == .waitingForBet, "Should reset to waitingForBet")
        #expect(gameManager.pointValue == nil, "Point value should be cleared")
        #expect(player.placeBets.count == 0, "Place bets should be cleared")
        #expect(player.bankroll > bankrollBeforeReset, "Place bets should be returned")
    }
}
