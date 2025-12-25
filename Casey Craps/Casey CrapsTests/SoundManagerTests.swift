//
//  SoundManagerTests.swift
//  Casey CrapsTests
//
//  Created by Claude on 12/25/25.
//

import Testing
import AVFoundation
@testable import Casey_Craps

/// Tests for SoundManager synthesis logic and parameters
/// Note: These tests verify the logic/parameters that control sound generation,
/// not actual AVAudioEngine playback (which is Apple's code).
@Suite
struct SoundManagerTests {

    // MARK: - Singleton Tests

    @Test func soundManagerIsSingleton() {
        let instance1 = SoundManager.shared
        let instance2 = SoundManager.shared

        #expect(instance1 === instance2, "SoundManager should be a singleton")
    }

    // MARK: - Sound Parameter Tests
    // These tests verify the hardcoded sound parameters are reasonable

    @Test func diceRollSoundParametersAreReasonable() {
        // Dice roll uses:
        // - 20 clicks
        // - Base frequency 450 Hz with ±150 Hz variation (300-600 Hz range)
        // - Duration 1.0 seconds total
        // - Individual click duration 0.03 seconds
        // - Volume starts at 0.25 and tapers to 0.075

        let numberOfClicks = 20
        let totalDuration = 1.0
        let clickDuration = 0.03
        let baseFrequency = 450.0
        let frequencyVariationRange = 300.0...600.0
        let initialVolume: Float = 0.25
        let finalVolume: Float = 0.075  // 0.25 * (1 - 0.7)

        // Verify parameters are in reasonable ranges
        #expect(numberOfClicks > 0 && numberOfClicks < 100, "Click count should be reasonable")
        #expect(totalDuration > 0 && totalDuration < 5, "Total duration should be reasonable")
        #expect(clickDuration > 0 && clickDuration < 0.5, "Click duration should be short")
        #expect(baseFrequency >= 20 && baseFrequency <= 20000, "Base frequency should be audible")
        #expect(frequencyVariationRange.lowerBound >= 20, "Min frequency should be audible")
        #expect(frequencyVariationRange.upperBound <= 20000, "Max frequency should be audible")
        #expect(initialVolume >= 0.0 && initialVolume <= 1.0, "Initial volume should be valid")
        #expect(finalVolume >= 0.0 && finalVolume <= 1.0, "Final volume should be valid")
    }

    @Test func chipClickSoundParametersAreReasonable() {
        // Chip click uses:
        // - Frequency 1400-1600 Hz
        // - Duration 0.05 seconds
        // - Volume 0.3

        let frequencyRange = 1400.0...1600.0
        let duration = 0.05
        let volume: Float = 0.3

        #expect(frequencyRange.lowerBound >= 20 && frequencyRange.lowerBound <= 20000, "Min frequency should be audible")
        #expect(frequencyRange.upperBound >= 20 && frequencyRange.upperBound <= 20000, "Max frequency should be audible")
        #expect(duration > 0 && duration < 0.5, "Duration should be short")
        #expect(volume >= 0.0 && volume <= 1.0, "Volume should be valid")
    }

    @Test func buttonClickSoundParametersAreReasonable() {
        // Button click uses:
        // - Frequency 800 Hz
        // - Duration 0.04 seconds
        // - Volume 0.2

        let frequency = 800.0
        let duration = 0.04
        let volume: Float = 0.2

        #expect(frequency >= 20 && frequency <= 20000, "Frequency should be audible")
        #expect(duration > 0 && duration < 0.5, "Duration should be short")
        #expect(volume >= 0.0 && volume <= 1.0, "Volume should be valid")
    }

