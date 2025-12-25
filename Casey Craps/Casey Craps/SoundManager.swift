//
//  SoundManager.swift
//  Casey Craps
//
//  Created by Matthew Barnson on 12/24/25.
//

import AVFoundation

class SoundManager {

    // MARK: - Singleton

    static let shared = SoundManager()

    // MARK: - Properties

    private let audioEngine: AVAudioEngine
    private let playerNode: AVAudioPlayerNode
    private var isEnabled: Bool = true
    private let sampleRate: Double = 44100.0

    // MARK: - Initialization

    private init() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()

        setupAudioEngine()
    }

    // MARK: - Setup

    private func setupAudioEngine() {
        // Attach player node to the audio engine
        audioEngine.attach(playerNode)

        // Connect player node to the main mixer node
        let mixer = audioEngine.mainMixerNode
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        audioEngine.connect(playerNode, to: mixer, format: format)

        // Start the audio engine
        do {
            try audioEngine.start()
            playerNode.play()
        } catch {
            print("Failed to start audio engine: \(error.localizedDescription)")
        }
    }

    // MARK: - Core Synthesis

    /// Play a synthesized tone at a given frequency
    /// - Parameters:
    ///   - frequency: The frequency in Hz
    ///   - duration: The duration in seconds
    ///   - volume: The volume (0.0 to 1.0)
    private func playTone(frequency: Double, duration: Double, volume: Float = 0.3) {
        guard isEnabled else { return }

        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!, frameCapacity: frameCount) else {
            return
        }

        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData?[0] else {
            return
        }

        // Generate sine wave samples with envelope
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let sineWave = sin(2.0 * .pi * frequency * t)

            // Apply simple envelope to avoid clicks
            // Attack: first 5% of duration
            // Release: last 10% of duration
            var envelope: Double = 1.0
            let attackTime = duration * 0.05
            let releaseTime = duration * 0.10

            if t < attackTime {
                envelope = t / attackTime
            } else if t > (duration - releaseTime) {
                envelope = (duration - t) / releaseTime
            }

            channelData[frame] = Float(sineWave * envelope) * volume
        }

        // Schedule and play the buffer
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
    }

    // MARK: - Game Sounds

    /// Play dice rolling sound - a rattling sequence
    func playDiceRoll() {
        guard isEnabled else { return }

        // Create a sequence of short clicks/taps that taper off
        let numberOfClicks = 20
        let totalDuration = 1.0

        // Schedule multiple short bursts with decreasing volume
        for i in 0..<numberOfClicks {
            let delay = (totalDuration / Double(numberOfClicks)) * Double(i)
            let clickDuration = 0.03

            // Randomize frequency for organic feel (300-600 Hz range)
            let baseFrequency = 450.0
            let frequencyVariation = Double.random(in: -150...150)
            let frequency = baseFrequency + frequencyVariation

            // Taper volume off toward the end
            let volumeFactor = 1.0 - (Double(i) / Double(numberOfClicks)) * 0.7
            let volume = Float(volumeFactor) * 0.25

            // Schedule click with delay
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.playTone(frequency: frequency, duration: clickDuration, volume: volume)
            }
        }
    }

    /// Play chip click sound - short, satisfying click
    func playChipClick() {
        guard isEnabled else { return }

        // High frequency click (1000-2000 Hz)
        let frequency = Double.random(in: 1400...1600)
        let duration = 0.05
        let volume: Float = 0.3

        playTone(frequency: frequency, duration: duration, volume: volume)
    }

    /// Play button click sound - subtle UI feedback
    func playButtonClick() {
        guard isEnabled else { return }

        // Lower, softer tone for UI feedback
        let frequency = 800.0
        let duration = 0.04
        let volume: Float = 0.2

        playTone(frequency: frequency, duration: duration, volume: volume)
    }

    // MARK: - Public Controls

    /// Enable or disable all sounds
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
}
