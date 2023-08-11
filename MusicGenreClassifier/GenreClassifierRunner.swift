import Foundation
import CoreML

private let BUFFER_DURATION_S = 3.0

private let HOP_LENGTH = 512

private let MEL_PARAMETERS = MelParameters(
    nfft: 2048,
    melFrequencyBinCount: 128,
    minFreq: 20,
    maxFreq: 22050
)

final class GenreClassifierRunner {
    let melFilterbank: MelFilterbank
    let classifier: GenreClassifier
    let classifierInput: GenreClassifierInput
    let audioRecorder: AudioRecorder

    init() {
        var config = MLModelConfiguration()
        self.classifier = try! GenreClassifier(configuration: config)
        
        let multiArrayConstraint = self.classifier
            .model
            .modelDescription
            .inputDescriptionsByName["conv2d_input"]!
            .multiArrayConstraint!
        
        print("multiArrayConstraint: \(multiArrayConstraint)")
        
        self.classifierInput = GenreClassifierInput(conv2d_input: try! MLMultiArray(
            shape: multiArrayConstraint.shape,
            dataType: multiArrayConstraint.dataType
        ))
        
        self.audioRecorder = AudioRecorder(recordingDurationS: BUFFER_DURATION_S)

        self.melFilterbank = MelFilterbank(
            sampleRate: audioRecorder.sampleRate,
            parameters: MEL_PARAMETERS
        )
    }
    
    public func run() async throws -> String {
        let audioData = try await audioRecorder.record()
        
        var melSpectrogram: [[Float]] = []
        var i = 0
        while i < audioData.count - MEL_PARAMETERS.nfft {
            let start = i
            let end = i + MEL_PARAMETERS.nfft
            let block = audioData[start..<end]
            melFilterbank.calculateMagnitudes(Array(block))
            melSpectrogram.append(melFilterbank.magnitudes)
            i += HOP_LENGTH
        }
        
        print("melSpectrogram.count: \(melSpectrogram.count)")
        print("melSpectrogram.first.count: \(melSpectrogram.first!.count)")
        
        // write spectrogram to classifier input
        let modelInputPtr = classifierInput.conv2d_input.dataPointer
        let ptr = modelInputPtr.bindMemory(to: Float.self, capacity: melSpectrogram.count * melSpectrogram.first!.count)
        let bufferPtr = UnsafeMutableBufferPointer(start: ptr, count: melSpectrogram.count * melSpectrogram.first!.count)
        
        for frameIndex in 0..<melSpectrogram.count {
            let frame = melSpectrogram[frameIndex]
            for binIndex in 0..<frame.count {
                let valueForBin = frame[binIndex]
                bufferPtr[frameIndex+binIndex] = valueForBin
            }
        }
        
        let output: GenreClassifierOutput = try classifier.prediction(input: classifierInput)

        output.Identity.sorted(by: { $0.value > $1.value }).forEach { print($0) }

        return output.genre
    }
}
