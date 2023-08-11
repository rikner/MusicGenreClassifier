import FlowDSP
import Foundation

public struct MelParameters: Codable {
    public let nfft: Int
    public let melFrequencyBinCount: Int
    public let minFreq: Float
    public let maxFreq: Float
}

extension FloatingPoint {
    var byteArray: [UInt8] {
        var value = self
        return withUnsafeBytes(of: &value) { Array($0) }
    }

    static func MEL<T: FloatingPoint>(fromHZ frequency: T) -> T {
        // There are two different ways for this conversion, we currently use HTK binning! see librosa implementation as reference: http://man.hubwiz.com/docset/LibROSA.docset/Contents/Resources/Documents/_modules/librosa/core/time_frequency.html#hz_to_mel
        return T(2595) * (T(1) + frequency / T(700)).logarithm10()
    }

    static func HZ<T: FloatingPoint>(fromMEL mels: T) -> T {
        // See aboth, we currently use HTK binning!
        return T(700) * ((mels / T(2595)).pow10() - T(1))
    }

    func logarithm10() -> Self {
        switch self {
        case let self as Double:
            return log10(self) as! Self
        case let self as CGFloat:
            return log10(self) as! Self
        case let self as Float:
            return log10f(self) as! Self
        default:
            preconditionFailure("Unsupported FloatingPoint type")
        }
    }

    func logarithm() -> Self {
        switch self {
        case let self as Double:
            return log(self) as! Self
        case let self as CGFloat:
            return log(self) as! Self
        case let self as Float:
            return logf(self) as! Self
        default:
            preconditionFailure("Unsupported FloatingPoint type")
        }
    }

    func exponent() -> Self {
        switch self {
        case let self as Double:
            return exp(self) as! Self
        case let self as CGFloat:
            return exp(self) as! Self
        case let self as Float:
            return expf(self) as! Self
        default:
            preconditionFailure("Unsupported FloatingPoint type")
        }
    }

    func pow10() -> Self {
        switch self {
        case let self as Double:
            return pow(10, self) as! Self
        case let self as CGFloat:
            return pow(10, self) as! Self
        case let self as Float:
            return pow(10, self) as! Self
        default:
            preconditionFailure("Unsupported FloatingPoint type")
        }
    }
}

func createMelFilter(sampleRate: Int, FTTCount: Int, melsCount: Int = 229, fmin: Float, fmax: Float) -> SparseMatrix {
    let FFTFreqs = [Float].createFFTFrequencies(sampleRate: sampleRate, FTTCount: FTTCount)

    let MELFreqs = [Float].createMELFrequencies(MELCount: melsCount + 2, fmin: fmin, fmax: fmax)
    let diff = MELFreqs.diff
    let ramps = MELFreqs.outerSubstract(FFTFreqs)

    var result = SparseMatrix(melsCount, FTTCount / 2 + 1)

    // We want to find which FFT bins match our mel bins
    // (each bin of either kind is mapped to a certain frequency,
    //  so we want to find out how much of a certain FFT bin
    //  contributes to the final value of the resulting mel bin)
    for rowIndex in 0 ..< melsCount {
        ramps[rowIndex].indices.forEach { colIndex in
            let lower = -ramps[rowIndex][colIndex] / diff[rowIndex]
            let upper = ramps[rowIndex + 2][colIndex] / diff[rowIndex + 1]

            let minValue = Swift.min(lower, upper)

            if minValue > 0 {
                let enorm = 2 / (MELFreqs[rowIndex + 2] - MELFreqs[rowIndex])
                let value = minValue * enorm
                result.insert(value, i: rowIndex, j: colIndex)
            }
        }
    }
    result.finalize()

    return result
}

public extension Array where Iterator.Element: FloatingPoint {
    static func createFFTFrequencies(sampleRate: Int, FTTCount: Int) -> [Element] {
        /// We need to add 2 instead of 1 for num because it rounds off at 0.5..........
        return [Element].linespace(start: 0, stop: Element(sampleRate) / Element(2), num: Element(2 + FTTCount / 2))
    }

    static func createMELFrequencies(MELCount: Int, fmin: Element, fmax: Element) -> [Element] {
        let minMEL = Float.MEL(fromHZ: fmin)
        let maxMEL = Float.MEL(fromHZ: fmax)

        let mels = [Element].linespace(start: minMEL, stop: maxMEL, num: Element(MELCount))
        return mels.map { Element.HZ(fromMEL: $0) }
    }

    func powerToDB(ref: Element = Element(1), amin: Element = Element(1) / Element(Int64(10_000_000_000)), topDB: Element = Element(80)) -> [Element] {
        let ten = Element(10)

        let logSpec = map { ten * Swift.max(amin, $0).logarithm10() - ten * Swift.max(amin, abs(ref)).logarithm10() }

        let maximum = (logSpec.max() ?? Element(0))

        return logSpec.map { Swift.max($0, maximum - topDB) }
    }

    func normalizeAudioPower() -> [Element] {
        var dbValues = powerToDB()

        let minimum = (dbValues.min() ?? Element(0))
        dbValues = dbValues.map { $0 - minimum }
        let maximum = (dbValues.map { abs($0) }.max() ?? Element(0))
        dbValues = dbValues.map { $0 / (maximum + Element(1)) }
        return dbValues
    }

    static func empty(width: Int, height: Int, defaultValue: Element) -> [[Element]] {
        var result = [[Element]]()

        for _ in 0 ..< width {
            var vertialArray = [Element]()
            for _ in 0 ..< height {
                vertialArray.append(defaultValue)
            }
            result.append(vertialArray)
        }

        return result
    }

    static func linespace(start: Element, stop: Element, num: Element) -> [Element] {
        var linespace = [Element]()

        let one = num / num
        var index = num * 0
        while index < num - one {
            let startPart = (start * (one - index / floor(num - one)))
            let stopPart = (index * stop / floor(num - one))

            let value = startPart + stopPart

            linespace.append(value)
            index += num / num
        }

        linespace.append(stop)

        return linespace
    }

    var diff: [Element] {
        var diff = [Element]()

        for index in 1 ..< count {
            let value = self[index] - self[index - 1]
            diff.append(value)
        }

        return diff
    }

    func outerSubstract(_ otherArray: [Element]) -> [[Element]] {
        var result = [[Element]]()

        let rows = count
        let cols = otherArray.count

        for row in 0 ..< rows {
            var rowValues = [Element]()
            for col in 0 ..< cols {
                let value = self[row] - otherArray[col]
                rowValues.append(value)
            }

            result.append(rowValues)
        }

        return result
    }
}

public extension Array where Element == [Double] {
    func normalizeAudioPowerArray() -> [[Double]] {
        let chunkSize = first?.count ?? 0
        let dbValues = flatMap { $0 }.normalizeAudioPower().chunked(into: chunkSize)
        return dbValues
    }
}

public extension Array where Element: FloatingPoint {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
