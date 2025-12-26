//
//  GameScene.swift
//  Casey Craps
//
//  Created by Matthew Barnson on 12/24/25.
//

import SpriteKit
import GameplayKit
import AppKit

class GameScene: SKScene {

    private let gameManager = GameManager.shared
    private var crapsTable: CrapsTableNode?
    private var die1: DieNode!
    private var die2: DieNode!
    private var isRolling: Bool = false
    private var bankrollLabel: SKLabelNode!
    private var betChip: SKNode?
    private var outcomeLabel: SKLabelNode?
    private var gameStateBanner: SKLabelNode!
    private var hintLabel: SKLabelNode!
    private var rollResultLabel: SKLabelNode!
    private var selectedBetAmount: Int = 100
    private var betButtons: [SKNode] = []
    private var placeChips: [Int: SKNode] = [:]  // Track chips on place bet numbers
    private var accessibilityManager: GameAccessibilityManager?
    private var gameContainer: SKNode!  // Container for table + dice (scales together)

    // MARK: - Keyboard Navigation

    enum FocusableElement: CaseIterable {
        case dice
        case passLine
        case dontPass
        case point4, point5, point6, point8, point9, point10
        case bet25, bet50, bet100, bet500

        var pointNumber: Int? {
            switch self {
            case .point4: return 4
            case .point5: return 5
            case .point6: return 6
            case .point8: return 8
            case .point9: return 9
            case .point10: return 10
            default: return nil
            }
        }

        var betAmount: Int? {
            switch self {
            case .bet25: return 25
            case .bet50: return 50
            case .bet100: return 100
            case .bet500: return 500
            default: return nil
            }
        }

        static func fromPointNumber(_ number: Int) -> FocusableElement? {
            switch number {
            case 4: return .point4
            case 5: return .point5
            case 6: return .point6
            case 8: return .point8
            case 9: return .point9
            case 10: return .point10
            default: return nil
            }
        }

        static func fromBetAmount(_ amount: Int) -> FocusableElement? {
            switch amount {
            case 25: return .bet25
            case 50: return .bet50
            case 100: return .bet100
            case 500: return .bet500
            default: return nil
            }
        }
    }

    private var currentFocus: FocusableElement?
    private var focusRing: SKShapeNode?

    override func didMove(to view: SKView) {
        // Remove template nodes from .sks file
        childNode(withName: "//helloLabel")?.removeFromParent()

        // Set casino felt background color
        backgroundColor = SKColor(red: 0.05, green: 0.36, blue: 0.05, alpha: 1.0)

        // Print current game state
        print("Game State: \(gameManager.state)")

        // Create game container (table + dice scale together)
        gameContainer = SKNode()
        gameContainer.position = CGPoint(x: 0, y: 0)
        addChild(gameContainer)

        // Add craps table to container
        let table = CrapsTableNode()
        table.position = CGPoint(x: 0, y: 0)
        gameContainer.addChild(table)
        crapsTable = table

        // Add dice to container (below point numbers, above pass line)
        die1 = DieNode()
        die1.position = CGPoint(x: -50, y: 20)
        gameContainer.addChild(die1)

        die2 = DieNode()
        die2.position = CGPoint(x: 50, y: 20)
        gameContainer.addChild(die2)

        // Add bankroll display at bottom center (where Roll Dice used to be)
        bankrollLabel = SKLabelNode(text: "Bankroll: $1,000")
        bankrollLabel.fontSize = 32
        bankrollLabel.fontName = "Arial-BoldMT"
        bankrollLabel.fontColor = .white
        bankrollLabel.horizontalAlignmentMode = .center
        bankrollLabel.position = CGPoint(x: 0, y: -350)
        addChild(bankrollLabel)
        updateBankrollDisplay()

        // Add game state banner at top center
        gameStateBanner = SKLabelNode(text: "PLACE YOUR BET")
        gameStateBanner.fontSize = 48
        gameStateBanner.fontName = "Arial-BoldMT"
        gameStateBanner.fontColor = .yellow
        gameStateBanner.verticalAlignmentMode = .center
        gameStateBanner.position = CGPoint(x: 0, y: 320)
        gameStateBanner.zPosition = 10

        // Add shadow effect with background panel
        let bannerBackground = SKShapeNode(rectOf: CGSize(width: 600, height: 80), cornerRadius: 10)
        bannerBackground.fillColor = SKColor(white: 0, alpha: 0.6)
        bannerBackground.strokeColor = .yellow
        bannerBackground.lineWidth = 3
        bannerBackground.position = CGPoint(x: 0, y: 320)
        bannerBackground.zPosition = 9
        bannerBackground.name = "bannerBackground"
        addChild(bannerBackground)
        addChild(gameStateBanner)

        updateGameStateBanner()

        // Add hint label below game state banner (clear of table border at y:200)
        hintLabel = SKLabelNode(text: "")
        hintLabel.fontSize = 20
        hintLabel.fontName = "Arial"
        hintLabel.fontColor = SKColor(white: 0.8, alpha: 1.0)
        hintLabel.verticalAlignmentMode = .center
        hintLabel.position = CGPoint(x: 0, y: 250)
        hintLabel.zPosition = 10
        addChild(hintLabel)
        updateHintLabel()

        // Add roll result label to container (initially hidden)
        rollResultLabel = SKLabelNode(text: "")
        rollResultLabel.fontSize = 66
        rollResultLabel.fontName = "Arial-BoldMT"
        rollResultLabel.verticalAlignmentMode = .center
        rollResultLabel.position = CGPoint(x: 0, y: 0)
        rollResultLabel.zPosition = 101
        rollResultLabel.alpha = 0
        gameContainer.addChild(rollResultLabel)

        // Add bet amount controls
        createBetAmountButtons()

        // Setup focus ring for keyboard navigation
        setupFocusRing()

        // Initial UI hints
        updateUIHints()

        // Initial layout positioning and scaling
        repositionUIElements()
    }

