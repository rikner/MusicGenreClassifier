import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        return [
            testCase(KissFFTTests.allTests),
            testCase(SparseBLASTests.allTests),
        ]
    }
#endif
