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
        let rollButton = SKLabelNode(text: "Roll Dice")
        rollButton.fontSize = 36
        rollButton.fontColor = .white
        rollButton.name = "rollButton"
        rollButton.position = CGPoint(x: 0, y: -300)
        addChild(rollButton)
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let node = atPoint(location)

        if node.name == "rollButton" {
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
                }
            }

            // Animate both dice
            die1.roll(to: finalValue1, completion: diceCompletion)
            die2.roll(to: finalValue2, completion: diceCompletion)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
