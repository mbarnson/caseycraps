# Roadmap: Casey Craps

## Overview

Build a learn-by-playing craps game for macOS. Start with clean architecture, add the visual table and dice physics, implement simplified craps rules (Pass/Don't Pass), layer in synthesized audio feedback, then polish the experience with a proper HUD and subtle teaching moments.

## Phases

- [x] **Phase 1: Foundation** - Clean game architecture replacing template code
- [x] **Phase 2: Table & Dice** - Realistic table layout and physics-based dice
- [x] **Phase 3: Game Logic** - Pass line betting with come-out and point phases
- [x] **Phase 4: Audio** - Synthesized sounds for all game events
- [x] **Phase 5: Polish** - HUD, bet UI, visual feedback, educational cues, Place bets
- [ ] **Phase 6: Testing & Accessibility** - Unit tests, VoiceOver, hearing accessibility, Reduce Motion

## Phase Details

### Phase 1: Foundation
**Goal**: Replace SpriteKit boilerplate with clean game architecture
**Depends on**: Nothing (first phase)
**Plans**: 2 plans

Plans:
- [x] 01-01: GameManager singleton and game state enum
- [x] 01-02: Scene setup with proper coordinate system and scaling

### Phase 2: Table & Dice
**Goal**: Visual craps table and satisfying dice rolling
**Depends on**: Phase 1
**Plans**: 2 plans

Plans:
- [x] 02-01: Craps table layout with felt texture and betting areas
- [x] 02-02: Dice sprites with physics-based rolling animation

### Phase 3: Game Logic
**Goal**: Playable Pass/Don't Pass with correct craps rules
**Depends on**: Phase 2
**Plans**: 3 plans

Plans:
- [x] 03-01: Betting system (bankroll, chip placement, bet tracking)
- [x] 03-02: Come-out roll logic (7/11 wins, 2/3/12 loses, point established)
- [x] 03-03: Point phase logic (hit point wins, 7 loses)

### Phase 4: Audio
**Goal**: Synthesized sounds that bring the table to life
**Depends on**: Phase 3
**Plans**: 2 plans

Plans:
- [x] 04-01: Core sounds (dice tumbling, chip clicks, button feedback)
- [x] 04-02: Event sounds (wins, losses, crowd reactions, point established)

### Phase 5: Polish
**Goal**: Refined experience with teaching moments
**Depends on**: Phase 4
**Plans**: 3 plans

Plans:
- [x] 05-01: HUD (bankroll display, current bet, point marker, game state)
- [x] 05-02: Visual feedback and subtle educational hints
- [x] 05-03: Place bets on point numbers (bonus feature)

### Phase 6: Testing & Accessibility
**Goal**: Comprehensive testing and Apple Accessibility compliance
**Depends on**: Phase 5
**Plans**: 4 plans

Plans:
- [x] 06-01: Test infrastructure and GameManager unit tests
- [x] 06-02: Models and SoundManager tests
- [ ] 06-03: VoiceOver accessibility for all interactive elements
- [ ] 06-04: Hearing accessibility and Reduce Motion support

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 2/2 | Complete | 2025-12-24 |
| 2. Table & Dice | 2/2 | Complete | 2025-12-24 |
| 3. Game Logic | 3/3 | Complete | 2025-12-24 |
| 4. Audio | 2/2 | Complete | 2025-12-24 |
| 5. Polish | 3/3 | Complete | 2025-12-25 |
| 6. Testing & Accessibility | 2/4 | In Progress | - |

## v1.0 Complete

Casey Craps is a fully functional craps game with:
- Pass Line and Don't Pass betting
- Place bets on point numbers with correct odds
- Synthesized audio feedback
- Educational hints and roll result callouts
- Take-down functionality for Place bets
