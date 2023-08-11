import Foundation
import CKissFFT

public typealias KissFFTCfg = kiss_fft_cfg
public typealias KissFFTCpx = kiss_fft_cpx

public func kissFFTRAlloc(nfft: Int, inverse: Bool) -> KissFFTCfg {
    let cfg = kiss_fftr_alloc(
        Int32(nfft),
        inverse ? 1 : 0,
        nil,
        nil
    )!
    return cfg
}

public func kissFFTR(cfg: KissFFTCfg, realInput: UnsafePointer<Float>, complexOutput: UnsafeMutablePointer<KissFFTCpx>) {
    kiss_fftr(cfg, realInput, complexOutput)
}

public extension KissFFTCpx {
    /// squared magnitude value
    var magnitude: Float { powf(self.r, 2) + powf(self.i, 2) }
    /// absolute value
    var absolute: Float { sqrtf( self.magnitude ) }
    /// angle in radians
    var phiRad: Float { atan(self.i / self.r) }
    /// angle in degrees
    var phiDeg: Float { self.phiRad * 180 / Float.pi }
}

public extension Array where Element == KissFFTCpx {
    var magnitudes: [Float] { self.map { $0.magnitude } }
    var absolute: [Float] { self.map { $0.absolute } }
    var phiRad: [Float] { self.map { $0.phiRad } }
    var phiDeg: [Float] { self.map { $0.phiDeg } }
}

public func hanningWindow(N: Int, normalized: Bool, halfWindow: Bool) -> [Float] {
    // https://developer.apple.com/documentation/accelerate/1450263-vdsp_hann_window
    // http://www.windoffthehilltop.com/sample-hamm%20hann.pdf

    let W: Float = normalized ? 0.8165 : 0.5
    let length = halfWindow ? ((N+1) / 2) : N

    return (0 ..< length).map { n in
        let a = 2 * Float.pi * Float(n)
        let b = Float(N)
        return W * (1.0 - cos(a/b))
    }
}
