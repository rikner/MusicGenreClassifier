import Cspblas

private enum BlasTransformType: UInt32 {
    // see blas_enum.h
    case noTransform = 111
    case transform = 112
}


public struct SparseMatrix: Sequence {
    let matrixID: blas_sparse_matrix
    var finalized: Bool = false

    // dimensions
    let m: Int
    let n: Int

    public init (_ m: Int, _ n: Int) {
        self.m = m
        self.n = n
        self.matrixID = sparse_uscr_begin_float(Int32(m), Int32(n))
    }

    @discardableResult
    public func insert(_ value: Float, i: Int, j: Int) -> Bool {
        if finalized {
            assertionFailure("You may not insert more values after finalizing")
            return false
        }

        return sparse_uscr_insert_entry_float(self.matrixID, value, Int32(i), Int32(j)) == 1
    }

    mutating public func finalize() {
        sparse_uscr_end_float(self.matrixID)
        finalized = true
    }

    public func makeIterator() -> Iterator {
        return Iterator(self)
    }

    /// The "indicies" used in this function are a bit confusing (which is why this function is not public):
    /// They refer to the indicies _of non-zero elements_ and do not relate to the actual matrix indicies at time of insertion. That means (0,0) refers to the first non-zero entry in the first row, (0,1) to the second in that row, (1,0) the first non-zero entry in the second row, etc.
    /// Use the iterator to fetch elements from the sparse matrix. If we need more control, we should add subscripts instead that return `Float?` by using a binary search over the given row (since the values should be sorted, but we need to check this)
    internal func getEntry(_ i: Int32, _ j: Int32) -> (value: Float, columnIndex: Int32)? {
        guard finalized else {
            preconditionFailure("You must finalize a sparse matrix before using it")
        }

        var result: Float = 0.0
        var columnIndex: Int32 = 0

        if sparse_get_entry_float(self.matrixID, i, j, &result, &columnIndex) == 1 {
            return (result, columnIndex)
        }

        return nil
    }

    @discardableResult
    public func destroy() -> Bool {
        return BLAS_usds(self.matrixID) == 1
    }

    @discardableResult
    public func multipliedByDenseVector(_ x: UnsafePointer<Float>) -> [Float] {
        guard finalized else {
            preconditionFailure("You must finalize a sparse matrix before using it")
        }

        var result = [Float](repeating: 0.0, count: self.m)

        sparse_usmv_float(
            blas_trans_type(rawValue: BlasTransformType.noTransform.rawValue),
            1,
            self.matrixID,
            x,
            1,
            &result,
            1
        )

        return result
    }
}

extension SparseMatrix {
    public struct Element: Hashable {
        public init (_ value: Float, i: Int, j: Int) {
            self.value = value
            self.i = i
            self.j = j
        }

        public let value: Float
        public let i: Int
        public let j: Int
    }

    public struct Iterator: IteratorProtocol {
        private let matrix: SparseMatrix
        private var index: (row: Int32, col: Int32) = (0,0)

        init(_ matrix: SparseMatrix) {
            self.matrix = matrix
        }

        public mutating func next() -> SparseMatrix.Element? {
            // if we get an entry, move to the next column
            if let entry = matrix.getEntry(index.row, index.col) {
                index.col += 1
                return SparseMatrix.Element(
                    entry.value,
                    i: Int(index.row),
                    j: Int(entry.columnIndex)
                )
            } else {
                // we have reached a column that does not exist
                // reset and go to next row
                index.row += 1
                index.col = 0

                if let entry = matrix.getEntry(index.row, index.col) {
                    index.col += 1
                    return SparseMatrix.Element(
                        entry.value,
                        i: Int(index.row),
                        j: Int(entry.columnIndex)
                    )
                }
            }

            // we have exhausted all possibilities
            return nil
        }
    }
}
