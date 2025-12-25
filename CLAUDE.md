# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Casey Craps is a macOS SpriteKit game that teaches craps through play. It features synthesized audio (no bundled sound files), a realistic casino table aesthetic, and simplified rules (Pass/Don't Pass line bets, Place bets).

## Build Commands

```bash
# Build the project
xcodebuild -project "Casey Craps/Casey Craps.xcodeproj" -scheme "Casey Craps" build

# Run the app (after building)
open ~/Library/Developer/Xcode/DerivedData/Casey_Craps-*/Build/Products/Debug/Casey\ Craps.app
```

## Architecture

### Core Files (in `Casey Craps/Casey Craps/`)

- **GameManager.swift** - Singleton state machine controlling game flow. States: `.waitingForBet`, `.comeOut`, `.point(Int)`, `.resolved(won: Bool)`. Handles all craps rules for Pass/Don't Pass and Place bets.

- **GameScene.swift** - Main SpriteKit scene. Handles all UI: click detection, chip placement, HUD updates, animations. Coordinates between GameManager, visual elements, and sound.

- **Models.swift** - Data models: `Die`, `BetType` enum (`.pass`, `.dontPass`, `.place(Int)`), `Bet`, `Player` class with bankroll and betting methods.

- **CrapsTableNode.swift** - Visual table layout. Named nodes for click detection: `"passLineArea"`, `"dontPassArea"`, `"placeNumber4"` through `"placeNumber10"`. Puck ON/OFF indicator.

- **DieNode.swift** - Dice rendering with dot patterns and roll animation (tumble, wobble, settle).

- **SoundManager.swift** - AVAudioEngine-based synthesized audio. Generates sine waves for all sounds (dice, chips, win/lose fanfares, point established).

### Key Patterns

- **Click detection**: Both shape nodes AND their text labels share the same `name` property so clicks register anywhere in the clickable area.

- **Place bet odds**: 6/8 pay 7:6, 5/9 pay 7:5, 4/10 pay 9:5 (calculated in `placeBetPayout()`).

- **Bet lifecycle**: Money deducted on placement. Place bets returned on game reset (point hit), lost on seven-out.

## Planning Structure

Development plans are in `.planning/` following a phase-based roadmap. Each phase has PLAN.md files (prompts) and SUMMARY.md files (outcomes). See `.planning/ROADMAP.md` for current progress.
