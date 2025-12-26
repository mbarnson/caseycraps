//
//  DieNode.swift
//  Casey Craps
//
//  Created by Matthew Barnson on 12/24/25.
//

import SpriteKit
import AppKit

class DieNode: SKNode {

    // MARK: - Properties

    private var value: Int = 1
    private let dieSize: CGFloat = 70
    private let dieColor: SKColor = SKColor(white: 0.95, alpha: 1.0) // Ivory white
    private let dotColor: SKColor = .black
    private let dotRadius: CGFloat = 5

    private var dieBody: SKShapeNode!
    private var dotsContainer: SKNode!

    // MARK: - Initialization

    override init() {
        super.init()
        setupDie()
        layoutDots()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDie()
        layoutDots()
    }

    // MARK: - Setup

    private func setupDie() {
        // Create the die body as a rounded rectangle
        let cornerRadius: CGFloat = 8
        let rect = CGRect(x: -dieSize/2, y: -dieSize/2, width: dieSize, height: dieSize)
        dieBody = SKShapeNode(rect: rect, cornerRadius: cornerRadius)
        dieBody.fillColor = dieColor
        dieBody.strokeColor = SKColor(white: 0.3, alpha: 1.0)
        dieBody.lineWidth = 2
        addChild(dieBody)

        // Container for dots
        dotsContainer = SKNode()
        addChild(dotsContainer)
    }

    // MARK: - Public Methods

    /// Update the die to show a new value
    /// - Parameter newValue: The new value to display (1-6)
    func setValue(_ newValue: Int) {
        guard (1...6).contains(newValue) else { return }
        value = newValue
        layoutDots()
    }

