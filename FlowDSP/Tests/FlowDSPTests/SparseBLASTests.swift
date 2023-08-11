import XCTest
import FlowDSP

final class SparseBLASTests: XCTestCase {
    func testSimpleMatrixVectorMultiplication() {
        var matrix = SparseMatrix(3, 3)
        matrix.insert(1.0, i: 0, j: 0)
        matrix.insert(2.0, i: 1, j: 1)
        matrix.insert(3.0, i: 2, j: 2)
        matrix.finalize()

        let allElementsInSparseMatrix = matrix.map { $0 }

        XCTAssertEqual(allElementsInSparseMatrix, [
            SparseMatrix.Element(1.0, i: 0, j: 0),
            SparseMatrix.Element(2.0, i: 1, j: 1),
            SparseMatrix.Element(3.0, i: 2, j: 2)
        ])

        let result = matrix.multipliedByDenseVector([3.0, 3.0, 3.0])
        XCTAssertEqual(result, [3.0, 6.0, 9.0])

        matrix.destroy()
    }

    static var allTests = [
        ("testSimpleMatrixVectorMultiplication", testSimpleMatrixVectorMultiplication),
    ]
}
