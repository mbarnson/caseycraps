//
//  AccessibleSKView.swift
//  Casey Craps
//
//  Created by Matthew Barnson on 12/25/25.
//

import SpriteKit
import AppKit

class AccessibleSKView: SKView {
    private var accessibilityElements: [NSAccessibilityElement] = []

    override func accessibilityChildren() -> [Any]? {
        return accessibilityElements
    }

    override func accessibilityHitTest(_ point: NSPoint) -> Any? {
        // Convert point to view coordinates and find element
        for element in accessibilityElements {
            let frame = element.accessibilityFrame()
            if frame.contains(point) {
                return element
            }
        }
        return super.accessibilityHitTest(point)
    }

    func updateAccessibilityElements(_ elements: [NSAccessibilityElement]) {
        self.accessibilityElements = elements
        NSAccessibility.post(element: self, notification: .layoutChanged)
    }
}

class GameAccessibilityManager {
    weak var view: AccessibleSKView?

    // Element references for updates
    var diceElement: NSAccessibilityElement?
    var passLineElement: NSAccessibilityElement?
    var dontPassElement: NSAccessibilityElement?
    var pointElements: [Int: NSAccessibilityElement] = [:]  // 4,5,6,8,9,10
    var betButtonElements: [Int: NSAccessibilityElement] = [:]  // Amount -> Element
    var bankrollElement: NSAccessibilityElement?

    func createElements(for view: AccessibleSKView, gameScene: GameScene) {
        self.view = view
        var elements: [NSAccessibilityElement] = []

        // Dice (combined as single clickable element)
        let dice = NSAccessibilityElement()
        dice.setAccessibilityParent(view)
        dice.setAccessibilityRole(.button)
        dice.setAccessibilityLabel("Dice")
        dice.setAccessibilityHelp("Double-click to roll dice")
        // Frame will be set by updateFrames()
        diceElement = dice
        elements.append(dice)

        // Pass Line
        let passLine = NSAccessibilityElement()
        passLine.setAccessibilityParent(view)
        passLine.setAccessibilityRole(.button)
        passLine.setAccessibilityLabel("Pass Line bet area")
        passLine.setAccessibilityHelp("Double-click to place Pass Line bet")
        passLineElement = passLine
        elements.append(passLine)

        // Don't Pass
        let dontPass = NSAccessibilityElement()
        dontPass.setAccessibilityParent(view)
        dontPass.setAccessibilityRole(.button)
        dontPass.setAccessibilityLabel("Don't Pass bet area")
        dontPass.setAccessibilityHelp("Double-click to place Don't Pass bet")
        dontPassElement = dontPass
        elements.append(dontPass)

        // Point numbers (4, 5, 6, 8, 9, 10)
        let pointNumbers = [4, 5, 6, 8, 9, 10]
        let odds = [4: "9 to 5", 5: "7 to 5", 6: "7 to 6", 8: "7 to 6", 9: "7 to 5", 10: "9 to 5"]
        for num in pointNumbers {
            let point = NSAccessibilityElement()
            point.setAccessibilityParent(view)
            point.setAccessibilityRole(.button)
            point.setAccessibilityLabel("Place bet on \(num)")
            point.setAccessibilityHelp("Double-click to place bet, pays \(odds[num]!)")
            pointElements[num] = point
            elements.append(point)
        }

        // Bet amount buttons ($25, $50, $100, $500)
        let amounts = [25, 50, 100, 500]
        for amount in amounts {
            let button = NSAccessibilityElement()
            button.setAccessibilityParent(view)
            button.setAccessibilityRole(.button)
            button.setAccessibilityLabel("Bet $\(amount)")
            button.setAccessibilityHelp("Double-click to select bet amount")
            betButtonElements[amount] = button
            elements.append(button)
        }

        // Bankroll display (read-only)
        let bankroll = NSAccessibilityElement()
        bankroll.setAccessibilityParent(view)
        bankroll.setAccessibilityRole(.staticText)
        bankroll.setAccessibilityLabel("Bankroll")
        bankrollElement = bankroll
        elements.append(bankroll)

        view.updateAccessibilityElements(elements)
    }

