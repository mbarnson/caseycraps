//
//  BetTests.swift
//  Casey CrapsTests
//
//  Created by Claude on 12/25/25.
//

import Testing
@testable import Casey_Craps

/// Comprehensive tests for Bet struct and BetType enum
@Suite
struct BetTests {

    // MARK: - BetType Tests

    @Test func betTypePassExists() {
        let betType = BetType.pass
        #expect(betType == .pass, "BetType.pass should exist")
    }

    @Test func betTypeDontPassExists() {
        let betType = BetType.dontPass
        #expect(betType == .dontPass, "BetType.dontPass should exist")
    }

    @Test func betTypePlaceWithNumber() {
        let betType = BetType.place(6)
        #expect(betType == .place(6), "BetType.place(6) should exist")
    }

    @Test func betTypeEquality() {
        #expect(BetType.pass == BetType.pass, "Pass should equal pass")
        #expect(BetType.dontPass == BetType.dontPass, "Don't pass should equal don't pass")
        #expect(BetType.place(6) == BetType.place(6), "Place(6) should equal place(6)")
        #expect(BetType.place(6) != BetType.place(8), "Place(6) should not equal place(8)")
        #expect(BetType.pass != BetType.dontPass, "Pass should not equal don't pass")
    }

    // MARK: - Bet Creation Tests

    @Test func betCreationWithPassType() {
        let bet = Bet(type: .pass, amount: 100)
        #expect(bet.type == .pass, "Bet type should be .pass")
        #expect(bet.amount == 100, "Bet amount should be 100")
    }

    @Test func betCreationWithDontPassType() {
        let bet = Bet(type: .dontPass, amount: 50)
        #expect(bet.type == .dontPass, "Bet type should be .dontPass")
        #expect(bet.amount == 50, "Bet amount should be 50")
    }

    @Test func betCreationWithPlaceType() {
        let bet = Bet(type: .place(8), amount: 60)
        #expect(bet.type == .place(8), "Bet type should be .place(8)")
        #expect(bet.amount == 60, "Bet amount should be 60")
    }

    // MARK: - Place Bet Payout Calculation Tests

    @Test func placeBetPayout6Pays7to6() {
        // 6 and 8 pay 7:6 odds
        // Bet $6, win $7 (plus original $6 back)
        // Bet $12, win $14 (plus original $12 back)
        let payout1 = placeBetPayout(number: 6, betAmount: 6)
        let payout2 = placeBetPayout(number: 6, betAmount: 12)
        let payout3 = placeBetPayout(number: 6, betAmount: 60)

        #expect(payout1 == 7, "6 bet should pay 7")
        #expect(payout2 == 14, "12 bet should pay 14")
        #expect(payout3 == 70, "60 bet should pay 70")
    }

    @Test func placeBetPayout8Pays7to6() {
        // 8 pays same as 6 (7:6)
        let payout1 = placeBetPayout(number: 8, betAmount: 6)
        let payout2 = placeBetPayout(number: 8, betAmount: 12)
        let payout3 = placeBetPayout(number: 8, betAmount: 60)

        #expect(payout1 == 7, "6 bet should pay 7")
        #expect(payout2 == 14, "12 bet should pay 14")
        #expect(payout3 == 70, "60 bet should pay 70")
    }

    @Test func placeBetPayout5Pays7to5() {
        // 5 and 9 pay 7:5 odds
        // Bet $5, win $7 (plus original $5 back)
        // Bet $10, win $14 (plus original $10 back)
        let payout1 = placeBetPayout(number: 5, betAmount: 5)
        let payout2 = placeBetPayout(number: 5, betAmount: 10)
        let payout3 = placeBetPayout(number: 5, betAmount: 50)

        #expect(payout1 == 7, "5 bet should pay 7")
        #expect(payout2 == 14, "10 bet should pay 14")
        #expect(payout3 == 70, "50 bet should pay 70")
    }

    @Test func placeBetPayout9Pays7to5() {
        // 9 pays same as 5 (7:5)
        let payout1 = placeBetPayout(number: 9, betAmount: 5)
        let payout2 = placeBetPayout(number: 9, betAmount: 10)
        let payout3 = placeBetPayout(number: 9, betAmount: 50)

        #expect(payout1 == 7, "5 bet should pay 7")
        #expect(payout2 == 14, "10 bet should pay 14")
        #expect(payout3 == 70, "50 bet should pay 70")
    }

