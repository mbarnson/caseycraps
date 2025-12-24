# Roadmap: Casey Craps

## Overview

Build a learn-by-playing craps game for macOS. Start with clean architecture, add the visual table and dice physics, implement simplified craps rules (Pass/Don't Pass), layer in synthesized audio feedback, then polish the experience with a proper HUD and subtle teaching moments.

## Phases

- [x] **Phase 1: Foundation** - Clean game architecture replacing template code
- [ ] **Phase 2: Table & Dice** - Realistic table layout and physics-based dice
- [ ] **Phase 3: Game Logic** - Pass line betting with come-out and point phases
- [ ] **Phase 4: Audio** - Synthesized sounds for all game events
- [ ] **Phase 5: Polish** - HUD, bet UI, visual feedback, educational cues

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
- [ ] 02-01: Craps table layout with felt texture and betting areas
- [ ] 02-02: Dice sprites with physics-based rolling animation

### Phase 3: Game Logic
**Goal**: Playable Pass/Don't Pass with correct craps rules
**Depends on**: Phase 2
**Plans**: 3 plans

Plans:
- [ ] 03-01: Betting system (bankroll, chip placement, bet tracking)
- [ ] 03-02: Come-out roll logic (7/11 wins, 2/3/12 loses, point established)
- [ ] 03-03: Point phase logic (hit point wins, 7 loses)

### Phase 4: Audio
**Goal**: Synthesized sounds that bring the table to life
**Depends on**: Phase 3
**Plans**: 2 plans

Plans:
- [ ] 04-01: Core sounds (dice tumbling, chip clicks, button feedback)
- [ ] 04-02: Event sounds (wins, losses, crowd reactions, point established)

### Phase 5: Polish
**Goal**: Refined experience with teaching moments
**Depends on**: Phase 4
**Plans**: 2 plans

Plans:
- [ ] 05-01: HUD (bankroll display, current bet, point marker, game state)
- [ ] 05-02: Visual feedback and subtle educational hints

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 2/2 | Complete | 2025-12-24 |
| 2. Table & Dice | 0/2 | Not started | - |
| 3. Game Logic | 0/3 | Not started | - |
| 4. Audio | 0/2 | Not started | - |
| 5. Polish | 0/2 | Not started | - |
