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
    }

    private func updateBankrollDisplay() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        let formattedBankroll = formatter.string(from: NSNumber(value: gameManager.player.bankroll)) ?? "0"
        bankrollLabel.text = "Bankroll: $\(formattedBankroll)"
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let node = atPoint(location)

        // Handle betting area clicks
        if (node.name == "passLineArea" || node.name == "dontPassArea") && gameManager.state == .waitingForBet {
            let betType: BetType = node.name == "passLineArea" ? .pass : .dontPass
            let betAmount = 100

            // Place bet with player
            if gameManager.player.placeBet(type: betType, amount: betAmount) {
                // Create and display chip
                createBetChip(at: node.position, amount: betAmount)

                // Update bankroll display
                updateBankrollDisplay()

                // Transition game state
                gameManager.placeBet()

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
            }
            run(SKAction.sequence([waitAction, resetAction]))

        case .point(let pointValue):
            print("Point is \(pointValue)")
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
