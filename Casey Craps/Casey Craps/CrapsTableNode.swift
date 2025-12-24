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
        addChild(passLine)

        // Pass Line label
        let passLineLabel = SKLabelNode(text: "PASS LINE")
        passLineLabel.fontSize = 24
        passLineLabel.fontName = "Arial-BoldMT"
        passLineLabel.fontColor = .white
        passLineLabel.verticalAlignmentMode = .center
        passLineLabel.position = CGPoint(x: 0, y: passLineY)
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
        addChild(dontPass)

        // Don't Pass Bar label
        let dontPassLabel = SKLabelNode(text: "DON'T PASS BAR")
        dontPassLabel.fontSize = 14
        dontPassLabel.fontName = "Arial-BoldMT"
        dontPassLabel.fontColor = .yellow
        dontPassLabel.verticalAlignmentMode = .center
        dontPassLabel.position = CGPoint(x: -tableWidth/2 + 170, y: dontPassY)
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
            addChild(label)
        }
    }

    private func addPuck() {
        // Create puck (OFF/ON indicator)
        let puckRadius: CGFloat = 25
        puckNode = SKShapeNode(circleOfRadius: puckRadius)
        puckNode?.fillColor = .black
        puckNode?.strokeColor = .white
        puckNode?.lineWidth = 3
        puckNode?.isHidden = true // Start hidden
        addChild(puckNode!)

        // Create puck label
        puckLabel = SKLabelNode(text: "OFF")
        puckLabel?.fontSize = 16
        puckLabel?.fontName = "Arial-BoldMT"
        puckLabel?.fontColor = .white
        puckLabel?.verticalAlignmentMode = .center
        puckNode?.addChild(puckLabel!)
    }

    // MARK: - Public Methods

    /// Set the puck position to indicate the current point
    /// - Parameter point: The point number (4, 5, 6, 8, 9, 10) or nil for OFF
    func setPuckPosition(point: Int?) {
        guard let puckNode = puckNode, let puckLabel = puckLabel else { return }

        if let point = point, let box = pointBoxes[point] {
            // Show puck ON the point
            puckNode.position = box.position
            puckNode.fillColor = .white
            puckLabel.text = "ON"
            puckLabel.fontColor = .black
            puckNode.isHidden = false
        } else {
            // Show puck as OFF or hide it
            puckNode.isHidden = true
        }
    }
}
