//
//  AudioInput.swift
//  MusicGenreClassifier
//
//  Created by Erik Werner on 30.03.23.
//

import Foundation
import AVFAudio
import Accelerate
import Dispatch

class AudioRecorder {
    private let audioEngine: AVAudioEngine
    private let audioFormat: AVAudioFormat
    private var audioBuffer: [Float]
    
    var sampleRate: Double {
        return audioFormat.sampleRate
    }
    
    init(recordingDurationS: Double) {
        try! AVAudioSession.sharedInstance().setCategory(.record, mode: .default)
        
        self.audioEngine = AVAudioEngine()
        self.audioFormat = AVAudioFormat(standardFormatWithSampleRate: AVAudioSession.sharedInstance().sampleRate, channels: 1)!

        let audioBufferLength: Int = Int((recordingDurationS * audioFormat.sampleRate).rounded())
        self.audioBuffer = Array<Float>(repeating: 0, count: audioBufferLength)
        self.audioBuffer.removeAll(keepingCapacity: true)
        print("audioBuffer.capacity: \(audioBuffer.capacity)")
        
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: audioFormat) { (sourceBuffer, time) in
            guard let srcFloatChannelData = sourceBuffer.floatChannelData else {
                fatalError("could not get floatChannelData")
            }
            
            let frameLength = Int(sourceBuffer.frameLength)
            let elementsLeft = self.audioBuffer.capacity - self.audioBuffer.count
            let audioBlock = UnsafeBufferPointer<Float>(
                start: srcFloatChannelData[0],
                count: min(frameLength, elementsLeft)
            )
            
            print("appending \(audioBlock.count) elements")
            self.audioBuffer.append(contentsOf: audioBlock)
        
            if self.audioBuffer.count == self.audioBuffer.capacity {
                self.audioEngine.stop()
                self.recordContinuation?.resume(returning: self.audioBuffer)
                self.recordContinuation = nil
            }
            
        }

    }
    
    private var recordContinuation: CheckedContinuation<[Float], any Error>?
    
    func record() async throws -> [Float] {
        audioBuffer.removeAll(keepingCapacity: true)
        try audioEngine.start()

        return try await withCheckedThrowingContinuation { continuation in
            self.recordContinuation = continuation
        }
    }
}
