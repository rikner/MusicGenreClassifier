import FlowDSP
import func Foundation.pow

public typealias FFTMagnitude = Float // typealias is public, Filterbank is not

public final class MelFilterbank {
    let window: [Float]
    private(set) var analysisBuffer: [Float]

    var fftCfg: KissFFTCfg
    let sparseMatrix: SparseMatrix
    private(set) public var magnitudes: [Float]

    private(set) var complexFFTOutput: [KissFFTCpx]
    let parameters: MelParameters

    public init(
        sampleRate: Double,
        parameters: MelParameters
    ) {
        self.parameters = parameters

        // Initalize FFT
        fftCfg = kissFFTRAlloc(
            nfft: parameters.nfft,
            inverse: false
        )
        
        magnitudes = [Float](repeating: 0.0, count: parameters.melFrequencyBinCount)

        // Initalize Hann Window
        window = hanningWindow(N: parameters.nfft, normalized: false, halfWindow: false)
        analysisBuffer = [Float](repeating: 0, count: window.count)

        // Inialize FFT complex output array
        // since we are using FFTR (real input), the result is the positive half-spectrum
        let outputCount = parameters.nfft / 2 + 1
        complexFFTOutput = [KissFFTCpx](repeating: KissFFTCpx(r: 0, i: 0), count: outputCount)

        sparseMatrix = createMelFilter(
            sampleRate: Int(sampleRate),
            FTTCount: parameters.nfft - 1,
            melsCount: parameters.melFrequencyBinCount,
            fmin: parameters.minFreq,
            fmax: parameters.maxFreq
        )
    }

    public func calculateMagnitudes(_ inMonoBuffer: [Float]) {
        precondition(inMonoBuffer.count == parameters.nfft)
        let fftMagnitudes = fftForward(inMonoBuffer)
        magnitudes = sparseMatrix.multipliedByDenseVector(fftMagnitudes)
    }

    func fftForward(_ inMonoRingBuffer: [Float]) -> [FFTMagnitude] {
        // Windowing
        for i in 0 ..< inMonoRingBuffer.count {
            analysisBuffer[i] = inMonoRingBuffer[i] * window[i]
        }

        // Perform a forward FFT
        kissFFTR(cfg: fftCfg, realInput: &analysisBuffer, complexOutput: &complexFFTOutput)

        return complexFFTOutput.magnitudes
    }

    deinit {
        sparseMatrix.destroy()
    }
}
