// swiftlint:disable variable_name

import Foundation

struct LowpassFilter {
    var y1 = Float(0)
    var y2 = Float(0)
    var x1 = Float(0)
    var x2 = Float(0)

    let b0and2: Float
    let b1: Float
    let a1: Float
    let a2: Float

    public init(sampleRate: Double, centreFrequency: Double, Q: Double) {
        precondition(centreFrequency > 0)
        precondition(Q > 0)

        let omega: Double = 2 * .pi * centreFrequency / sampleRate
        let omegaS: Double = sin(omega)
        let omegaC: Double = cos(omega)
        let alpha: Double = omegaS / (2 * Q)

        let a0 = 1 + alpha;
        b0and2 = Float(((1 - omegaC)/2)      / a0)
        b1 = Float(((1 - omegaC))        / a0)
//        b2 = Float(((1 - omegaC)/2)      / a0) // same as b0
        a1 = Float((-2 * omegaC)         / a0)
        a2 = Float((1 - alpha)           / a0)

        if abs(a1) < (1 + a2) {
        } else {
            print("Warning: a1 is unstable for sampleRate: \(sampleRate)", centreFrequency, Q)
        }

        if abs(a2) < 1 {
        } else {
            print("Warning: a2 is unstable for sampleRate: \(sampleRate)", centreFrequency, Q)
        }
    }

    // simplified version of general IIR filter equation:
    // x * b0 + x1 * b1 + x2 * b2 - y1 * a1 - y2 * a2

    // we are able to do 4 multiplications instead of 5 with this simplified version
    // which we get because b0 and b2 are the same
    public mutating func run(_ x: Float) -> Float {
        let y = ((((x + x2) * b0and2).addingProduct(x1, b1)).addingProduct(-y1, a1)).addingProduct(-y2, a2)
        x2 = x1
        x1 = x

        y2 = y1
        y1 = y

        return y
    }
}
