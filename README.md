# Casey Craps

A learn-by-playing craps game for macOS. Built with SpriteKit, featuring synthesized audio and full accessibility support.

## Features

- **Pass Line & Don't Pass betting** - Core craps gameplay with correct rules
- **Place bets** - Bet on point numbers (4, 5, 6, 8, 9, 10) with authentic casino odds
- **Synthesized audio** - All sounds generated via AVAudioEngine (no bundled audio files)
- **Educational hints** - Contextual tips explain what wins/loses in each phase
- **Take-down bets** - Remove Place bets anytime during point phase

### Accessibility

Casey Craps is fully accessible:

- **VoiceOver support** - All game elements announced via NSAccessibilityElement overlay
- **Full keyboard navigation** - Tab between elements, Space/Enter to activate
- **Visual focus indicator** - Clear highlight shows current keyboard focus
- **Hearing accessibility** - Visual feedback (screen flash, symbols) accompanies all audio cues
- **Reduce Motion support** - Respects system preference for reduced animations
- **Color blind friendly** - Win/lose uses shapes (✓/✗) and line styles, not just colors
- **WCAG contrast compliance** - All text meets 3:1+ contrast ratios

## Requirements

- macOS 14.0+ (Sonoma)
- Xcode 15+

## Building

```bash
# Clone the repository
git clone https://github.com/mbarnson/caseycraps.git
cd caseycraps

# Build
xcodebuild -project "Casey Craps/Casey Craps.xcodeproj" -scheme "Casey Craps" build

# Run (after building)
open ~/Library/Developer/Xcode/DerivedData/Casey_Craps-*/Build/Products/Debug/Casey\ Craps.app
```

Or open `Casey Craps/Casey Craps.xcodeproj` in Xcode and press ⌘R.

## How to Play

1. **Select bet amount** - Click $25, $50, $100, or $500
2. **Place your bet** - Click PASS LINE or DON'T PASS
3. **Roll the dice** - Click the dice to roll

### Come-Out Roll (first roll)
- **Pass Line**: 7 or 11 wins, 2/3/12 loses, other numbers set the point
- **Don't Pass**: 2 or 3 wins, 7/11 loses, 12 pushes, other numbers set the point

### Point Phase (after point is set)
- **Pass Line**: Roll the point to win, 7 loses (seven-out)
- **Don't Pass**: 7 wins, rolling the point loses
- **Place bets**: Click point numbers to bet on them (pays when that number rolls)

## Tests

```bash
xcodebuild test -project "Casey Craps/Casey Craps.xcodeproj" \
  -scheme "Casey Craps" \
  -destination 'platform=macOS' \
  -only-testing:"Casey CrapsTests"
```

99 unit tests covering game logic, models, and sound parameters.

## License

This is free and unencumbered software released into the public domain. See [LICENSE](LICENSE) for details.

Do whatever you want with it.
