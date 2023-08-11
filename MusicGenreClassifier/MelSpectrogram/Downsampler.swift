import Foundation

final class Downsampler {
    let stepdownFactor: Int
    let actualOutSampleRate: Double
    private var lowpassFilter: LowpassFilter
    private(set) var processedAudioData: [Float] = []

    init(inSampleRate: Double, targetSampleRate: Double) {
        precondition(inSampleRate > targetSampleRate)

        // floor to make conservative downsampler
        stepdownFactor = Int(floor(inSampleRate / targetSampleRate))

        let Q = 6.0 // discovered experimentally but could potentially be further optimised
        lowpassFilter = LowpassFilter(sampleRate: inSampleRate, centreFrequency: targetSampleRate, Q: Q)

        actualOutSampleRate = inSampleRate / Double(stepdownFactor)
        print("Actual outSampleRate: \(actualOutSampleRate)")
    }

    func process(_ audioData: [Float]) {
        if stepdownFactor == 1 { return }

        var tempSample: Double = 0.0
        let processedAudioDataCount = Int(ceil(Double(audioData.count) / Double(stepdownFactor)))

        if processedAudioData.count != processedAudioDataCount {
            processedAudioData = [Float](repeating: 0, count: processedAudioDataCount)
        }

        audioData.indices.forEach { audioFrameIndex in
            let filteredInputSample = lowpassFilter.run(audioData[audioFrameIndex])
            tempSample += Double(filteredInputSample)

            let (quotient, remainer) = audioFrameIndex.quotientAndRemainder(dividingBy: stepdownFactor)
            if remainer == 0 {
                processedAudioData[quotient] = Float(tempSample / Double(stepdownFactor))
                tempSample = 0.0
            }
        }
    }
}