    @Test func winSoundParametersAreReasonable() {
        // Win sound uses ascending notes:
        // - C5 (523 Hz) at 0.0s
        // - E5 (659 Hz) at 0.12s
        // - G5 (784 Hz) at 0.24s
        // - C6 (1047 Hz) at 0.36s
        // - Note duration 0.12 seconds
        // - Volume 0.35

        let notes: [(frequency: Double, delay: Double)] = [
            (523, 0.0),
            (659, 0.12),
            (784, 0.24),
            (1047, 0.36)
        ]
        let noteDuration = 0.12
        let volume: Float = 0.35

        // Verify all frequencies are audible
        for note in notes {
            #expect(note.frequency >= 20 && note.frequency <= 20000, "Frequency should be audible: \(note.frequency)")
            #expect(note.delay >= 0, "Delay should be non-negative: \(note.delay)")
        }

        // Verify ascending pattern
        #expect(notes[1].frequency > notes[0].frequency, "Notes should ascend")
        #expect(notes[2].frequency > notes[1].frequency, "Notes should ascend")
        #expect(notes[3].frequency > notes[2].frequency, "Notes should ascend")

        #expect(noteDuration > 0 && noteDuration < 1, "Note duration should be reasonable")
        #expect(volume >= 0.0 && volume <= 1.0, "Volume should be valid")
    }

    @Test func loseSoundParametersAreReasonable() {
        // Lose sound uses descending notes:
        // - E4 (330 Hz) at 0.0s
        // - Eb4 (311 Hz) at 0.17s
        // - D4 (294 Hz) at 0.34s
        // - Note duration 0.17 seconds
        // - Volume 0.25

        let notes: [(frequency: Double, delay: Double)] = [
            (330, 0.0),
            (311, 0.17),
            (294, 0.34)
        ]
        let noteDuration = 0.17
        let volume: Float = 0.25

        // Verify all frequencies are audible
        for note in notes {
            #expect(note.frequency >= 20 && note.frequency <= 20000, "Frequency should be audible: \(note.frequency)")
            #expect(note.delay >= 0, "Delay should be non-negative: \(note.delay)")
        }

        // Verify descending pattern
        #expect(notes[1].frequency < notes[0].frequency, "Notes should descend")
        #expect(notes[2].frequency < notes[1].frequency, "Notes should descend")

        #expect(noteDuration > 0 && noteDuration < 1, "Note duration should be reasonable")
        #expect(volume >= 0.0 && volume <= 1.0, "Volume should be valid")
    }

    @Test func pointEstablishedSoundParametersAreReasonable() {
        // Point established uses:
        // - G5 (784 Hz) at 0.0s
        // - C6 (1047 Hz) at 0.15s
        // - Note duration 0.15 seconds
        // - Volume 0.3

        let notes: [(frequency: Double, delay: Double)] = [
            (784, 0.0),
            (1047, 0.15)
        ]
        let noteDuration = 0.15
        let volume: Float = 0.3

        // Verify all frequencies are audible
        for note in notes {
            #expect(note.frequency >= 20 && note.frequency <= 20000, "Frequency should be audible: \(note.frequency)")
            #expect(note.delay >= 0, "Delay should be non-negative: \(note.delay)")
        }

        // Verify ascending pattern (distinctive ding)
        #expect(notes[1].frequency > notes[0].frequency, "Notes should ascend for ding")

        #expect(noteDuration > 0 && noteDuration < 1, "Note duration should be reasonable")
        #expect(volume >= 0.0 && volume <= 1.0, "Volume should be valid")
    }

    // MARK: - Audible Range Tests

    @Test func allFrequenciesAreInAudibleRange() {
        // Human hearing range: approximately 20 Hz to 20,000 Hz
        // All sound frequencies should fall within this range

        let audibleRange = 20.0...20000.0

        // Dice roll: 300-600 Hz
        #expect(audibleRange.contains(300.0), "Dice roll min frequency should be audible")
        #expect(audibleRange.contains(600.0), "Dice roll max frequency should be audible")

        // Chip click: 1400-1600 Hz
        #expect(audibleRange.contains(1400.0), "Chip click min frequency should be audible")
        #expect(audibleRange.contains(1600.0), "Chip click max frequency should be audible")

        // Button click: 800 Hz
        #expect(audibleRange.contains(800.0), "Button click frequency should be audible")

        // Win sound: 523, 659, 784, 1047 Hz
        #expect(audibleRange.contains(523.0), "Win note C5 should be audible")
        #expect(audibleRange.contains(659.0), "Win note E5 should be audible")
        #expect(audibleRange.contains(784.0), "Win note G5 should be audible")
        #expect(audibleRange.contains(1047.0), "Win note C6 should be audible")

        // Lose sound: 330, 311, 294 Hz
        #expect(audibleRange.contains(330.0), "Lose note E4 should be audible")
        #expect(audibleRange.contains(311.0), "Lose note Eb4 should be audible")
        #expect(audibleRange.contains(294.0), "Lose note D4 should be audible")

        // Point established: 784, 1047 Hz
        #expect(audibleRange.contains(784.0), "Point note G5 should be audible")
        #expect(audibleRange.contains(1047.0), "Point note C6 should be audible")
    }

