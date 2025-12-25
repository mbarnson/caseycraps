//
//  GameScene.swift
//  Casey Craps
//
//  Created by Matthew Barnson on 12/24/25.
//

import SpriteKit
import GameplayKit

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

    override func didMove(to view: SKView) {
        // Remove template nodes from .sks file
        childNode(withName: "//helloLabel")?.removeFromParent()

        // Set casino felt background color
        backgroundColor = SKColor(red: 0.05, green: 0.36, blue: 0.05, alpha: 1.0)

        // Print current game state
        print("Game State: \(gameManager.state)")

        // Add craps table
        let table = CrapsTableNode()
        table.position = CGPoint(x: 0, y: 0)
        addChild(table)
        crapsTable = table

        // Add dice to center of table (below point numbers, above pass line)
        die1 = DieNode()
        die1.position = CGPoint(x: -50, y: 20)
        addChild(die1)

        die2 = DieNode()
        die2.position = CGPoint(x: 50, y: 20)
        addChild(die2)

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

        // Add roll result label (initially hidden)
        rollResultLabel = SKLabelNode(text: "")
        rollResultLabel.fontSize = 66
        rollResultLabel.fontName = "Arial-BoldMT"
        rollResultLabel.verticalAlignmentMode = .center
        rollResultLabel.position = CGPoint(x: 0, y: 0)
        rollResultLabel.zPosition = 101
        rollResultLabel.alpha = 0
        addChild(rollResultLabel)

        // Add bet amount controls
        createBetAmountButtons()

        // Initial UI hints
        updateUIHints()
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
            if won {
                gameStateBanner.text = "WINNER!"
                gameStateBanner.fontColor = .green
            } else {
                // Check if it was a seven-out
                if case .resolved = gameManager.state,
                   let bet = gameManager.player.currentBet,
                   bet.type == .pass,
                   gameManager.pointValue == nil {
                    gameStateBanner.text = "SEVEN OUT"
                    gameStateBanner.fontColor = .red
                } else {
                    gameStateBanner.text = "LOSER"
                    gameStateBanner.fontColor = .red
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

        for (index, amount) in amounts.enumerated() {
            if index < betButtons.count, let button = betButtons[index] as? SKShapeNode {
                let canAfford = bankroll >= amount
                let isSelected = amount == selectedBetAmount

                // Only show buttons in waitingForBet state
                button.isHidden = !isWaitingForBet

                if isWaitingForBet {
                    if !canAfford {
                        // Gray out unaffordable amounts
                        button.fillColor = SKColor(white: 0.3, alpha: 0.5)
                        button.strokeColor = SKColor(white: 0.5, alpha: 0.5)
                        if let label = button.children.first as? SKLabelNode {
                            label.fontColor = SKColor(white: 0.6, alpha: 1.0)
                        }
                    } else if isSelected {
                        // Highlight selected amount
                        button.fillColor = SKColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 1.0)
                        button.strokeColor = .yellow
                        button.lineWidth = 4
                        if let label = button.children.first as? SKLabelNode {
                            label.fontColor = .white
                        }
                    } else {
                        // Normal state
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
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let node = atPoint(location)

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
                handlePlaceBetClick(on: number)
            }
            return
        }

        // Handle betting area clicks
        if (node.name == "passLineArea" || node.name == "dontPassArea") && gameManager.state == .waitingForBet {
            let betType: BetType = node.name == "passLineArea" ? .pass : .dontPass
            let betAmount = selectedBetAmount

            // Place bet with player
            if gameManager.player.placeBet(type: betType, amount: betAmount) {
                // Play chip click sound
                SoundManager.shared.playChipClick()

                // Create and display chip
                createBetChip(at: node.position, amount: betAmount)

                // Update bankroll display
                updateBankrollDisplay()

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

    private func handleRollOutcome() {
        // Check for place bet winnings first
        if gameManager.lastPlaceBetWinnings > 0, let winningNumber = gameManager.lastPlaceBetWinningNumber {
            // Show place bet winnings
            showPlaceBetWinnings(amount: gameManager.lastPlaceBetWinnings, on: winningNumber)

            // Remove the winning chip
            removePlaceChip(from: winningNumber)

            // Play win sound for place bet
            SoundManager.shared.playWinSound()

            // Update bankroll display
            updateBankrollDisplay()
        }

        switch gameManager.state {
        case .resolved(let won):
            // All place bets lose on seven out - remove chips
            removeAllPlaceChips()

            // Show outcome feedback
            showOutcomeLabel(won: won)

            // Update bankroll display
            updateBankrollDisplay()

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

                // Update bankroll display
                self.updateBankrollDisplay()

                // Update game state banner
                self.updateGameStateBanner()

                // Update hint label
                self.updateHintLabel()

                // Update bet button states (show them again)
                self.updateBetButtonStates()

                // Update UI hints (highlights betting areas again)
                self.updateUIHints()
            }
            run(SKAction.sequence([waitAction, resetAction]))

        case .point(let pointValue):
            print("Point is \(pointValue)")
            // Play point established sound
            SoundManager.shared.playPointEstablished()
            // Update puck to show ON at the point number
            crapsTable?.setPuckPosition(point: pointValue)
            // Bet chip stays on table for point phase

        default:
            break
        }
    }

    private func showPlaceBetWinnings(amount: Int, on number: Int) {
        // Get position of the number box
        guard let position = crapsTable?.getPointBoxPosition(number: number) else { return }

        // Create floating winnings label
        let winLabel = SKLabelNode(text: "+$\(amount)")
        winLabel.fontSize = 28
        winLabel.fontName = "Arial-BoldMT"
        winLabel.fontColor = .green
        winLabel.position = CGPoint(x: position.x, y: position.y - 40)
        winLabel.zPosition = 200
        crapsTable?.addChild(winLabel)

        // Animate floating up and fading out
        let moveUp = SKAction.moveBy(x: 0, y: 60, duration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let group = SKAction.group([moveUp, fadeOut])
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([group, remove])
        winLabel.run(sequence)
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

        // Create outcome label
        let label = SKLabelNode(text: labelText)
        label.fontSize = 72
        label.fontName = "Arial-BoldMT"
        label.fontColor = won ? .green : .red
        label.position = CGPoint(x: 0, y: 100)
        label.zPosition = 100
        addChild(label)
        outcomeLabel = label

        // Add pulsing animation
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.3)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.3)
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        label.run(SKAction.repeatForever(pulse))
    }

    private func showRollResult(total: Int) {
        // Determine color based on game state and bet type
        let betType = gameManager.player.currentBet?.type ?? .pass
        var color: SKColor
        var isWinning = false
        var isLosing = false

        switch gameManager.state {
        case .resolved(let won):
            // Resolved state - show green for win, red for loss
            if won {
                color = .green
                isWinning = true
            } else {
                color = .red
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

        // Hold duration depends on outcome type
        let holdDuration: TimeInterval
        if isWinning || isLosing {
            // Win/loss: hold for 1 second
            holdDuration = 1.0
        } else {
            // Point set: fade faster (0.6 seconds)
            holdDuration = 0.6
        }

        let wait = SKAction.wait(forDuration: holdDuration)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)

        let sequence = SKAction.sequence([popIn, wait, fadeOut])
        rollResultLabel.run(sequence)
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

    private func handlePlaceBetClick(on number: Int) {
        // Must be in point phase to interact with place bets
        guard case .point = gameManager.state else {
            print("Can only place/remove bets during point phase")
            return
        }

        // Check if player already has a bet on this number - if so, take it down
        if gameManager.player.hasPlaceBet(on: number) {
            let returned = gameManager.player.takeDownPlaceBet(number: number)
            if returned > 0 {
                // Play chip click sound
                SoundManager.shared.playChipClick()

                // Remove the chip
                removePlaceChip(from: number)

                // Update bankroll display
                updateBankrollDisplay()

                print("Took down $\(returned) from \(number)")
            }
            return
        }

        // Otherwise, try to place a new bet
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

        // Place the bet
        if gameManager.player.placePlaceBet(number: number, amount: selectedBetAmount) {
            // Play chip click sound
            SoundManager.shared.playChipClick()

            // Create and display chip on the number
            createPlaceChip(on: number, amount: selectedBetAmount)

            // Update bankroll display
            updateBankrollDisplay()

            // Update hint label to mention place bets
            updateHintLabel()

            print("Placed $\(selectedBetAmount) on \(number)")
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

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