    /// Set whether the die should have a glowing/pulsing outline
    /// - Parameter glowing: true to add pulse animation, false to remove
    func setGlowing(_ glowing: Bool) {
        let actionKey = "dieGlow"
        dieBody.removeAction(forKey: actionKey)

        if glowing {
            // Check for Reduce Motion preference
            if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
                // Static gold border instead of pulse
                dieBody.strokeColor = SKColor(red: 0.9, green: 0.75, blue: 0.2, alpha: 1.0)
                dieBody.lineWidth = 4
            } else {
                // Pulsing gold outline (original animation)
                let glowUp = SKAction.customAction(withDuration: 0.6) { node, elapsed in
                    guard let shape = node as? SKShapeNode else { return }
                    let progress = elapsed / 0.6
                    let width = 2.0 + 3.0 * sin(CGFloat(progress) * .pi)
                    shape.lineWidth = width
                    let blend = sin(CGFloat(progress) * .pi)
                    shape.strokeColor = SKColor(
                        red: 0.3 + 0.6 * blend,
                        green: 0.3 + 0.45 * blend,
                        blue: 0.3 - 0.1 * blend,
                        alpha: 1.0
                    )
                }
                let glowDown = SKAction.customAction(withDuration: 0.6) { node, elapsed in
                    guard let shape = node as? SKShapeNode else { return }
                    let progress = elapsed / 0.6
                    let width = 5.0 - 3.0 * sin(CGFloat(progress) * .pi)
                    shape.lineWidth = width
                    let blend = 1.0 - sin(CGFloat(progress) * .pi)
                    shape.strokeColor = SKColor(
                        red: 0.9 - 0.6 * (1.0 - blend),
                        green: 0.75 - 0.45 * (1.0 - blend),
                        blue: 0.2 + 0.1 * (1.0 - blend),
                        alpha: 1.0
                    )
                }
                let pulse = SKAction.sequence([glowUp, glowDown])
                dieBody.run(SKAction.repeatForever(pulse), withKey: actionKey)
            }
        } else {
            // Reset to normal
            dieBody.strokeColor = SKColor(white: 0.3, alpha: 1.0)
            dieBody.lineWidth = 2
        }
    }

    /// Animate the die rolling and settle on a final value
    /// - Parameters:
    ///   - finalValue: The value to settle on (1-6)
    ///   - completion: Closure to call when animation completes
    func roll(to finalValue: Int, completion: @escaping () -> Void) {
        guard (1...6).contains(finalValue) else {
            completion()
            return
        }

        // Play dice rolling sound (always plays)
        SoundManager.shared.playDiceRoll()

        // Check for Reduce Motion preference
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            // Immediate result, no animation
            setValue(finalValue)
            completion()
            return
        }

        // Animation parameters (original animation)
        let initialPulseDuration: TimeInterval = 0.1
        let tumbleDuration: TimeInterval = 0.8
        let numberOfTumbles = 8
        let tumbleInterval = tumbleDuration / Double(numberOfTumbles)
        let settleDuration: TimeInterval = 0.3

        var actions: [SKAction] = []

        // 1. Initial pulse - excitement
        let scaleUp = SKAction.scale(to: 1.15, duration: initialPulseDuration)
        let scaleDown = SKAction.scale(to: 1.0, duration: initialPulseDuration)
        actions.append(SKAction.sequence([scaleUp, scaleDown]))

        // 2. Tumble - rapid value changes with rotation wobble
        var tumbleActions: [SKAction] = []
        for _ in 0..<numberOfTumbles {
            let randomValue = Int.random(in: 1...6)
            let changeValue = SKAction.run { [weak self] in
                self?.setValue(randomValue)
            }
            let rotateLeft = SKAction.rotate(byAngle: CGFloat.pi / 8, duration: tumbleInterval / 2)
            let rotateRight = SKAction.rotate(byAngle: -CGFloat.pi / 8, duration: tumbleInterval / 2)
            let wobble = SKAction.sequence([rotateLeft, rotateRight])
            tumbleActions.append(SKAction.group([changeValue, wobble]))
        }
        actions.append(SKAction.sequence(tumbleActions))

        // 3. Settle - slight bounce and set final value
        let setFinal = SKAction.run { [weak self] in
            self?.setValue(finalValue)
        }
        let bounceUp = SKAction.scale(to: 1.1, duration: settleDuration / 2)
        bounceUp.timingMode = .easeOut
        let bounceDown = SKAction.scale(to: 1.0, duration: settleDuration / 2)
        bounceDown.timingMode = .easeIn
        let settle = SKAction.sequence([bounceUp, bounceDown])
        actions.append(SKAction.group([setFinal, settle]))

        // 4. Call completion
        actions.append(SKAction.run(completion))

        // Run the entire sequence
        let rollSequence = SKAction.sequence(actions)
        run(rollSequence)
    }

    // MARK: - Private Methods

    /// Layout dots based on current value
    private func layoutDots() {
        // Clear existing dots
        dotsContainer.removeAllChildren()

        let spacing: CGFloat = dieSize * 0.35 // Distance from center to corner dots

        // Dot positions for standard die patterns
        let center = CGPoint(x: 0, y: 0)
        let topLeft = CGPoint(x: -spacing, y: spacing)
        let topRight = CGPoint(x: spacing, y: spacing)
        let middleLeft = CGPoint(x: -spacing, y: 0)
        let middleRight = CGPoint(x: spacing, y: 0)
        let bottomLeft = CGPoint(x: -spacing, y: -spacing)
        let bottomRight = CGPoint(x: spacing, y: -spacing)

        var dotPositions: [CGPoint] = []

        switch value {
        case 1:
            dotPositions = [center]
        case 2:
            dotPositions = [topRight, bottomLeft]
        case 3:
            dotPositions = [topRight, center, bottomLeft]
        case 4:
            dotPositions = [topLeft, topRight, bottomLeft, bottomRight]
        case 5:
            dotPositions = [topLeft, topRight, center, bottomLeft, bottomRight]
        case 6:
            dotPositions = [topLeft, topRight, middleLeft, middleRight, bottomLeft, bottomRight]
        default:
            break
        }

        // Create dot nodes
        for position in dotPositions {
            let dot = SKShapeNode(circleOfRadius: dotRadius)
            dot.fillColor = dotColor
            dot.strokeColor = dotColor
            dot.position = position
            dotsContainer.addChild(dot)
        }
    }
}
