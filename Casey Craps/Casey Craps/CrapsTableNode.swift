//
//  CrapsTableNode.swift
//  Casey Craps
//
//  Created by Matthew Barnson on 12/24/25.
//

import SpriteKit

/// A visual representation of a craps table with betting areas and point indicators
class CrapsTableNode: SKNode {

    // MARK: - Properties

    private let tableWidth: CGFloat = 900
    private let tableHeight: CGFloat = 400

    private let feltGreen = SKColor(red: 0x0d/255.0, green: 0x5c/255.0, blue: 0x0d/255.0, alpha: 1.0)
    private let borderGold = SKColor(red: 0xc9/255.0, green: 0xa2/255.0, blue: 0x27/255.0, alpha: 1.0)

    private var puckNode: SKShapeNode?
    private var puckLabel: SKLabelNode?
    private var pointBoxes: [Int: SKShapeNode] = [:]
    private var passLineArea: SKShapeNode?
    private var dontPassArea: SKShapeNode?
    private var currentPoint: Int?

    // MARK: - Initialization

    override init() {
        super.init()
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }

    // MARK: - Setup

    private func setupLayout() {
        // Create felt background with rounded corners
        let feltBackground = SKShapeNode(rectOf: CGSize(width: tableWidth, height: tableHeight), cornerRadius: 20)
        feltBackground.fillColor = feltGreen
        feltBackground.strokeColor = borderGold
        feltBackground.lineWidth = 8
        feltBackground.position = .zero
        addChild(feltBackground)

        // Add betting areas
        addPassLineArea()
        addDontPassArea()
        addPointNumbers()
        addPuck()
    }

    private func addPassLineArea() {
        // Pass Line - large curved band along bottom
        let passLineHeight: CGFloat = 60
        let passLineY = -tableHeight/2 + passLineHeight/2 + 10

        let passLine = SKShapeNode(rectOf: CGSize(width: tableWidth - 40, height: passLineHeight), cornerRadius: 30)
        passLine.fillColor = .clear
        passLine.strokeColor = .white
        passLine.lineWidth = 3
        passLine.position = CGPoint(x: 0, y: passLineY)
        passLine.name = "passLineArea"
        passLine.isAccessibilityElement = true
        passLine.accessibilityRole = NSAccessibility.Role.button.rawValue
        passLine.accessibilityLabel = "Pass Line bet area"
        passLine.accessibilityHelp = "Double-click to place Pass Line bet"
        addChild(passLine)
        passLineArea = passLine

        // Pass Line label (same name for click detection)
        let passLineLabel = SKLabelNode(text: "PASS LINE")
        passLineLabel.fontSize = 24
        passLineLabel.fontName = "Arial-BoldMT"
        passLineLabel.fontColor = .white
        passLineLabel.verticalAlignmentMode = .center
        passLineLabel.position = CGPoint(x: 0, y: passLineY)
        passLineLabel.name = "passLineArea"
        addChild(passLineLabel)
    }

    private func addDontPassArea() {
        // Don't Pass Bar - smaller area above pass line
        let dontPassHeight: CGFloat = 40
        let dontPassY = -tableHeight/2 + 90

        let dontPass = SKShapeNode(rectOf: CGSize(width: 300, height: dontPassHeight), cornerRadius: 5)
        dontPass.fillColor = SKColor(white: 0.2, alpha: 0.3)
        dontPass.strokeColor = .yellow
        dontPass.lineWidth = 2
        dontPass.position = CGPoint(x: -tableWidth/2 + 170, y: dontPassY)
        dontPass.name = "dontPassArea"
        dontPass.isAccessibilityElement = true
        dontPass.accessibilityRole = NSAccessibility.Role.button.rawValue
        dontPass.accessibilityLabel = "Don't Pass bet area"
        dontPass.accessibilityHelp = "Double-click to place Don't Pass bet"
        addChild(dontPass)
        dontPassArea = dontPass

        // Don't Pass Bar label (same name for click detection)
        let dontPassLabel = SKLabelNode(text: "DON'T PASS BAR")
        dontPassLabel.fontSize = 14
        dontPassLabel.fontName = "Arial-BoldMT"
        dontPassLabel.fontColor = .yellow
        dontPassLabel.verticalAlignmentMode = .center
        dontPassLabel.position = CGPoint(x: -tableWidth/2 + 170, y: dontPassY)
        dontPassLabel.name = "dontPassArea"
        addChild(dontPassLabel)
    }

