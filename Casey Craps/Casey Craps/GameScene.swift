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
    private var rollButton: SKLabelNode!
    private var outcomeLabel: SKLabelNode?
    private var gameStateBanner: SKLabelNode!
    private var selectedBetAmount: Int = 100
    private var betButtons: [SKNode] = []

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

        // Add dice to shooter area (right side of table)
        die1 = DieNode()
        die1.position = CGPoint(x: 250, y: 50)
        addChild(die1)

        die2 = DieNode()
        die2.position = CGPoint(x: 350, y: 50)
        addChild(die2)

        // Add Roll Dice button below the table
        rollButton = SKLabelNode(text: "Roll Dice")
        rollButton.fontSize = 36
        rollButton.fontColor = .gray
        rollButton.name = "rollButton"
        rollButton.position = CGPoint(x: 0, y: -300)
        addChild(rollButton)

        // Add bankroll display at top-left
        bankrollLabel = SKLabelNode(text: "Bankroll: $1,000")
        bankrollLabel.fontSize = 24
        bankrollLabel.fontName = "Arial-BoldMT"
        bankrollLabel.fontColor = .white
        bankrollLabel.horizontalAlignmentMode = .left
        bankrollLabel.position = CGPoint(x: -450, y: 280)
        addChild(bankrollLabel)
        updateBankrollDisplay()

        // Add game state banner at top center
        gameStateBanner = SKLabelNode(text: "PLACE YOUR BET")
        gameStateBanner.fontSize = 48
        gameStateBanner.fontName = "Arial-BoldMT"
        gameStateBanner.fontColor = .yellow
        gameStateBanner.verticalAlignmentMode = .center
        gameStateBanner.position = CGPoint(x: 0, y: 280)
        gameStateBanner.zPosition = 10

        // Add shadow effect with background panel
        let bannerBackground = SKShapeNode(rectOf: CGSize(width: 600, height: 80), cornerRadius: 10)
        bannerBackground.fillColor = SKColor(white: 0, alpha: 0.6)
        bannerBackground.strokeColor = .yellow
        bannerBackground.lineWidth = 3
        bannerBackground.position = CGPoint(x: 0, y: 280)
        bannerBackground.zPosition = 9
        addChild(bannerBackground)
        addChild(gameStateBanner)

        updateGameStateBanner()

        // Add bet amount controls
        createBetAmountButtons()
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

                // Update bet button states (hide them after bet placed)
                updateBetButtonStates()

                // Enable roll button
                rollButton.fontColor = .white
            }
        }

        if node.name == "rollButton" {
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

                    // Update game state banner
                    self.updateGameStateBanner()

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
        switch gameManager.state {
        case .resolved(let won):
            // Show outcome feedback
            showOutcomeLabel(won: won)

            // Update bankroll display
            updateBankrollDisplay()

            // Disable roll button
            rollButton.fontColor = .gray

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

                // Update bet button states (show them again)
                self.updateBetButtonStates()
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

    private func createBetChip(at position: CGPoint, amount: Int) {
        // Remove existing chip if any
        betChip?.removeFromParent()

        // Create chip node
        let chipRadius: CGFloat = 25
        let chip = SKShapeNode(circleOfRadius: chipRadius)
        chip.fillColor = SKColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
        chip.strokeColor = .white
        chip.lineWidth = 3
        chip.position = position

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

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