    @Test func placeBetPayout4Pays9to5() {
        // 4 and 10 pay 9:5 odds
        // Bet $5, win $9 (plus original $5 back)
        // Bet $10, win $18 (plus original $10 back)
        let payout1 = placeBetPayout(number: 4, betAmount: 5)
        let payout2 = placeBetPayout(number: 4, betAmount: 10)
        let payout3 = placeBetPayout(number: 4, betAmount: 50)

        #expect(payout1 == 9, "5 bet should pay 9")
        #expect(payout2 == 18, "10 bet should pay 18")
        #expect(payout3 == 90, "50 bet should pay 90")
    }

    @Test func placeBetPayout10Pays9to5() {
        // 10 pays same as 4 (9:5)
        let payout1 = placeBetPayout(number: 10, betAmount: 5)
        let payout2 = placeBetPayout(number: 10, betAmount: 10)
        let payout3 = placeBetPayout(number: 10, betAmount: 50)

        #expect(payout1 == 9, "5 bet should pay 9")
        #expect(payout2 == 18, "10 bet should pay 18")
        #expect(payout3 == 90, "50 bet should pay 90")
    }

    @Test func placeBetPayoutInvalidNumberReturnsZero() {
        // Invalid numbers should return 0
        #expect(placeBetPayout(number: 2, betAmount: 10) == 0, "Invalid number 2 should return 0")
        #expect(placeBetPayout(number: 3, betAmount: 10) == 0, "Invalid number 3 should return 0")
        #expect(placeBetPayout(number: 7, betAmount: 10) == 0, "Invalid number 7 should return 0")
        #expect(placeBetPayout(number: 11, betAmount: 10) == 0, "Invalid number 11 should return 0")
        #expect(placeBetPayout(number: 12, betAmount: 10) == 0, "Invalid number 12 should return 0")
    }

    // MARK: - Fractional Payout Rounding Tests

    @Test func placeBetPayoutRoundsCorrectly() {
        // Test rounding for non-standard bet amounts
        // 6/8 at 7:6 odds
        let payout68_1 = placeBetPayout(number: 6, betAmount: 7)  // 7 * 7/6 = 8.17 -> should round to 8
        #expect(payout68_1 == 8, "7 bet on 6 should round to 8")

        let payout68_2 = placeBetPayout(number: 8, betAmount: 13) // 13 * 7/6 = 15.17 -> should round to 15
        #expect(payout68_2 == 15, "13 bet on 8 should round to 15")

        // 5/9 at 7:5 odds
        let payout59_1 = placeBetPayout(number: 5, betAmount: 7)  // 7 * 7/5 = 9.8 -> should round to 10
        #expect(payout59_1 == 10, "7 bet on 5 should round to 10")

        let payout59_2 = placeBetPayout(number: 9, betAmount: 13) // 13 * 7/5 = 18.2 -> should round to 18
        #expect(payout59_2 == 18, "13 bet on 9 should round to 18")

        // 4/10 at 9:5 odds
        let payout410_1 = placeBetPayout(number: 4, betAmount: 7)  // 7 * 9/5 = 12.6 -> should round to 13
        #expect(payout410_1 == 13, "7 bet on 4 should round to 13")

        let payout410_2 = placeBetPayout(number: 10, betAmount: 13) // 13 * 9/5 = 23.4 -> should round to 23
        #expect(payout410_2 == 23, "13 bet on 10 should round to 23")
    }

    // MARK: - Casino Rules Verification

    @Test func verifyCasinoOddsFor6and8() {
        // Standard casino bet: $12 on 6 or 8 pays $14
        let payout = placeBetPayout(number: 6, betAmount: 12)
        #expect(payout == 14, "Standard $12 bet on 6 should pay $14 (casino rule)")

        let payout2 = placeBetPayout(number: 8, betAmount: 12)
        #expect(payout2 == 14, "Standard $12 bet on 8 should pay $14 (casino rule)")
    }

    @Test func verifyCasinoOddsFor5and9() {
        // Standard casino bet: $10 on 5 or 9 pays $14
        let payout = placeBetPayout(number: 5, betAmount: 10)
        #expect(payout == 14, "Standard $10 bet on 5 should pay $14 (casino rule)")

        let payout2 = placeBetPayout(number: 9, betAmount: 10)
        #expect(payout2 == 14, "Standard $10 bet on 9 should pay $14 (casino rule)")
    }

    @Test func verifyCasinoOddsFor4and10() {
        // Standard casino bet: $10 on 4 or 10 pays $18
        let payout = placeBetPayout(number: 4, betAmount: 10)
        #expect(payout == 18, "Standard $10 bet on 4 should pay $18 (casino rule)")

        let payout2 = placeBetPayout(number: 10, betAmount: 10)
        #expect(payout2 == 18, "Standard $10 bet on 10 should pay $18 (casino rule)")
    }
}