    private func updateBankrollDisplay() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        let formattedBankroll = formatter.string(from: NSNumber(value: gameManager.player.bankroll)) ?? "0"
        bankrollLabel.text = "Bankroll: $\(formattedBankroll)"
    }

    private func updateGameStateBanner() {
        switch gameManager.state {
        case .waitingForBet:
            gameStateBanner.text = "PLACE YOUR BET"
            gameStateBanner.fontColor = .yellow
        case .comeOut:
            gameStateBanner.text = "COME OUT ROLL"
            gameStateBanner.fontColor = .cyan
        case .point(let value):
            gameStateBanner.text = "POINT IS \(value)"
            gameStateBanner.fontColor = .white
        case .resolved(let won):
            // High-contrast colors for accessibility (WCAG 3:1 for large text)
            let accessibleRed = SKColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0)  // #FF8080 - 3.3:1 contrast
            let accessibleGreen = SKColor(red: 0.4, green: 1.0, blue: 0.4, alpha: 1.0)  // #66FF66 - high contrast

            if won {
                gameStateBanner.text = "WINNER!"
                gameStateBanner.fontColor = accessibleGreen
            } else {
                // Check if it was a seven-out
                if case .resolved = gameManager.state,
                   let bet = gameManager.player.currentBet,
                   bet.type == .pass,
                   gameManager.pointValue == nil {
                    gameStateBanner.text = "SEVEN OUT"
                    gameStateBanner.fontColor = accessibleRed
                } else {
                    gameStateBanner.text = "LOSER"
                    gameStateBanner.fontColor = accessibleRed
                }
            }
        }
    }

    private func updateHintLabel() {
        let betType = gameManager.player.currentBet?.type ?? .pass

        switch gameManager.state {
        case .waitingForBet:
            hintLabel.text = "Click PASS LINE or DON'T PASS to place your bet"

        case .comeOut:
            if betType == .pass {
                hintLabel.text = "7 or 11 WINS! • 2, 3, 12 loses • Other numbers set the point"
            } else {
                hintLabel.text = "2 or 3 WINS! • 7, 11 loses • 12 pushes • Other sets point"
            }

        case .point(let value):
            if betType == .pass {
                hintLabel.text = "Roll \(value) to WIN! • 7 loses • Click numbers to place bets"
            } else {
                hintLabel.text = "7 WINS! • \(value) loses • Click numbers to place bets"
            }

        case .resolved:
            hintLabel.text = ""
        }
    }

    private func updateUIHints() {
        // Update dice glow based on whether they can be rolled
        let canRoll: Bool
        if case .point = gameManager.state {
            canRoll = true
        } else {
            canRoll = gameManager.state == .comeOut
        }

        // Set dice glow state
        let shouldGlow = canRoll && !isRolling
        die1.setGlowing(shouldGlow)
        die2.setGlowing(shouldGlow)

        // Update table highlighting through CrapsTableNode
        switch gameManager.state {
        case .waitingForBet:
            crapsTable?.highlightBettingAreas(true)
            crapsTable?.highlightPlaceNumbers(except: nil)
        case .comeOut:
            crapsTable?.highlightBettingAreas(false)
            crapsTable?.highlightPlaceNumbers(except: nil)
        case .point(let point):
            crapsTable?.highlightBettingAreas(false)
            crapsTable?.highlightPlaceNumbers(except: point)
        case .resolved:
            crapsTable?.highlightBettingAreas(false)
            crapsTable?.highlightPlaceNumbers(except: nil)
        }
    }

    private func createBetAmountButtons() {
        let amounts = [25, 50, 100, 500]
        let buttonWidth: CGFloat = 100
        let buttonHeight: CGFloat = 50
        let spacing: CGFloat = 20
        let totalWidth = CGFloat(amounts.count) * (buttonWidth + spacing) - spacing
        let startX = -totalWidth / 2 + buttonWidth / 2
        let yPosition: CGFloat = -250

        for (index, amount) in amounts.enumerated() {
            let xPosition = startX + CGFloat(index) * (buttonWidth + spacing)

            // Create button background
            let button = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 10)
            button.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.8, alpha: 0.8)
            button.strokeColor = .white
            button.lineWidth = 2
            button.position = CGPoint(x: xPosition, y: yPosition)
            button.name = "betButton_\(amount)"
            button.zPosition = 5
            addChild(button)
            betButtons.append(button)

            // Create button label
            let label = SKLabelNode(text: "$\(amount)")
            label.fontSize = 24
            label.fontName = "Arial-BoldMT"
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.name = "betButton_\(amount)"
            label.position = CGPoint(x: 0, y: 0)
            button.addChild(label)
        }

        updateBetButtonStates()
    }

    private func updateBetButtonStates() {
        let amounts = [25, 50, 100, 500]
        let bankroll = gameManager.player.bankroll
        let isWaitingForBet = gameManager.state == .waitingForBet
        let isPointPhase: Bool
        if case .point = gameManager.state { isPointPhase = true } else { isPointPhase = false }

        // Buttons are actionable during waitingForBet and point phases
        let buttonsActive = isWaitingForBet || isPointPhase

        for (index, amount) in amounts.enumerated() {
            if index < betButtons.count, let button = betButtons[index] as? SKShapeNode {
                let canAfford = bankroll >= amount
                let isSelected = amount == selectedBetAmount

                // Always show buttons (never hidden) for UI consistency
                button.isHidden = false

                if !buttonsActive {
                    // Disabled state: grayed out during comeOut and resolved
                    button.fillColor = SKColor(white: 0.2, alpha: 0.4)
                    button.strokeColor = SKColor(white: 0.4, alpha: 0.4)
                    button.lineWidth = 1
                    if let label = button.children.first as? SKLabelNode {
                        label.fontColor = SKColor(white: 0.5, alpha: 0.6)
                    }
                } else if !canAfford {
                    // Can't afford: grayed but slightly more visible than disabled
                    button.fillColor = SKColor(white: 0.3, alpha: 0.5)
                    button.strokeColor = SKColor(white: 0.5, alpha: 0.5)
                    button.lineWidth = 2
                    if let label = button.children.first as? SKLabelNode {
                        label.fontColor = SKColor(white: 0.7, alpha: 1.0)
                    }
                } else if isSelected {
                    // Selected: gold highlight
                    button.fillColor = SKColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 1.0)
                    button.strokeColor = .yellow
                    button.lineWidth = 4
                    if let label = button.children.first as? SKLabelNode {
                        label.fontColor = .white
                    }
                } else {
                    // Normal: blue
                    button.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.8, alpha: 0.8)
                    button.strokeColor = .white
                    button.lineWidth = 2
                    if let label = button.children.first as? SKLabelNode {
                        label.fontColor = .white
                    }
                }
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let node = atPoint(location)

        // Handle New Game button click (game over screen)
        if node.name == "newGameButton" {
            startNewGame()
            return
        }

        // Handle bet amount button clicks
        if let nodeName = node.name, nodeName.starts(with: "betButton_") {
            if let amountString = nodeName.split(separator: "_").last,
               let amount = Int(amountString) {
                // Only allow selecting amounts player can afford
                if gameManager.player.bankroll >= amount {
                    selectedBetAmount = amount
                    updateBetButtonStates()
                    // Play button click sound
                    SoundManager.shared.playButtonClick()
                }
            }
            return
        }

        // Handle Place bet clicks on point numbers during point phase
        if let nodeName = node.name, nodeName.starts(with: "placeNumber") {
            if let numberString = nodeName.dropFirst("placeNumber".count).description as String?,
               let number = Int(numberString) {
                // Option+click decreases bet
                let isDecrease = event.modifierFlags.contains(.option)
                handlePlaceBetClick(on: number, isDecrease: isDecrease)
            }
            return
        }

        // Handle betting area clicks
        if (node.name == "passLineArea" || node.name == "dontPassArea") && gameManager.state == .waitingForBet {
            let betAmount = selectedBetAmount

            // Place bet with player
            if gameManager.player.placeBet(type: (node.name == "passLineArea" ? .pass : .dontPass), amount: betAmount) {
                // Play chip click sound
                SoundManager.shared.playChipClick()

                // Create and display chip
                createBetChip(at: node.position, amount: betAmount)

                // Update bankroll display
                updateBankrollDisplay()

                // Announce bet placement
                let betTypeName = (node.name == "passLineArea" ? "Pass Line" : "Don't Pass")
                announceBetPlaced(amount: betAmount, betType: betTypeName)

                // Update table accessibility
                updateTableAccessibility()

                // Transition game state
                gameManager.placeBet()

                // Update game state banner
                updateGameStateBanner()

                // Update hint label
                updateHintLabel()

                // Update bet button states (hide them after bet placed)
                updateBetButtonStates()

                // Update UI hints (makes Roll Dice throb)
                updateUIHints()
            }
        }

        // Check if clicked on dice (or their children)
        let clickedDie = (node === die1 || node.parent === die1 || node.parent?.parent === die1 ||
                         node === die2 || node.parent === die2 || node.parent?.parent === die2)

        if clickedDie {
            // Only allow rolling if bet is placed (state is comeOut or point)
            let canRoll: Bool
            if case .point = gameManager.state {
                canRoll = true
            } else {
                canRoll = gameManager.state == .comeOut
            }
            guard canRoll else { return }

            // Prevent multiple simultaneous rolls
            guard !isRolling else { return }
            isRolling = true

            // Stop dice glow while rolling
            die1.setGlowing(false)
            die2.setGlowing(false)

            // Play button click sound
            SoundManager.shared.playButtonClick()

            // Get final dice values from the model
            let finalValue1 = Die.roll()
            let finalValue2 = Die.roll()
            let total = finalValue1 + finalValue2

            // Track completion of both dice
            var completedDice = 0
            let diceCompletion = {
                completedDice += 1
                if completedDice == 2 {
                    self.isRolling = false
                    print("Rolled: \(finalValue1) and \(finalValue2) = \(total)")

                    // Process roll through GameManager
                    self.gameManager.roll(die1: finalValue1, die2: finalValue2)

                    // Show roll result callout
                    self.showRollResult(total: total)

                    // Update dice accessibility label
                    let canRollNext = self.gameManager.state == .comeOut || (self.gameManager.state != .waitingForBet && self.gameManager.state != .resolved(won: true) && self.gameManager.state != .resolved(won: false))
                    self.accessibilityManager?.updateDiceLabel(die1: finalValue1, die2: finalValue2, canRoll: canRollNext)

                    // Announce roll result for VoiceOver
                    self.announceRollResult(die1: finalValue1, die2: finalValue2, total: total)

                    // Update game state banner
                    self.updateGameStateBanner()

                    // Update hint label
                    self.updateHintLabel()

                    // Update UI hints
                    self.updateUIHints()

                    // Handle outcome based on new state
                    self.handleRollOutcome()
                }
            }

            // Animate both dice
            die1.roll(to: finalValue1, completion: diceCompletion)
            die2.roll(to: finalValue2, completion: diceCompletion)
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let node = atPoint(location)

        // Handle right-click on place numbers to decrease bet
        if let nodeName = node.name, nodeName.starts(with: "placeNumber") {
            if let numberString = nodeName.dropFirst("placeNumber".count).description as String?,
               let number = Int(numberString) {
                handlePlaceBetClick(on: number, isDecrease: true)
            }
        }
    }

    private func handleRollOutcome() {
        // Check for place bet winnings first
        if gameManager.lastPlaceBetWinnings > 0, let winningNumber = gameManager.lastPlaceBetWinningNumber {
            // Show place bet winnings
            showPlaceBetWinnings(amount: gameManager.lastPlaceBetWinnings, on: winningNumber)

            // Remove the winning chip
            removePlaceChip(from: winningNumber)

            // Play win sound for place bet
            SoundManager.shared.playWinSound()

            // Show visual feedback for hearing accessibility
            showWinFeedback(amount: gameManager.lastPlaceBetWinnings)

            // Announce place bet win
            announceBetResolved(won: true, amount: gameManager.lastPlaceBetWinnings, betType: "Place \(winningNumber)")

            // Update bankroll display and accessibility
            updateBankrollDisplay()
            accessibilityManager?.updateBankrollLabel(amount: gameManager.player.bankroll)
        }

        switch gameManager.state {
        case .resolved(let won):
            // All place bets lose on seven out - remove chips
            removeAllPlaceChips()

            // Show outcome feedback
            showOutcomeLabel(won: won)

            // Show visual feedback for hearing accessibility
            if let bet = gameManager.player.currentBet {
                let betTypeName = bet.type == .pass ? "Pass Line" : "Don't Pass"
                if won {
                    showWinFeedback(amount: bet.amount * 2)
                } else {
                    showLoseFeedback(betType: betTypeName)
                }

                // Announce main bet resolution
                let payout = won ? bet.amount * 2 : 0  // Win pays 1:1, so get back bet + winnings
                announceBetResolved(won: won, amount: payout, betType: betTypeName)
            }

            // Update bankroll display and accessibility
            updateBankrollDisplay()
            accessibilityManager?.updateBankrollLabel(amount: gameManager.player.bankroll)

            // Update betting area accessibility (bet resolved)
            accessibilityManager?.updatePassLineLabel(betAmount: nil)
            accessibilityManager?.updateDontPassLabel(betAmount: nil)

            // Wait 1.5 seconds, then reset
            let waitAction = SKAction.wait(forDuration: 1.5)
            let resetAction = SKAction.run {
                // Remove bet chip
                self.betChip?.removeFromParent()
                self.betChip = nil

                // Hide outcome label
                self.outcomeLabel?.removeFromParent()
                self.outcomeLabel = nil

                // Reset puck to OFF
                self.crapsTable?.setPuckPosition(point: nil)

                // Reset game state
                self.gameManager.reset()

                // Update bankroll display and accessibility
                self.updateBankrollDisplay()
                self.accessibilityManager?.updateBankrollLabel(amount: self.gameManager.player.bankroll)

                // Update game state banner
                self.updateGameStateBanner()

                // Update hint label
                self.updateHintLabel()

                // Update bet button states (show them again)
                self.updateBetButtonStates()

                // Update UI hints (highlights betting areas again)
                self.updateUIHints()

                // Reset point labels
                for num in [4, 5, 6, 8, 9, 10] {
                    self.accessibilityManager?.updatePointLabel(number: num, isCurrentPoint: false, betAmount: nil)
                }

                // Check if player is broke (no money AND no active bets)
                if self.gameManager.player.bankroll == 0 &&
                   self.gameManager.player.currentBet == nil &&
                   self.gameManager.player.placeBets.isEmpty {
                    self.showGameOverPrompt()
                }
            }
            run(SKAction.sequence([waitAction, resetAction]))

        case .point(let pointValue):
            print("Point is \(pointValue)")
            // Play point established sound
            SoundManager.shared.playPointEstablished()

            // Show visual feedback for hearing accessibility
            showPointEstablished(point: pointValue)

            // Update puck to show ON at the point number
            crapsTable?.setPuckPosition(point: pointValue)

            // Update point number accessibility labels
            for num in [4, 5, 6, 8, 9, 10] {
                let placeBetAmount = gameManager.player.getPlaceBetAmount(on: num)
                accessibilityManager?.updatePointLabel(number: num, isCurrentPoint: num == pointValue, betAmount: placeBetAmount)
            }

            // Bet chip stays on table for point phase

        default:
            break
        }
    }

    private func showPlaceBetWinnings(amount: Int, on number: Int) {
        // Get position of the number box
        guard let position = crapsTable?.getPointBoxPosition(number: number) else { return }

        // High-contrast green for accessibility (WCAG 3:1 for large text)
        let accessibleGreen = SKColor(red: 0.4, green: 1.0, blue: 0.4, alpha: 1.0)  // #66FF66

        // Create floating winnings label
        let winLabel = SKLabelNode(text: "+$\(amount)")
        winLabel.fontSize = 28
        winLabel.fontName = "Arial-BoldMT"
        winLabel.fontColor = accessibleGreen
        winLabel.position = CGPoint(x: position.x, y: position.y - 40)
        winLabel.zPosition = 200
        crapsTable?.addChild(winLabel)

        let remove = SKAction.removeFromParent()

        // Check for Reduce Motion preference
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            // Static display, then remove after delay
            let wait = SKAction.wait(forDuration: 1.0)
            winLabel.run(SKAction.sequence([wait, remove]))
        } else {
            // Animate floating up and fading out
            let moveUp = SKAction.moveBy(x: 0, y: 60, duration: 1.0)
            let fadeOut = SKAction.fadeOut(withDuration: 1.0)
            let group = SKAction.group([moveUp, fadeOut])
            winLabel.run(SKAction.sequence([group, remove]))
        }
    }

    private func showOutcomeLabel(won: Bool) {
        // Remove existing label if any
        outcomeLabel?.removeFromParent()

        // Determine label text based on outcome and bet type
        let labelText: String
        if won {
            labelText = "WIN!"
            // Play win sound
            SoundManager.shared.playWinSound()
        } else {
            // Check if it was a seven-out (point phase loss with pass bet or win with don't pass)
            if case .resolved = gameManager.state,
               let bet = gameManager.player.currentBet {
                if bet.type == .pass {
                    labelText = "SEVEN OUT!"
                } else {
                    labelText = "LOSE!"
                }
            } else {
                labelText = "LOSE!"
            }
            // Play lose sound
            SoundManager.shared.playLoseSound()
        }

        // Create outcome label with high-contrast colors (WCAG 3:1 for large text)
        let accessibleRed = SKColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0)  // #FF8080
        let accessibleGreen = SKColor(red: 0.4, green: 1.0, blue: 0.4, alpha: 1.0)  // #66FF66

        let label = SKLabelNode(text: labelText)
        label.fontSize = 72
        label.fontName = "Arial-BoldMT"
        label.fontColor = won ? accessibleGreen : accessibleRed
        label.position = CGPoint(x: 0, y: 100)
        label.zPosition = 100
        addChild(label)
        outcomeLabel = label

        // Check for Reduce Motion preference
        if !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            // Add pulsing animation (skip if Reduce Motion enabled)
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.3)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.3)
            let pulse = SKAction.sequence([scaleUp, scaleDown])
            label.run(SKAction.repeatForever(pulse))
        }
        // If Reduce Motion is enabled, label displays at static size
    }

    private func showRollResult(total: Int) {
        // Determine color based on game state and bet type
        // High-contrast colors for accessibility (WCAG 3:1 for large text)
        let accessibleRed = SKColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0)  // #FF8080
        let accessibleGreen = SKColor(red: 0.4, green: 1.0, blue: 0.4, alpha: 1.0)  // #66FF66

        var color: SKColor
        var isWinning = false
        var isLosing = false

        switch gameManager.state {
        case .resolved(let won):
            // Resolved state - show green for win, red for loss
            if won {
                color = accessibleGreen
                isWinning = true
            } else {
                color = accessibleRed
                isLosing = true
            }

        case .point:
            // Point was just set - neutral/informative (yellow)
            color = .yellow

        case .comeOut:
            // Shouldn't happen, but default to white
            color = .white

        case .waitingForBet:
            // Shouldn't happen
            color = .white
        }

        // Set text and color
        rollResultLabel.text = "\(total)!"
        rollResultLabel.fontColor = color

        // Remove any existing animations
        rollResultLabel.removeAllActions()

        // Hold duration depends on outcome type
        let holdDuration: TimeInterval
        if isWinning || isLosing {
            // Win/loss: hold for 1 second
            holdDuration = 1.0
        } else {
            // Point set: fade faster (0.6 seconds)
            holdDuration = 0.6
        }

        // Check for Reduce Motion preference
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            // Instant display, then hide after delay (no animation)
            rollResultLabel.alpha = 1
            rollResultLabel.setScale(1)
            let wait = SKAction.wait(forDuration: holdDuration)
            let hide = SKAction.run { self.rollResultLabel.alpha = 0 }
            rollResultLabel.run(SKAction.sequence([wait, hide]))
        } else {
            // Animation sequence
            rollResultLabel.alpha = 0
            rollResultLabel.setScale(0)

            let popIn = SKAction.group([
                SKAction.fadeIn(withDuration: 0.2),
                SKAction.sequence([
                    SKAction.scale(to: 1.2, duration: 0.15),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ])
            ])

            let wait = SKAction.wait(forDuration: holdDuration)
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)

            let sequence = SKAction.sequence([popIn, wait, fadeOut])
            rollResultLabel.run(sequence)
        }
    }

    private func createBetChip(at position: CGPoint, amount: Int) {
        // Remove existing chip if any
        betChip?.removeFromParent()

        // Create chip node
        let chipRadius: CGFloat = 25
        let chip = SKShapeNode(circleOfRadius: chipRadius)
        chip.fillColor = SKColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
        chip.strokeColor = .white
        chip.lineWidth = 3
        // Offset chip to the right of center so it doesn't cover text
        chip.position = CGPoint(x: position.x + 200, y: position.y)

        // Add amount label
        let label = SKLabelNode(text: "$\(amount)")
        label.fontSize = 18
        label.fontName = "Arial-BoldMT"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        chip.addChild(label)

        // Add to table
        crapsTable?.addChild(chip)
        betChip = chip
    }

    // MARK: - Place Bets

    private func handlePlaceBetClick(on number: Int, isDecrease: Bool = false) {
        // Must be in point phase to interact with place bets
        guard case .point = gameManager.state else {
            print("Can only place/remove bets during point phase")
            return
        }

        if isDecrease {
            // Decrease existing bet
            let result = gameManager.player.decreasePlaceBet(number: number, amount: selectedBetAmount)
            if result.success {
                if result.newAmount == 0 {
                    // Bet removed entirely
                    SoundManager.shared.playBetDecrease()
                    removePlaceChipAnimated(from: number)
                    announceBetRemoved(number: number)
                } else {
                    // Bet decreased
                    SoundManager.shared.playBetDecrease()
                    updatePlaceChip(on: number, amount: result.newAmount, decreased: true)
                    announceBetChanged(number: number, newAmount: result.newAmount, increased: false)
                }
                updateBankrollDisplay()
                updateHintLabel()
                print("Decreased bet on \(number), new amount: $\(result.newAmount)")
            }
        } else {
            // Increase or place new bet
            // Check if we can place a bet on this number (not the point)
            guard gameManager.canPlaceBet(on: number) else {
                print("Cannot place bet on \(number)")
                return
            }

            // Check if player can afford the bet
            guard gameManager.player.bankroll >= selectedBetAmount else {
                print("Cannot afford place bet")
                return
            }

            let hadExistingBet = gameManager.player.hasPlaceBet(on: number)

            // Place or increase the bet
            if gameManager.player.placePlaceBet(number: number, amount: selectedBetAmount) {
                if hadExistingBet {
                    // Increased existing bet
                    SoundManager.shared.playBetIncrease()
                    let newAmount = gameManager.player.getPlaceBetAmount(on: number) ?? 0
                    updatePlaceChip(on: number, amount: newAmount, decreased: false)
                    announceBetChanged(number: number, newAmount: newAmount, increased: true)
                    print("Increased bet on \(number) to $\(newAmount)")
                } else {
                    // New bet placed
                    SoundManager.shared.playChipClick()
                    createPlaceChip(on: number, amount: selectedBetAmount)
                    announceBetPlaced(amount: selectedBetAmount, betType: "Place \(number)")
                    print("Placed $\(selectedBetAmount) on \(number)")
                }

                // Update bankroll display
                updateBankrollDisplay()

                // Update hint label
                updateHintLabel()
            }
        }
    }

    private func createPlaceChip(on number: Int, amount: Int) {
        // Get position of the number box
        guard let position = crapsTable?.getPointBoxPosition(number: number) else { return }

        // Create chip node (slightly smaller than pass line chip)
        let chipRadius: CGFloat = 20
        let chip = SKShapeNode(circleOfRadius: chipRadius)
        chip.fillColor = SKColor(red: 0.1, green: 0.5, blue: 0.1, alpha: 1.0)  // Green for place bets
        chip.strokeColor = .white
        chip.lineWidth = 2
        chip.position = CGPoint(x: position.x, y: position.y - 15)  // Offset below the number
        chip.zPosition = 50

        // Add amount label
        let label = SKLabelNode(text: "$\(amount)")
        label.fontSize = 14
        label.fontName = "Arial-BoldMT"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        chip.addChild(label)

        // Add to table and track
        crapsTable?.addChild(chip)
        placeChips[number] = chip
    }

    private func removePlaceChip(from number: Int) {
        placeChips[number]?.removeFromParent()
        placeChips[number] = nil
    }

    private func removeAllPlaceChips() {
        for (_, chip) in placeChips {
            chip.removeFromParent()
        }
        placeChips.removeAll()
    }

    private func updatePlaceChip(on number: Int, amount: Int, decreased: Bool) {
        guard let chip = placeChips[number] as? SKShapeNode else { return }

        // Update label
        if let label = chip.children.first as? SKLabelNode {
            label.text = "$\(amount)"
        }

        // Show visual feedback
        showBetChangeFeedback(on: number, amount: decreased ? -selectedBetAmount : selectedBetAmount, decreased: decreased)
    }

    private func removePlaceChipAnimated(from number: Int) {
        guard let chip = placeChips[number] else { return }

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            chip.removeFromParent()
        } else {
            let shrink = SKAction.scale(to: 0, duration: 0.2)
            let fade = SKAction.fadeOut(withDuration: 0.2)
            let remove = SKAction.removeFromParent()
            chip.run(SKAction.sequence([SKAction.group([shrink, fade]), remove]))
        }

        placeChips[number] = nil
    }

    private func showBetChangeFeedback(on number: Int, amount: Int, decreased: Bool) {
        guard let position = crapsTable?.getPointBoxPosition(number: number) else { return }

        // Colors (WCAG compliant)
        let color: SKColor = decreased ?
            SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0) :  // Amber for decrease
            SKColor(red: 0.4, green: 1.0, blue: 0.4, alpha: 1.0)    // Green for increase

        // Direction indicator for color blindness
        let indicator = decreased ? "v" : "^"
        let amountText = decreased ? "-$\(abs(amount))" : "+$\(abs(amount))"

        // Create feedback label
        let label = SKLabelNode(text: "\(indicator) \(amountText)")
        label.fontSize = 24
        label.fontName = "Arial-BoldMT"
        label.fontColor = color
        label.position = CGPoint(x: position.x, y: position.y - 50)
        label.zPosition = 200
        crapsTable?.addChild(label)

        let remove = SKAction.removeFromParent()

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            // Static display
            let wait = SKAction.wait(forDuration: 0.8)
            label.run(SKAction.sequence([wait, remove]))
        } else {
            // Animate: float in direction of change
            let moveY: CGFloat = decreased ? -40 : 40
            let move = SKAction.moveBy(x: 0, y: moveY, duration: 0.8)
            let fade = SKAction.fadeOut(withDuration: 0.8)
            label.run(SKAction.sequence([SKAction.group([move, fade]), remove]))
        }

        // Pulse the chip
        if let chip = placeChips[number] {
            pulseChip(chip, color: color)
        }
    }

    private func pulseChip(_ chip: SKNode, color: SKColor) {
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }

        // Create pulse overlay
        let pulse = SKShapeNode(circleOfRadius: 22)
        pulse.fillColor = .clear
        pulse.strokeColor = color
        pulse.lineWidth = 3
        pulse.position = chip.position
        pulse.zPosition = chip.zPosition + 1
        crapsTable?.addChild(pulse)

        let expand = SKAction.scale(to: 1.3, duration: 0.15)
        let contract = SKAction.scale(to: 1.0, duration: 0.15)
        let remove = SKAction.removeFromParent()
        pulse.run(SKAction.sequence([expand, contract, remove]))
    }

    // MARK: - Accessibility Announcements

    private func announceRollResult(die1: Int, die2: Int, total: Int) {
        var announcement = "Rolled \(die1) and \(die2), total \(total). "

        // Add context based on game state
        switch gameManager.state {
        case .resolved(let won):
            if won {
                announcement += "Winner!"
            } else {
                // Check if it was a seven-out
                if let bet = gameManager.player.currentBet,
                   bet.type == .pass,
                   gameManager.pointValue == nil {
                    announcement += "Seven out!"
                } else {
                    announcement += "Loser!"
                }
            }
        case .point(let value):
            announcement += "Point is \(value)."
        case .comeOut, .waitingForBet:
            break
        }

        NSAccessibility.post(element: self.view as Any, notification: .announcementRequested, userInfo: [.announcement: announcement])
    }

    private func announceBetPlaced(amount: Int, betType: String) {
        let announcement = "Placed $\(amount) on \(betType)"
        NSAccessibility.post(element: self.view as Any, notification: .announcementRequested, userInfo: [.announcement: announcement])
    }

    private func announceBetResolved(won: Bool, amount: Int, betType: String) {
        let announcement: String
        if won {
            announcement = "Won $\(amount) on \(betType)"
        } else {
            announcement = "Lost \(betType) bet"
        }
        NSAccessibility.post(element: self.view as Any, notification: .announcementRequested, userInfo: [.announcement: announcement])
    }

    private func announceBetChanged(number: Int, newAmount: Int, increased: Bool) {
        let action = increased ? "Increased" : "Decreased"
        let announcement = "\(action) Place \(number) to $\(newAmount)"
        NSAccessibility.post(element: self.view as Any, notification: .announcementRequested, userInfo: [.announcement: announcement])
    }

    private func announceBetRemoved(number: Int) {
        let announcement = "Place \(number) bet removed"
        NSAccessibility.post(element: self.view as Any, notification: .announcementRequested, userInfo: [.announcement: announcement])
    }

    private func updateTableAccessibility() {
        // Update betting area accessibility values
        let passLineBet: Int?
        let dontPassBet: Int?

        if let currentBet = gameManager.player.currentBet {
            if currentBet.type == .pass {
                passLineBet = currentBet.amount
                dontPassBet = nil
            } else if currentBet.type == .dontPass {
                passLineBet = nil
                dontPassBet = currentBet.amount
            } else {
                passLineBet = nil
                dontPassBet = nil
            }
        } else {
            passLineBet = nil
            dontPassBet = nil
        }

        crapsTable?.updateBetAreaAccessibility(passLineBet: passLineBet, dontPassBet: dontPassBet)

        // Update accessibility manager labels
        accessibilityManager?.updatePassLineLabel(betAmount: passLineBet)
        accessibilityManager?.updateDontPassLabel(betAmount: dontPassBet)
    }

    // MARK: - Visual Feedback for Hearing Accessibility

    private func showWinFeedback(amount: Int) {
        // High-contrast green for accessibility (WCAG 3:1 for large text)
        let accessibleGreen = SKColor(red: 0.4, green: 1.0, blue: 0.4, alpha: 1.0)  // #66FF66

        // Flash border green with solid thick line (color blind: solid = win)
        let flash = SKShapeNode(rectOf: CGSize(width: 980, height: 740))
        flash.strokeColor = accessibleGreen
        flash.lineWidth = 12  // Thicker for win
        flash.fillColor = .clear
        flash.zPosition = 900
        addChild(flash)

        // Container for win indicator
        let container = SKNode()
        container.position = CGPoint(x: 0, y: 0)
        container.zPosition = 901
        addChild(container)

        // Checkmark symbol for color blind support (✓)
        let checkmark = SKLabelNode(text: "✓")
        checkmark.fontSize = 72
        checkmark.fontColor = accessibleGreen
        checkmark.fontName = "Arial-BoldMT"
        checkmark.position = CGPoint(x: -80, y: -10)
        checkmark.verticalAlignmentMode = .center
        container.addChild(checkmark)

        // Floating "+$amount" text
        let winText = SKLabelNode(text: "+$\(amount)")
        winText.fontSize = 48
        winText.fontColor = accessibleGreen
        winText.fontName = "Arial-BoldMT"
        winText.position = CGPoint(x: 30, y: 0)
        winText.verticalAlignmentMode = .center
        container.addChild(winText)

        let remove = SKAction.removeFromParent()

        // Check for Reduce Motion preference
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            // Instant appearance, then remove after delay (no animation)
            let wait = SKAction.wait(forDuration: 1.5)
            container.run(SKAction.sequence([wait, remove]))
            flash.run(SKAction.sequence([wait, remove]))
        } else {
            // Animate: rise and fade
            let rise = SKAction.moveBy(x: 0, y: 100, duration: 1.5)
            let fade = SKAction.fadeOut(withDuration: 1.5)
            container.run(SKAction.sequence([SKAction.group([rise, fade]), remove]))

            // Flash fade
            flash.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.5),
                remove
            ]))
        }
    }

    private func showLoseFeedback(betType: String) {
        // High-contrast red for accessibility (WCAG 3:1 for large text)
        let accessibleRed = SKColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0)  // #FF8080

        // Flash border red with dashed line (color blind: dashed = lose)
        let flash = SKShapeNode(rectOf: CGSize(width: 980, height: 740))
        flash.strokeColor = accessibleRed
        flash.lineWidth = 6
        flash.fillColor = .clear
        flash.zPosition = 900
        // Add dashed pattern for color blind differentiation
        flash.path = flash.path?.copy(dashingWithPhase: 0, lengths: [20, 10])
        addChild(flash)

        // Container for lose indicator
        let container = SKNode()
        container.position = CGPoint(x: 0, y: 0)
        container.zPosition = 901
        addChild(container)

        // X symbol for color blind support (✗)
        let xMark = SKLabelNode(text: "✗")
        xMark.fontSize = 60
        xMark.fontColor = accessibleRed
        xMark.fontName = "Arial-BoldMT"
        xMark.position = CGPoint(x: -100, y: -8)
        xMark.verticalAlignmentMode = .center
        container.addChild(xMark)

        // Floating "Lost [bet]" text
        let loseText = SKLabelNode(text: "Lost \(betType)")
        loseText.fontSize = 36
        loseText.fontColor = accessibleRed
        loseText.fontName = "Arial-BoldMT"
        loseText.position = CGPoint(x: 20, y: 0)
        loseText.verticalAlignmentMode = .center
        container.addChild(loseText)

        let remove = SKAction.removeFromParent()

        // Check for Reduce Motion preference
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            // Instant appearance, then remove after delay (no animation)
            let wait = SKAction.wait(forDuration: 1.0)
            container.run(SKAction.sequence([wait, remove]))
            flash.run(SKAction.sequence([wait, remove]))
        } else {
            // Animate: sink and fade
            let sink = SKAction.moveBy(x: 0, y: -50, duration: 1.0)
            let fade = SKAction.fadeOut(withDuration: 1.0)
            container.run(SKAction.sequence([SKAction.group([sink, fade]), remove]))
            flash.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.5), remove]))
        }
    }

    private func showPointEstablished(point: Int) {
        // Flash the point number box gold
        if let boxPosition = crapsTable?.getPointBoxPosition(number: point) {
            let highlight = SKShapeNode(rectOf: CGSize(width: 90, height: 70), cornerRadius: 8)
            highlight.position = boxPosition
            highlight.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0, alpha: 0.5)
            highlight.strokeColor = .clear
            highlight.zPosition = 50
            crapsTable?.addChild(highlight)

            // Check for Reduce Motion preference
            if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
                // Static highlight, then remove after delay (no animation)
                let wait = SKAction.wait(forDuration: 1.2)
                highlight.run(SKAction.sequence([wait, SKAction.removeFromParent()]))
            } else {
                // Animated flash 3 times
                let flash = SKAction.sequence([
                    SKAction.fadeIn(withDuration: 0.2),
                    SKAction.fadeOut(withDuration: 0.2)
                ])
                highlight.run(SKAction.sequence([
                    SKAction.repeat(flash, count: 3),
                    SKAction.removeFromParent()
                ]))
            }
        }
    }

    func setAccessibilityManager(_ manager: GameAccessibilityManager) {
        self.accessibilityManager = manager
    }

    // MARK: - Game Over

    private func showGameOverPrompt() {
        // Create overlay background
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        overlay.fillColor = SKColor(white: 0, alpha: 0.7)
        overlay.strokeColor = .clear
        overlay.position = .zero
        overlay.zPosition = 1000
        overlay.name = "gameOverOverlay"
        addChild(overlay)

        // Create prompt container
        let container = SKNode()
        container.zPosition = 1001
        container.name = "gameOverContainer"
        addChild(container)

        // "GAME OVER" title
        let title = SKLabelNode(text: "GAME OVER")
        title.fontSize = 72
        title.fontName = "Arial-BoldMT"
        title.fontColor = .yellow
        title.position = CGPoint(x: 0, y: 80)
        container.addChild(title)

        // "You're broke!" message
        let message = SKLabelNode(text: "You're out of chips!")
        message.fontSize = 28
        message.fontName = "Arial"
        message.fontColor = .white
        message.position = CGPoint(x: 0, y: 20)
        container.addChild(message)

        // "New Game" button
        let buttonBg = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 10)
        buttonBg.fillColor = SKColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1.0)
        buttonBg.strokeColor = .white
        buttonBg.lineWidth = 3
        buttonBg.position = CGPoint(x: 0, y: -60)
        buttonBg.name = "newGameButton"
        container.addChild(buttonBg)

        let buttonLabel = SKLabelNode(text: "New Game")
        buttonLabel.fontSize = 28
        buttonLabel.fontName = "Arial-BoldMT"
        buttonLabel.fontColor = .white
        buttonLabel.verticalAlignmentMode = .center
        buttonLabel.position = CGPoint(x: 0, y: -60)
        buttonLabel.name = "newGameButton"
        container.addChild(buttonLabel)

        // Announce for VoiceOver
        NSAccessibility.post(element: self.view as Any, notification: .announcementRequested,
                           userInfo: [.announcement: "Game over. You're out of chips. Press Space or click New Game to start over."])
    }

    func startNewGame() {
        // Remove game over UI
        childNode(withName: "gameOverOverlay")?.removeFromParent()
        childNode(withName: "gameOverContainer")?.removeFromParent()

        // Reset player bankroll
        gameManager.player.resetBankroll()

        // Update displays
        updateBankrollDisplay()
        accessibilityManager?.updateBankrollLabel(amount: gameManager.player.bankroll)
        updateGameStateBanner()
        updateHintLabel()
        updateBetButtonStates()
        updateUIHints()

        // Announce
        NSAccessibility.post(element: self.view as Any, notification: .announcementRequested,
                           userInfo: [.announcement: "New game started. Bankroll reset to $1,000."])
    }

    // MARK: - Focus Ring Setup

    private func setupFocusRing() {
        focusRing = SKShapeNode()
        focusRing?.strokeColor = NSColor.keyboardFocusIndicatorColor
        focusRing?.lineWidth = 3
        focusRing?.fillColor = .clear
        focusRing?.zPosition = 1000  // Above everything
        focusRing?.isHidden = true
        addChild(focusRing!)
    }

    private func getDiceBounds() -> CGRect {
        // Calculate bounds that cover both dice
        let die1Pos = die1.position
        let die2Pos = die2.position
        let leftX = min(die1Pos.x, die2Pos.x) - 35
        let rightX = max(die1Pos.x, die2Pos.x) + 35
        let width = rightX - leftX
        let centerX = (leftX + rightX) / 2
        let centerY = (die1Pos.y + die2Pos.y) / 2

        return CGRect(x: centerX - width/2, y: centerY - 35, width: width, height: 70)
    }

    private func updateFocusRing(for element: FocusableElement) {
        guard let focusRing = focusRing else { return }

        let frame: CGRect
        switch element {
        case .dice:
            frame = getDiceBounds()
        case .passLine:
            frame = crapsTable?.getPassLineFrame() ?? .zero
        case .dontPass:
            frame = crapsTable?.getDontPassFrame() ?? .zero
        case .point4, .point5, .point6, .point8, .point9, .point10:
            if let number = element.pointNumber {
                frame = crapsTable?.getPointBoxFrame(number: number) ?? .zero
            } else {
                frame = .zero
            }
        case .bet25, .bet50, .bet100, .bet500:
            frame = getBetButtonFrame(for: element)
        }

        // Create rounded rect path
        let path = CGPath(roundedRect: frame.insetBy(dx: -4, dy: -4),
                         cornerWidth: 8, cornerHeight: 8, transform: nil)
        focusRing.path = path
        focusRing.isHidden = false

        // Announce focus change for VoiceOver
        announceFocusChange(element)
    }

    private func getBetButtonFrame(for element: FocusableElement) -> CGRect {
        let amounts = [25, 50, 100, 500]
        guard let amount = element.betAmount,
              let index = amounts.firstIndex(of: amount),
              index < betButtons.count else {
            return .zero
        }

        let button = betButtons[index]
        // Button is 70x40 centered at its position
        let buttonSize = CGSize(width: 70, height: 40)
        return CGRect(x: button.position.x - buttonSize.width/2,
                     y: button.position.y - buttonSize.height/2,
                     width: buttonSize.width,
                     height: buttonSize.height)
    }

    private func announceFocusChange(_ element: FocusableElement) {
        let announcement: String
        switch element {
        case .dice:
            announcement = "Dice"
        case .passLine:
            announcement = "Pass Line bet area"
        case .dontPass:
            announcement = "Don't Pass bet area"
        case .point4, .point5, .point6, .point8, .point9, .point10:
            if let number = element.pointNumber {
                if let currentBet = gameManager.player.getPlaceBetAmount(on: number) {
                    announcement = "Place \(number), current bet $\(currentBet). Space to increase, Delete to decrease."
                } else {
                    announcement = "Place \(number), no bet. Space to place bet."
                }
            } else {
                announcement = "Point number"
            }
        case .bet25, .bet50, .bet100, .bet500:
            if let amount = element.betAmount {
                let isSelected = amount == selectedBetAmount
                announcement = "$\(amount) bet amount\(isSelected ? ", currently selected" : "")"
            } else {
                announcement = "Bet amount"
            }
        }
        NSAccessibility.post(element: self.view as Any, notification: .announcementRequested, userInfo: [.announcement: announcement])
    }

    // MARK: - Keyboard Navigation Methods

    override func keyDown(with event: NSEvent) {
        // If game over prompt is showing, Space/Enter starts new game
        if childNode(withName: "gameOverOverlay") != nil {
            if event.keyCode == 49 || event.keyCode == 36 {  // Space or Enter
                startNewGame()
            }
            return  // Ignore other keys during game over
        }

        switch event.keyCode {
        case 48:  // Tab
            if event.modifierFlags.contains(.shift) {
                focusPreviousElement()
            } else {
                focusNextElement()
            }
        case 49:  // Space
            activateFocusedElement()
        case 36:  // Return/Enter
            activateFocusedElement()
        case 123: // Left arrow
            focusPreviousInGroup()
        case 124: // Right arrow
            focusNextInGroup()
        case 125: // Down arrow
            focusNextElement()
        case 126: // Up arrow
            focusPreviousElement()
        case 53:  // Escape
            clearFocus()
            // Exit full-screen mode if active
            if let window = view?.window, window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
        case 51, 117:  // Delete, Forward Delete - decrease bet on focused place number
            if let focus = currentFocus, let number = focus.pointNumber {
                handlePlaceBetClick(on: number, isDecrease: true)
            }
        default:
            super.keyDown(with: event)
        }
    }

    /// Returns only elements that are currently actionable based on game state
    private func getActionableElements() -> [FocusableElement] {
        var actionable: [FocusableElement] = []

        // Dice: actionable when can roll and not currently rolling
        let canRoll: Bool
        if case .point = gameManager.state {
            canRoll = true
        } else {
            canRoll = gameManager.state == .comeOut
        }
        if canRoll && !isRolling {
            actionable.append(.dice)
        }

        // Pass Line / Don't Pass: actionable during waitingForBet
        if gameManager.state == .waitingForBet {
            // Bet amount buttons: actionable if player can afford them
            let bankroll = gameManager.player.bankroll
            let amounts = [25, 50, 100, 500]
            for amount in amounts {
                if bankroll >= amount, let element = FocusableElement.fromBetAmount(amount) {
                    actionable.append(element)
                }
            }

            actionable.append(.passLine)
            actionable.append(.dontPass)
        }

        // Point numbers and bet buttons: actionable during point phase
        if case .point(let currentPoint) = gameManager.state {
            // Bet amount buttons: actionable if player can afford them
            let bankroll = gameManager.player.bankroll
            let amounts = [25, 50, 100, 500]
            for amount in amounts {
                if bankroll >= amount, let element = FocusableElement.fromBetAmount(amount) {
                    actionable.append(element)
                }
            }

            // Point numbers (except current point)
            let pointNumbers = [4, 5, 6, 8, 9, 10]
            for num in pointNumbers {
                if num != currentPoint {
                    if let element = FocusableElement.fromPointNumber(num) {
                        actionable.append(element)
                    }
                }
            }
        }

        return actionable
    }

    private func focusNextElement() {
        let actionable = getActionableElements()
        guard !actionable.isEmpty else {
            clearFocus()
            return
        }

        if let current = currentFocus,
           let currentIndex = actionable.firstIndex(of: current) {
            let nextIndex = (currentIndex + 1) % actionable.count
            setFocus(actionable[nextIndex])
        } else {
            // Start at the beginning
            setFocus(actionable[0])
        }
    }

    private func focusPreviousElement() {
        let actionable = getActionableElements()
        guard !actionable.isEmpty else {
            clearFocus()
            return
        }

        if let current = currentFocus,
           let currentIndex = actionable.firstIndex(of: current) {
            let previousIndex = currentIndex == 0 ? actionable.count - 1 : currentIndex - 1
            setFocus(actionable[previousIndex])
        } else {
            // Start at the end
            setFocus(actionable.last!)
        }
    }

    private func focusNextInGroup() {
        // Only works for point numbers group during point phase
        guard let current = currentFocus,
              current.pointNumber != nil,
              case .point(let currentPoint) = gameManager.state else {
            focusNextElement()
            return
        }

        // Only actionable point numbers (exclude current point)
        let actionablePoints: [FocusableElement] = [.point4, .point5, .point6, .point8, .point9, .point10]
            .filter { $0.pointNumber != currentPoint }

        guard !actionablePoints.isEmpty else { return }

        if let currentIndex = actionablePoints.firstIndex(of: current) {
            let nextIndex = (currentIndex + 1) % actionablePoints.count
            setFocus(actionablePoints[nextIndex])
        } else if let first = actionablePoints.first {
            setFocus(first)
        }
    }

    private func focusPreviousInGroup() {
        // Only works for point numbers group during point phase
        guard let current = currentFocus,
              current.pointNumber != nil,
              case .point(let currentPoint) = gameManager.state else {
            focusPreviousElement()
            return
        }

        // Only actionable point numbers (exclude current point)
        let actionablePoints: [FocusableElement] = [.point4, .point5, .point6, .point8, .point9, .point10]
            .filter { $0.pointNumber != currentPoint }

        guard !actionablePoints.isEmpty else { return }

        if let currentIndex = actionablePoints.firstIndex(of: current) {
            let previousIndex = currentIndex == 0 ? actionablePoints.count - 1 : currentIndex - 1
            setFocus(actionablePoints[previousIndex])
        } else if let last = actionablePoints.last {
            setFocus(last)
        }
    }

    private func setFocus(_ element: FocusableElement) {
        currentFocus = element
        updateFocusRing(for: element)
        print("Focus set to: \(element)")
    }

    private func clearFocus() {
        currentFocus = nil
        focusRing?.isHidden = true
        print("Focus cleared")
    }

    private func activateFocusedElement() {
        guard let focus = currentFocus else { return }

        switch focus {
        case .dice:
            // Trigger dice roll if allowed
            let canRoll: Bool
            if case .point = gameManager.state {
                canRoll = true
            } else {
                canRoll = gameManager.state == .comeOut
            }

            guard canRoll && !isRolling else { return }

            // Simulate dice click by triggering roll
            isRolling = true
            die1.setGlowing(false)
            die2.setGlowing(false)
            SoundManager.shared.playButtonClick()

            let finalValue1 = Die.roll()
            let finalValue2 = Die.roll()
            let total = finalValue1 + finalValue2

            var completedDice = 0
            let diceCompletion = {
                completedDice += 1
                if completedDice == 2 {
                    self.isRolling = false
                    print("Rolled: \(finalValue1) and \(finalValue2) = \(total)")
                    self.gameManager.roll(die1: finalValue1, die2: finalValue2)
                    self.showRollResult(total: total)

                    // Update dice accessibility label
                    let canRollNext = self.gameManager.state == .comeOut || (self.gameManager.state != .waitingForBet && self.gameManager.state != .resolved(won: true) && self.gameManager.state != .resolved(won: false))
                    self.accessibilityManager?.updateDiceLabel(die1: finalValue1, die2: finalValue2, canRoll: canRollNext)

                    self.announceRollResult(die1: finalValue1, die2: finalValue2, total: total)
                    self.updateGameStateBanner()
                    self.updateHintLabel()
                    self.updateUIHints()
                    self.handleRollOutcome()
                }
            }

            die1.roll(to: finalValue1, completion: diceCompletion)
            die2.roll(to: finalValue2, completion: diceCompletion)

        case .passLine:
            // Place Pass Line bet if in waitingForBet state
            guard gameManager.state == .waitingForBet else { return }
            if gameManager.player.placeBet(type: .pass, amount: selectedBetAmount) {
                SoundManager.shared.playChipClick()
                if let passLineArea = crapsTable?.childNode(withName: "passLineArea") {
                    createBetChip(at: passLineArea.position, amount: selectedBetAmount)
                }
                updateBankrollDisplay()
                announceBetPlaced(amount: selectedBetAmount, betType: "Pass Line")
                updateTableAccessibility()
                gameManager.placeBet()
                updateGameStateBanner()
                updateHintLabel()
                updateBetButtonStates()
                updateUIHints()
            }

        case .dontPass:
            // Place Don't Pass bet if in waitingForBet state
            guard gameManager.state == .waitingForBet else { return }
            if gameManager.player.placeBet(type: .dontPass, amount: selectedBetAmount) {
                SoundManager.shared.playChipClick()
                if let dontPassArea = crapsTable?.childNode(withName: "dontPassArea") {
                    createBetChip(at: dontPassArea.position, amount: selectedBetAmount)
                }
                updateBankrollDisplay()
                announceBetPlaced(amount: selectedBetAmount, betType: "Don't Pass")
                updateTableAccessibility()
                gameManager.placeBet()
                updateGameStateBanner()
                updateHintLabel()
                updateBetButtonStates()
                updateUIHints()
            }

        case .point4, .point5, .point6, .point8, .point9, .point10:
            // Place bet on point number during point phase
            if let number = focus.pointNumber {
                handlePlaceBetClick(on: number)
            }

        case .bet25, .bet50, .bet100, .bet500:
            // Select bet amount
            guard let amount = focus.betAmount,
                  gameManager.player.bankroll >= amount else { return }
            selectedBetAmount = amount
            updateBetButtonStates()
            SoundManager.shared.playButtonClick()
            // Announce selection
            NSAccessibility.post(element: self.view as Any, notification: .announcementRequested,
                               userInfo: [.announcement: "Selected $\(amount) bet amount"])
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        // Reposition UI elements when window/scene size changes
        repositionUIElements()
    }

    private func repositionUIElements() {
        let halfHeight = size.height / 2

        // Reposition top elements (banner, hint)
        gameStateBanner?.position.y = halfHeight - 60
        if let bannerBg = childNode(withName: "//bannerBackground") as? SKShapeNode {
            bannerBg.position.y = halfHeight - 60
        }
        hintLabel?.position.y = halfHeight - 130

        // Reposition bottom elements (bankroll, bet buttons)
        bankrollLabel?.position.y = -halfHeight + 30

        // Reposition bet buttons
        let buttonY = -halfHeight + 100
        let amounts = [25, 50, 100, 500]
        let buttonWidth: CGFloat = 100
        let spacing: CGFloat = 20
        let totalWidth = CGFloat(amounts.count) * (buttonWidth + spacing) - spacing
        let startX = -totalWidth / 2 + buttonWidth / 2

        for (index, _) in amounts.enumerated() {
            if index < betButtons.count {
                let xPosition = startX + CGFloat(index) * (buttonWidth + spacing)
                betButtons[index].position = CGPoint(x: xPosition, y: buttonY)
            }
        }

        // Scale game container to fit available space
        // Design size: table is 900x400, with dice adding ~70 above/below
        let designWidth: CGFloat = 900
        let designHeight: CGFloat = 540  // Table + margins for dice/chips

        // Available space (leave room for HUD: 140 top, 140 bottom)
        let hudMargin: CGFloat = 150
        let availableWidth = size.width - 40  // Small horizontal padding
        let availableHeight = size.height - (hudMargin * 2)

        // Calculate scale to fit while maintaining aspect ratio
        let scaleX = availableWidth / designWidth
        let scaleY = availableHeight / designHeight
        let scale = min(scaleX, scaleY, 1.0)  // Don't scale up beyond 1.0

        gameContainer?.setScale(scale)

        // Center the game container vertically in available space
        // Offset slightly toward top since buttons take more visual space
        let centerOffset: CGFloat = -20 * scale
        gameContainer?.position.y = centerOffset
    }
}

