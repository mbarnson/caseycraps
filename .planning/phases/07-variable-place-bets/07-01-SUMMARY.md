# Phase 7 Plan 01: Variable Place Bet Amounts Summary

**Implemented variable place bet amounts allowing players to increase and decrease bets on individual numbers per real craps rules.**

## Accomplishments

- Modified `Player.placePlaceBet()` to allow increasing existing bets (not just placing new ones)
- Added `Player.decreasePlaceBet()` method with tuple return for success/new amount
- Updated `GameManager.canPlaceBet()` to return true for numbers with existing bets
- Added distinct audio feedback: `playBetIncrease()` (ascending) and `playBetDecrease()` (descending)
- Implemented visual feedback for bet changes:
  - Floating "+$X" / "-$X" text with directional indicators (^/v) for color blindness
  - Chip pulse animation on change
  - Reduce Motion compliant (static display when enabled)
- Added VoiceOver announcements for bet changes and removals
- Added right-click and Option+click support for decreasing bets
- Added Delete/Backspace keyboard support for decreasing focused place bet
- Made bet amount buttons visible during point phase for selecting increase/decrease amounts
- Updated keyboard navigation to include bet buttons during point phase

## Files Modified

1. `Casey Craps/Casey Craps/Models.swift`
   - Modified `placePlaceBet()` to increase existing bets
   - Added `decreasePlaceBet()` method

2. `Casey Craps/Casey Craps/SoundManager.swift`
   - Added `playBetIncrease()` method
   - Added `playBetDecrease()` method

3. `Casey Craps/Casey Craps/GameManager.swift`
   - Updated `canPlaceBet()` to allow betting on numbers with existing bets

4. `Casey Craps/Casey Craps/GameScene.swift`
   - Updated `handlePlaceBetClick()` with `isDecrease` parameter
   - Added `rightMouseDown()` handler
   - Added `updatePlaceChip()` for amount changes
   - Added `removePlaceChipAnimated()` for bet removal
   - Added `showBetChangeFeedback()` for visual feedback
   - Added `pulseChip()` helper
   - Added `announceBetChanged()` and `announceBetRemoved()` for VoiceOver
   - Updated `announceFocusChange()` with hints for place numbers
   - Added Delete/Backspace handling in `keyDown()`
   - Updated `updateBetButtonStates()` to show during point phase
   - Updated `getActionableElements()` to include bet buttons during point phase

5. `Casey Craps/Casey CrapsTests/PlayerTests.swift`
   - Replaced `cannotPlaceDuplicatePlaceBet` with `canIncreasePlaceBet`
   - Added `decreasePlaceBetPartially` test
   - Added `decreasePlaceBetToZero` test
   - Added `decreasePlaceBetBeyondAmount` test
   - Added `decreasePlaceBetNonExistent` test

6. `Casey Craps/Casey CrapsTests/GameManagerTests.swift`
   - Replaced `cannotPlaceDuplicatePlaceBet` with `canIncreasePlaceBetOnExistingNumber`

## Accessibility Features (Apple HIG Compliant)

| Feature | Implementation |
|---------|---------------|
| VoiceOver | Announces all bet changes with context |
| Hearing | Visual feedback (floating text, chip pulse) always visible |
| Color Blindness | Directional indicators (^/v) differentiate increase/decrease |
| Reduce Motion | Animations skip, static feedback shown |
| Keyboard | Space increases, Delete decreases bet |

## Interaction Summary

| Input | Action |
|-------|--------|
| Left-click on place number | Add selected bet amount |
| Right-click / Option+click | Decrease by selected bet amount |
| Space/Enter on focused place | Add selected bet amount |
| Delete/Backspace on focused place | Decrease by selected bet amount |

## Test Results

- 103 unit tests passing
- Build succeeds without warnings

## Deviations

- None