    private func addPointNumbers() {
        // Point numbers displayed across the top: 4, 5, SIX, 8, NINE, 10
        let pointNumbers = [4, 5, 6, 8, 9, 10]
        let boxWidth: CGFloat = 80
        let boxHeight: CGFloat = 60
        let spacing: CGFloat = 20
        let totalWidth = CGFloat(pointNumbers.count) * (boxWidth + spacing) - spacing
        let startX = -totalWidth / 2 + boxWidth / 2
        let yPosition: CGFloat = tableHeight/2 - 100

        for (index, number) in pointNumbers.enumerated() {
            let xPosition = startX + CGFloat(index) * (boxWidth + spacing)

            // Create point box
            let box = SKShapeNode(rectOf: CGSize(width: boxWidth, height: boxHeight), cornerRadius: 5)
            box.fillColor = .clear
            box.strokeColor = .white
            box.lineWidth = 2
            box.position = CGPoint(x: xPosition, y: yPosition)
            box.name = "placeNumber\(number)"
            box.isAccessibilityElement = true
            box.accessibilityRole = NSAccessibility.Role.button.rawValue
            box.accessibilityLabel = "Place bet on \(number)"
            updatePointBoxAccessibility(box: box, number: number)
            addChild(box)
            pointBoxes[number] = box

            // Create label (use words for 6 and 9, numbers for others)
            let labelText: String
            switch number {
            case 6:
                labelText = "SIX"
            case 9:
                labelText = "NINE"
            default:
                labelText = "\(number)"
            }

            let label = SKLabelNode(text: labelText)
            label.fontSize = 28
            label.fontName = "Arial-BoldMT"
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: xPosition, y: yPosition)
            label.name = "placeNumber\(number)"  // Same name for click detection
            addChild(label)
        }
    }

    private func addPuck() {
        // Create puck (OFF/ON indicator) - sized to fit on point box
        let puckRadius: CGFloat = 35
        puckNode = SKShapeNode(circleOfRadius: puckRadius)
        puckNode?.fillColor = .black
        puckNode?.strokeColor = .white
        puckNode?.lineWidth = 3
        puckNode?.isHidden = true // Start hidden
        puckNode?.zPosition = 100  // Above everything else
        addChild(puckNode!)

        // Create puck label
        puckLabel = SKLabelNode(text: "OFF")
        puckLabel?.fontSize = 18
        puckLabel?.fontName = "Arial-BoldMT"
        puckLabel?.fontColor = .white
        puckLabel?.verticalAlignmentMode = .center
        puckNode?.addChild(puckLabel!)

        // Add accessibility to puck
        puckNode?.isAccessibilityElement = true
        puckNode?.accessibilityRole = NSAccessibility.Role.staticText.rawValue
        puckNode?.accessibilityLabel = "Point marker: OFF"
    }

    // MARK: - Public Methods

    /// Get the position of a point number box (for placing chips)
    /// - Parameter number: The point number (4, 5, 6, 8, 9, 10)
    /// - Returns: The position of the box, or nil if invalid number
    func getPointBoxPosition(number: Int) -> CGPoint? {
        return pointBoxes[number]?.position
    }

    /// Get the frame of the Pass Line betting area
    /// - Returns: The frame of the Pass Line area in the table's coordinate space
    func getPassLineFrame() -> CGRect {
        guard let passLineArea = passLineArea else {
            return CGRect(x: -215, y: -120, width: 430, height: 60)
        }
        return passLineArea.frame
    }

    /// Get the frame of the Don't Pass betting area
    /// - Returns: The frame of the Don't Pass area in the table's coordinate space
    func getDontPassFrame() -> CGRect {
        guard let dontPassArea = dontPassArea else {
            return CGRect(x: -265, y: -110, width: 300, height: 40)
        }
        return dontPassArea.frame
    }

    /// Get the frame of a point number box
    /// - Parameter number: The point number (4, 5, 6, 8, 9, 10)
    /// - Returns: The frame of the point box in the table's coordinate space
    func getPointBoxFrame(number: Int) -> CGRect {
        guard let box = pointBoxes[number] else {
            return .zero
        }
        return box.frame
    }

    /// Set the puck position to indicate the current point
    /// - Parameter point: The point number (4, 5, 6, 8, 9, 10) or nil for OFF
    func setPuckPosition(point: Int?) {
        guard let puckNode = puckNode, let puckLabel = puckLabel else { return }

        currentPoint = point

        if let point = point, let box = pointBoxes[point] {
            // Show puck ON the point with bright white background
            let targetPosition = box.position

            // Animate puck movement
            puckNode.removeAllActions()
            let moveAction = SKAction.move(to: targetPosition, duration: 0.3)
            moveAction.timingMode = .easeInEaseOut

            // Scale up animation
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.15)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
            let scaleSequence = SKAction.sequence([scaleUp, scaleDown])

            // Run animations together
            let group = SKAction.group([moveAction, scaleSequence])

            // Update appearance for ON state
            puckNode.fillColor = .white
            puckNode.strokeColor = .black
            puckLabel.text = "ON"
            puckLabel.fontColor = .black
            puckNode.isHidden = false

            // Update accessibility
            puckNode.accessibilityLabel = "Point marker: ON \(point)"

            // Update accessibility for point boxes
            updateAllPointBoxAccessibility()

            puckNode.run(group)
        } else {
            // Show puck as OFF (black with white text) or hide it
            puckNode.fillColor = .black
            puckNode.strokeColor = .white
            puckLabel.text = "OFF"
            puckLabel.fontColor = .white
            puckNode.isHidden = true

            // Update accessibility
            puckNode.accessibilityLabel = "Point marker: OFF"

            // Update accessibility for point boxes
            updateAllPointBoxAccessibility()
        }
    }

    /// Highlight or unhighlight the Pass Line and Don't Pass betting areas
    /// - Parameter highlight: true to add glow effect, false to remove
    func highlightBettingAreas(_ highlight: Bool) {
        let actionKey = "bettingGlow"

        if highlight {
            // Add pulsing glow to pass line
            let glowUp = SKAction.customAction(withDuration: 1.0) { node, elapsed in
                guard let shape = node as? SKShapeNode else { return }
                let progress = elapsed / 1.0
                let width = 3.0 + 3.0 * sin(CGFloat(progress) * .pi)
                shape.lineWidth = width
            }
            let glowDown = SKAction.customAction(withDuration: 1.0) { node, elapsed in
                guard let shape = node as? SKShapeNode else { return }
                let progress = elapsed / 1.0
                let width = 6.0 - 3.0 * sin(CGFloat(progress) * .pi)
                shape.lineWidth = width
            }
            let pulse = SKAction.sequence([glowUp, glowDown])
            let repeatPulse = SKAction.repeatForever(pulse)

            passLineArea?.run(repeatPulse, withKey: actionKey)
            dontPassArea?.run(repeatPulse, withKey: actionKey)
        } else {
            // Remove glow and reset to normal
            passLineArea?.removeAction(forKey: actionKey)
            passLineArea?.lineWidth = 3
            dontPassArea?.removeAction(forKey: actionKey)
            dontPassArea?.lineWidth = 2
        }
    }

    /// Highlight place bet numbers that can be clicked
    /// - Parameter except: The point number to NOT highlight (nil to unhighlight all)
    func highlightPlaceNumbers(except point: Int?) {
        let actionKey = "placeGlow"

        for (number, box) in pointBoxes {
            box.removeAction(forKey: actionKey)

            if let point = point, number != point {
                // This number can be bet on - add subtle pulse
                let glowUp = SKAction.customAction(withDuration: 0.8) { node, elapsed in
                    guard let shape = node as? SKShapeNode else { return }
                    let progress = elapsed / 0.8
                    let width = 2.0 + 1.5 * sin(CGFloat(progress) * .pi)
                    shape.lineWidth = width
                    let brightness = 1.0 + 0.3 * sin(CGFloat(progress) * .pi)
                    shape.strokeColor = SKColor(white: brightness, alpha: 1.0)
                }
                let glowDown = SKAction.customAction(withDuration: 0.8) { node, elapsed in
                    guard let shape = node as? SKShapeNode else { return }
                    let progress = elapsed / 0.8
                    let width = 3.5 - 1.5 * sin(CGFloat(progress) * .pi)
                    shape.lineWidth = width
                    let brightness = 1.3 - 0.3 * sin(CGFloat(progress) * .pi)
                    shape.strokeColor = SKColor(white: brightness, alpha: 1.0)
                }
                let pulse = SKAction.sequence([glowUp, glowDown])
                box.run(SKAction.repeatForever(pulse), withKey: actionKey)
            } else {
                // Reset to normal (either not in point phase, or this IS the point)
                box.lineWidth = 2
                box.strokeColor = .white
            }
        }
    }

    // MARK: - Accessibility Updates

    private func updatePointBoxAccessibility(box: SKShapeNode, number: Int) {
        let odds: String
        switch number {
        case 4, 10:
            odds = "9 to 5"
        case 5, 9:
            odds = "7 to 5"
        case 6, 8:
            odds = "7 to 6"
        default:
            odds = ""
        }

        var hint = "Double-click to place bet, pays \(odds)"
        if currentPoint == number {
            hint = "Current point. " + hint
        }

        box.accessibilityHelp = hint
    }

    private func updateAllPointBoxAccessibility() {
        for (number, box) in pointBoxes {
            updatePointBoxAccessibility(box: box, number: number)
        }
    }

    /// Update accessibility value for betting areas based on current bets
    /// - Parameters:
    ///   - passLineBet: Amount of Pass Line bet, or nil if none
    ///   - dontPassBet: Amount of Don't Pass bet, or nil if none
    func updateBetAreaAccessibility(passLineBet: Int?, dontPassBet: Int?) {
        if let amount = passLineBet {
            passLineArea?.accessibilityLabel = "Pass Line bet area: $\(amount) bet placed"
        } else {
            passLineArea?.accessibilityLabel = "Pass Line bet area: No bet placed"
        }

        if let amount = dontPassBet {
            dontPassArea?.accessibilityLabel = "Don't Pass bet area: $\(amount) bet placed"
        } else {
            dontPassArea?.accessibilityLabel = "Don't Pass bet area: No bet placed"
        }
    }
}