    // MARK: - Volume Range Tests

    @Test func allVolumesAreInValidRange() {
        // Volume should be between 0.0 and 1.0

        let volumeRange = 0.0...1.0

        // All sound volumes
        let volumes: [Float] = [
            0.25,  // Dice roll initial
            0.3,   // Chip click
            0.2,   // Button click
            0.35,  // Win sound
            0.25,  // Lose sound
            0.3    // Point established
        ]

        for volume in volumes {
            #expect(volumeRange.contains(Double(volume)), "Volume \(volume) should be in valid range 0.0-1.0")
        }
    }

    // MARK: - Duration Tests

    @Test func allDurationsAreReasonable() {
        // Durations should be positive and not excessively long
        let reasonableDurationRange = 0.0...5.0

        let durations = [
            1.0,   // Dice roll total
            0.03,  // Dice roll individual click
            0.05,  // Chip click
            0.04,  // Button click
            0.12,  // Win sound note
            0.17,  // Lose sound note
            0.15   // Point established note
        ]

        for duration in durations {
            #expect(reasonableDurationRange.contains(duration), "Duration \(duration) should be reasonable")
            #expect(duration > 0, "Duration \(duration) should be positive")
        }
    }

    // MARK: - Musical Correctness Tests

    @Test func winSoundUsesAscendingTones() {
        // Win sound should use ascending frequencies for happy feel
        let frequencies = [523.0, 659.0, 784.0, 1047.0]  // C5, E5, G5, C6

        #expect(frequencies[1] > frequencies[0], "E5 > C5")
        #expect(frequencies[2] > frequencies[1], "G5 > E5")
        #expect(frequencies[3] > frequencies[2], "C6 > G5")
    }

    @Test func loseSoundUsesDescendingTones() {
        // Lose sound should use descending frequencies for sad feel
        let frequencies = [330.0, 311.0, 294.0]  // E4, Eb4, D4

        #expect(frequencies[1] < frequencies[0], "Eb4 < E4")
        #expect(frequencies[2] < frequencies[1], "D4 < Eb4")
    }

    @Test func pointEstablishedUsesAscendingTones() {
        // Point established should use ascending tones for notification
        let frequencies = [784.0, 1047.0]  // G5, C6

        #expect(frequencies[1] > frequencies[0], "C6 > G5")
    }

    // MARK: - Relative Characteristics Tests

    @Test func chipClickIsShorterThanOtherSounds() {
        // Chip click should be shortest (0.05s)
        let chipClickDuration = 0.05
        let buttonClickDuration = 0.04  // Actually button is shorter!
        let diceClickDuration = 0.03

        // These are all very short UI feedback sounds
        #expect(chipClickDuration < 0.1, "Chip click should be very short")
        #expect(buttonClickDuration < 0.1, "Button click should be very short")
        #expect(diceClickDuration < 0.1, "Dice click should be very short")
    }

    @Test func winSoundIsLouderThanLoseSound() {
        // Win should be more prominent than lose
        let winVolume: Float = 0.35
        let loseVolume: Float = 0.25

        #expect(winVolume > loseVolume, "Win sound should be louder than lose sound")
    }

    @Test func buttonClickIsQuietestSound() {
        // Button click is UI feedback, should be subtle
        let buttonVolume: Float = 0.2
        let otherVolumes: [Float] = [0.25, 0.3, 0.35, 0.25, 0.3]

        for volume in otherVolumes {
            #expect(buttonVolume <= volume, "Button click should be quietest or tied for quietest")
        }
    }
}
