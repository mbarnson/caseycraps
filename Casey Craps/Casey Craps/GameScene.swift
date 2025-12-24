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

    override func didMove(to view: SKView) {
        // Remove template nodes from .sks file
        childNode(withName: "//helloLabel")?.removeFromParent()

        // Set casino felt background color
        backgroundColor = SKColor(red: 0.05, green: 0.36, blue: 0.05, alpha: 1.0)

        // Print current game state
        print("Game State: \(gameManager.state)")

        // Add Roll Dice button
        let rollButton = SKLabelNode(text: "Roll Dice")
        rollButton.fontSize = 48
        rollButton.fontColor = .white
        rollButton.name = "rollButton"
        rollButton.position = CGPoint(x: 0, y: 0)
        addChild(rollButton)
    }

    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let node = atPoint(location)

        if node.name == "rollButton" {
            let die1 = Die.roll()
            let die2 = Die.roll()
            print("Rolled: \(die1) and \(die2) = \(die1 + die2)")
        }
    }

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
