//
//  ViewController.swift
//  Casey Craps
//
//  Created by Matthew Barnson on 12/24/25.
//

import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController {

    @IBOutlet var skView: SKView!
    var accessibilityManager: GameAccessibilityManager?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let view = self.skView as? AccessibleSKView {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") as? GameScene {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .resizeFill

                // Present the scene
                view.presentScene(scene)

                // Set up accessibility
                accessibilityManager = GameAccessibilityManager()
                accessibilityManager?.createElements(for: view, gameScene: scene)
                scene.setAccessibilityManager(accessibilityManager!)

                // Update frames after a brief delay to ensure scene is laid out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.accessibilityManager?.updateFrames(from: scene)
                    // Set initial bankroll label
                    self.accessibilityManager?.updateBankrollLabel(amount: GameManager.shared.player.bankroll)
                }
            }

            view.ignoresSiblingOrder = true

            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    // MARK: - Menu Actions

    @IBAction func newGame(_ sender: Any?) {
        if let view = self.skView,
           let scene = view.scene as? GameScene {
            scene.startNewGame()
        }
    }
}

