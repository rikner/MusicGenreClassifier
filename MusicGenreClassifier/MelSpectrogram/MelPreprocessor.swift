import Collections

public final class MelPreprocessor {

    private var audioBuffer: Deque<Float> // to decouple mel preprocessing from incoming audio block sizes
    private(set) var audioBufferReadCount: Int // the amount of samples which we we take out of buffer and send to the downsampler
    private let downsampler: Downsampler // to increase on fft resolution
    private var overlapBuffer: Deque<Float> // stores n recent downsampled audio frames
    private var melFilterbankInput: [Float]

    public var outputSampleRate: Double {
        return downsampler.actualOutSampleRate
    }

    public var stepdownFactor: Int {
        return downsampler.stepdownFactor
    }

    public init(inputSampleRate: Double, melParameters: MelParameters, frameCount: Int) {
        // use an arbitrary (but big enough) sized buffer to collect audio blocks of arbitrary size from the audio engine
        audioBuffer = Deque<Float>(minimumCapacity: 5000)
        overlapBuffer = Deque<Float>(repeating: 0 , count: melParameters.nfft)
        melFilterbankInput = [Float](repeating: 0, count: melParameters.nfft)
        downsampler = Downsampler(
            inSampleRate: inputSampleRate,
            targetSampleRate: Double(melParameters.maxFreq * 2)
        )
        audioBufferReadCount = (melParameters.nfft / frameCount) * downsampler.stepdownFactor
    }

    public func callAsFunction(audioData: [Float]) -> [Float]? {
        audioBuffer.append(contentsOf: audioData)
        if audioBuffer.count >= audioBufferReadCount {
            downsampler.process(audioBuffer.popFirst(audioBufferReadCount))
            overlapBuffer.removeFirst(downsampler.processedAudioData.count)
            overlapBuffer.append(contentsOf: downsampler.processedAudioData)
            melFilterbankInput.indices.forEach { melFilterbankInput[$0] = overlapBuffer[$0] }
            precondition(audioBuffer.count < audioBufferReadCount)
            return melFilterbankInput
        } else {
            return nil
        }
    }
}


public extension Deque {
    @inlinable
    mutating func popFirst(_ k: Int) -> [Element] {
        return (0 ..< k).map {_ in
            return self.popFirst()!
        }
    }
}