    func updateFrames(from gameScene: GameScene) {
        // Convert SKNode positions to screen coordinates
        guard let view = self.view,
              let window = view.window else { return }

        // Helper function to convert scene coordinates to screen coordinates
        func sceneToScreen(point: CGPoint, size: CGSize) -> NSRect {
            // Convert scene point to view coordinates
            let viewPoint = gameScene.convertPoint(toView: point)

            // Convert view point to window coordinates
            let windowPoint = view.convert(viewPoint, to: nil)

            // Convert window point to screen coordinates
            var screenRect = NSRect(origin: windowPoint, size: size)
            screenRect.origin = window.convertToScreen(screenRect).origin

            return screenRect
        }

        // Update dice element (cover both dice)
        if let die1 = gameScene.childNode(withName: "//die1") as? SKNode,
           let die2 = gameScene.childNode(withName: "//die2") as? SKNode {
            // Calculate bounds that cover both dice
            let leftX = min(die1.position.x, die2.position.x) - 30
            let rightX = max(die1.position.x, die2.position.x) + 30
            let width = rightX - leftX
            let centerX = (leftX + rightX) / 2
            let centerY = (die1.position.y + die2.position.y) / 2

            let frame = sceneToScreen(point: CGPoint(x: centerX, y: centerY), size: CGSize(width: width, height: 60))
            diceElement?.setAccessibilityFrame(frame)
        }

        // Update betting areas - use approximate positions based on typical layout
        // Pass Line area
        let passLineFrame = sceneToScreen(point: CGPoint(x: -100, y: -120), size: CGSize(width: 250, height: 60))
        passLineElement?.setAccessibilityFrame(passLineFrame)

        // Don't Pass area
        let dontPassFrame = sceneToScreen(point: CGPoint(x: 100, y: -120), size: CGSize(width: 250, height: 60))
        dontPassElement?.setAccessibilityFrame(dontPassFrame)

        // Update point number frames
        let pointPositions: [Int: CGPoint] = [
            4: CGPoint(x: -240, y: 80),
            5: CGPoint(x: -160, y: 80),
            6: CGPoint(x: -80, y: 80),
            8: CGPoint(x: 80, y: 80),
            9: CGPoint(x: 160, y: 80),
            10: CGPoint(x: 240, y: 80)
        ]

        for (number, position) in pointPositions {
            let frame = sceneToScreen(point: position, size: CGSize(width: 70, height: 70))
            pointElements[number]?.setAccessibilityFrame(frame)
        }

        // Update bet button frames
        let buttonAmounts = [25, 50, 100, 500]
        let buttonWidth: CGFloat = 100
        let spacing: CGFloat = 20
        let totalWidth = CGFloat(buttonAmounts.count) * (buttonWidth + spacing) - spacing
        let startX = -totalWidth / 2 + buttonWidth / 2
        let yPosition: CGFloat = -250

        for (index, amount) in buttonAmounts.enumerated() {
            let xPosition = startX + CGFloat(index) * (buttonWidth + spacing)
            let frame = sceneToScreen(point: CGPoint(x: xPosition, y: yPosition), size: CGSize(width: buttonWidth, height: 50))
            betButtonElements[amount]?.setAccessibilityFrame(frame)
        }

        // Update bankroll frame
        let bankrollFrame = sceneToScreen(point: CGPoint(x: 0, y: -350), size: CGSize(width: 300, height: 40))
        bankrollElement?.setAccessibilityFrame(bankrollFrame)
    }

    func updateBankrollValue(_ value: String) {
        bankrollElement?.setAccessibilityValue(value)
    }

    func updateBetButtonState(amount: Int, enabled: Bool, selected: Bool) {
        guard let button = betButtonElements[amount] else { return }

        button.setAccessibilityEnabled(enabled)
        if selected {
            button.setAccessibilityLabel("Bet $\(amount) - Selected")
        } else {
            button.setAccessibilityLabel("Bet $\(amount)")
        }
    }

    func updateDiceState(canRoll: Bool) {
        diceElement?.setAccessibilityEnabled(canRoll)
        if canRoll {
            diceElement?.setAccessibilityHelp("Double-click to roll dice")
        } else {
            diceElement?.setAccessibilityHelp("Place a bet first")
        }
    }
}
