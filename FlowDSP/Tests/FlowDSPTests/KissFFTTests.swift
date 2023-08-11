import XCTest
import FlowDSP

final class KissFFTTests: XCTestCase {

    func testAbsolute() {
        let cpx = KissFFTCpx(r: 3, i: 7)
        XCTAssertEqual(cpx.absolute, 7.615773105863909)
    }

    func testMagnitude() {
        let cpx = KissFFTCpx(r: 3, i: 7)
        XCTAssertEqual(cpx.magnitude, 58.0)
    }

    func testPhi() {
        let cpx = KissFFTCpx(r: 1, i: 4)
        XCTAssertEqual(cpx.phiRad, 1.3258177)
        XCTAssertEqual(cpx.phiDeg, 75.96376)
    }

    func testRealFFTWithConstantInput() {
        let nfft = 1024
        let amplitude: Float = 1

        // constant, non-alternating input
        var realIn = [Float](repeating: amplitude, count: nfft)
        var complexOut = [KissFFTCpx](repeating: KissFFTCpx(r: 0, i: 0), count: realIn.count / 2)
        let cfg: KissFFTCfg = kissFFTRAlloc(nfft: nfft, inverse: false)
        kissFFTR(cfg: cfg, realInput: &realIn, complexOutput: &complexOut)

        complexOut.absolute.enumerated().forEach { i, abs in
            if i == 0 {
                // first element in absolute values is dc component
                XCTAssertEqual(abs, amplitude * Float(nfft))
            } else {
                XCTAssertEqual(abs, 0)
            }
        }
    }

    func testRealFFTWithSineInput() {
        let nfft = 1024

        let frequency: Float = 440
        let sampleRate: Float = 44100

        let cfg: KissFFTCfg = kissFFTRAlloc(nfft: nfft, inverse: false)
        var realIn = sineWave(count: nfft, f: frequency, fs: sampleRate, amp: 1)
        var complexOut = [KissFFTCpx](repeating: KissFFTCpx(r: 0, i: 0), count: nfft / 2)
        kissFFTR(cfg: cfg, realInput: &realIn, complexOutput: &complexOut)

        let magnitudes = complexOut.absolute
        let maxIndex = magnitudes.firstIndex(of: magnitudes.max()!)!
        let expectedMaxIndex: Int = {
            let fmax = sampleRate / 2
            let binCount = nfft / 2
            let frequencyResolution = fmax / Float(binCount)
            return lroundf(frequency / frequencyResolution)
        }()

        XCTAssertEqual(expectedMaxIndex, maxIndex)
    }


    static var allTests = [
        ("testAbsolute", testAbsolute),
        ("testPhi", testPhi),
        ("testMagnitude", testMagnitude),
        ("testRealFFTWithConstantInput", testRealFFTWithConstantInput),
        ("testRealFFTWithSineInput", testRealFFTWithSineInput)
    ]
}

func sineWave(count: Int, f: Float, fs: Float, amp: Float = 1) -> [Float] {
    return (0 ..< count).map { index in
        return amp * Foundation.sin(2 * .pi * f/fs * Float(index))
    }
}
