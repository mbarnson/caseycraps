---
phase: 05-polish
plan: 03
type: summary
status: complete
---

# 05-03 Summary: Place Bets on Point Numbers

## Objective
Add Place bets on point numbers during point phase - core craps feature beyond original scope.

## Completed Tasks

### Task 1: Place Bet Data Model and GameManager Support
- Extended `BetType` enum with `.place(Int)` case
- Added `placeBetPayout(number:betAmount:)` with correct odds:
  - 6 and 8 pay 7:6
  - 5 and 9 pay 7:5
  - 4 and 10 pay 9:5
- Added to Player class:
  - `placeBets: [Bet]` array
  - `placePlaceBet(number:amount:)` - place a bet
  - `resolvePlaceBets(rolledNumber:sevenOut:)` - resolve on hits/seven-out
  - `clearPlaceBets()` - return money on game reset
  - `loseAllPlaceBets()` - lose all on seven-out
  - `hasPlaceBet(on:)` - check if bet exists
  - `takeDownPlaceBet(number:)` - remove bet and return money
- GameManager tracks place bet winnings for UI feedback

### Task 2: Click Detection and Chip Display
- Point number boxes named "placeNumber4" through "placeNumber10"
- Labels share same names for reliable click detection
- Added `handlePlaceBetClick(on:)` with toggle behavior:
  - Click number without bet: place bet
  - Click number with bet: take it down (return money)
- Added `placeChips: [Int: SKNode]` dictionary
- Green chips (vs red for pass line) distinguish place bets

### Task 3: Resolution and UI Updates
- Place bets resolve correctly:
  - Number hit: pay odds, remove chip, show "+$X" animation
  - Seven-out: lose all place bets
  - Point hit (pass line wins): return place bet money
- Hints updated to mention "Click numbers to place bets" during point phase
- `showPlaceBetWinnings(amount:on:)` displays floating animation

## Deviations from Plan
1. **Take-down feature added** - User requested ability to remove place bets
2. **Click detection fix** - Labels needed same names as shapes for reliable clicks
3. **Bet lifecycle clarified** - Place bets return money when pass line wins (point hit)

## Files Modified
- `Models.swift` - BetType enum, placeBetPayout(), Player place bet methods
- `GameManager.swift` - canPlaceBet(), place bet winnings tracking
- `CrapsTableNode.swift` - Node naming for click detection
- `GameScene.swift` - Place bet click handling, chip display, winnings animation

## Verification
- Build succeeds
- Can place bets on numbers during point phase (not on point itself)
- Can take down bets by clicking again
- Place bets pay correct odds when hit
- Place bets lose on seven-out
- Place bets returned when pass line wins
- Chips display correctly on numbers

## Human Verification
Approved - Place bets work correctly with take-down functionality.
