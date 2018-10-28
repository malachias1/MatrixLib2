//
//  MatrixLib.swift
//
//  Created by John Morris on 10/4/18.
//  Copyright © 2018 John Morris. All rights reserved.
//
//  The Vector and Matrix Framework offers a friendly alternative
//  to Accelerate in cases where accelerate is cumbersome or when
//  the one exceeds simd's limitations.

//  Ease of constructing and accessing matrix contents is central to the
//  implementation, an area in which Accelerate is dreadful (apart from simd,
//  which was too small for my needs).  Much of the performance penalty
//  one encounters is the result of constructing matrices. I suspect that
//  one will lose most of the performance advantages one might hope to
//  gain from Accelerate if one's matrices are relatively small, dense,
//  and frequently constructed.
//
//  Error Handling
//
//  There are plenty of opportunities for errors when it comes to indexing
//  vectors and matrices.  Error handling offers two approaches.  The first
//  catches the error, continues in a manner that will not cause a fault,
//  and logs the error. The second approach does not catch the error and
//  errors likely result in a fault.  Internally, these unsafe access methods
//  are used when indices are know to be valid.
//
//  These two approaches seem to offer the right balance of safety,
//  performance, simplicity (i.e., preferrable to propogating
//  errors or returning optional values), and consistancy (i.e.,
//  one can't throw from a subscript).
//
//  Memory Allocation:
//
//  None of the methods below explicitly allocate memory.
//  Unsafe buffer pointers are obtained from swift Arrays,
//  not allocated.
//
//  Performance Notes:
//
//  Four performance tests were run to obtain some sense of
//  how well the library performed.  All the tests were performed
//  on a Matrix (i.e., I don't have performance numbers for Vectors)
//  - Using the simulator, it takes 100-200ms to invert 1000 randomly
//    valued 10x10 matricies, including matrix creation. This runtime seems
//    a little slow to me, but it is adequate for the application I
//    have in mind.  The same test, takes about 600-700ms on an iPhone 6
//  - 100,000 unsafe_get followed by unsafe_set takes about 20-30ms
//  - 100,000 equivalent subscript operations take about 70-80ms, which are
//    checked and fail silently; so, expect a significant slowdown when
//    using subscripts.
//  - 1000 matrix multiplies of two randomly valued 10x10 matrices takes
//    about 20ms using the simulator
//
//  Where computationally intensive operations are performed
//  and indices are known to be good, I use
//  withUnsafeBufferPointer and withUnsafeMutableBufferPointer.
//
//  The LU Decomposition was ported from C code founded at
//  https://en.wikipedia.org/wiki/LU_decomposition)
//

import Foundation
import os.log
import Accelerate

infix operator **: MultiplicationPrecedence

fileprivate let EPSILON = 0e-10

/**
 Protocol for a vector, a 1D array.  Note that a vector
 holds values of type Double.
 */
public protocol V: Sequence, CustomStringConvertible {
    /// The length of the vector
    var count: Int { get }
    /// The shape of a vector is always count * 1
    /// This addition allows me to use the same set
    /// operators for vectors and matrices.
    var shape: (n: Int, m: Int) { get }
    /// V assumes that the underlying data may can be representated
    /// as an array of Doubles.
    var values: [Double] { get }
    
    // Mark: Getting and setting values
    
    /**
     Return the value at the given index. The index is
     not checked. An index out of bounds will cause a
     fault.
     - parameter index: an index
     - returns: the value at the given index
     */
    func unsafe_get(_ index: Int) -> Double
    /**
     Set the value at the given index to the given value. The
     index is not checked. An index out of bounds will cause a
     fault.
     - parameter index: an index
     - parameter value: a value
     */
    mutating func unsafe_set(_ index: Int, _ value: Double)
    /**
     Return the value at the given index. An index out of bounds
     will cause a silent failure. An invalid index will cause an error to
     be logged and 0.0 will be returned.
     to be returned.
     - parameter index: an index
     - returns: the value at the given index
     */
    func get(_ index: Int) -> Double
    /**
     Set the value at the given index to the given value. The
     index is checked. An index out of bounds will cause a
     silent failure. An invalid index will cause an error to
     be logged. Nothing will be done.
     - parameter index: an index
     - parameter value: a value
     - returns: the value at the given index
     */
    mutating func set(_ index: Int, _ value: Double)
    /**
     Set or get the value at the given index. The
     index is checked. An index out of bounds will cause a
     silent failure. On a get an invalid index will return 0.0.
     On a set an invalid index will do nothing. An invalid index
     will cause an error to be logged.
     */
    subscript(index: Int) -> Double { get set }
}

public extension V {
    /// The number of elements in V
    var count: Int {
        get {
            return values.count
        }
    }
    
    func get(_ index: Int) -> Double {
        guard 0 <= index && index < count else {
            return 0.0
        }
        return unsafe_get(index)
    }
    
    mutating func set(_ index: Int, _ value: Double) {
        guard 0 <= index && index < count else {
            return
        }
        
        unsafe_set(index, value)
    }
    
    subscript(index: Int) -> Double {
        get {
            return get(index)
        }
        
        set {
            set(index, newValue)
        }
    }
    
    /**
     Set the elements in this instance to those in values.
     If the length of values differs from that of this
     instance, an error will be logged and nothing will be
     done.
     - parameter values: an array of values of the same
     length as this instance
     */
    mutating func set(values: [Double]) {
        guard count == values.count else {
            countMismatchLogMsg(count, values.count)
            return
        }
        
        for i in 0..<count {
            unsafe_set(i, values[i])
        }
    }
    
    /**
     Set the elements in this instance to those in values.
     If the number of values given differs from that of this
     instance, an error will be logged and nothing will be
     done.
     - parameter values: an array of values of the same
     length as this instance
     */
    mutating func set(values: Double...) {
        set(values: Array<Double>(values))
    }
    
    /**
     Set the elements in this instance to those in values.
     If the length of values differs from that of this
     instance, an error will be logged and nothing will be
     done.
     - parameter values: an array of values of the same
     length as this instance
     */
    mutating func set<T: V>(values: T) {
        guard count == values.count else {
            countMismatchLogMsg(count, values.count)
            return
        }
        
        for i in 0..<count {
            unsafe_set(i, values.unsafe_get(i))
        }
    }
    
    /**
     Return the default description string for this instance.
     */
    var defaultDescription: String {
        var text = "["
        for i in 0..<count {
            if i > 0 {
                text += ", "
            }
            text += "\(self[i])"
        }
        return text + "]"
    }
    
    /**
     Return true if index is a valid index, i.e.: >= to 0
     and < count.
     - returns: if index is valid
     */
    internal func indexIsValid(index: Int) -> Bool {
        return 0 <= index && index < count
    }
    
    internal func defaultLogIndexOutOfBoundsMsg(_ index: Int) {
        os_log("Index out of bounds: upper bound is %d, index given is %d", log: .default, type: .error, count, index)
    }
    
    internal func countMismatchLogMsg(_ count: Int, _ other: Int) {
        os_log("Count mismatch: expected count = %d, actual count = %d",
               log: .default, type: .error, count, values.count)
    }
}

/**
 An iterator for any struct or class implementing the V
 protocol. The iterator traverses a Vector sequentially and
 traverses Matrix in column-major order. Other instances
 that conform to the V protocol may have different
 traversal patterns.
 */
public struct VIter<T: V>: IteratorProtocol {
    public typealias Element = Double
    private var idx: Int?
    private var v: T
    
    public init(v: T) {
        self.v = v
        self.idx = 0
    }
    
    public mutating func next() -> VIter.Element? {
        guard idx != nil else {
            return nil
        }
        
        let value = v.unsafe_get(idx!)
        idx! += 1
        if idx! >= v.count {
            idx = nil
        }
        return value
    }
}

/**
 Perform the given binary operation on the left operand
 and right operand and return the result.
 - parameter left: an instance that conforms to V
 - parameter right: a value
 - parameter f: a closure for combining left elements and right operands
 - returns: a new T that conforms to V
 */
func binaryOp<T: V> (left: T, right: Double, f: (Double, Double) -> Double) -> T {
    var result = left
    for i in 0..<left.count {
        result.unsafe_set(i, f(left.unsafe_get(i), right))
    }
    return result
}

/**
 Perform the given binary operation on the left operand
 and right operand and return the result.  Left and right
 operands must be of the same shape. If they are not of the
 same shape, an error will be logged and left operand will be
 returned unchanged.
 - parameter left: an instance that conforms to V
 - parameter right: an instance that conforms to V
 - parameter f: a closure for combining left and right operand elements
 - returns: a new T that conforms to V
 */
func binaryOp<T: V> (left: T, right: T, f: (Double, Double) -> Double) -> T {
    guard left.shape == right.shape else {
        os_log("Shape mismatch: left shape = %@, right shape = %@",
               log: .default, type: .error, "\(left.shape)", "\(right.shape)")
        return left
    }
    
    var result = left
    for i in 0..<left.count {
        result.unsafe_set(i, f(left.unsafe_get(i), right.unsafe_get(i)))
    }
    return result
}
/**
 Add a scalar value to the given instance elementwise.
 - parameter left: an instance that conforms to V
 - parameter right: a scalar
 - returns: a new T that conforms to V
 */
public func +<T: V> (left: T, right: Double) -> T {
    return binaryOp(left: left, right: right, f: {$0 + $1})
}

/**
 Substract a scalar value to the given instance elementwise.
 - parameter left: an instance that conforms to V
 - parameter right: a scalar
 - returns: a new T that conforms to V
 */
public func -<T: V> (left: T, right: Double) -> T {
    return binaryOp(left: left, right: right, f: {$0 - $1})
}

/**
 Multiply a scalar value to the given instance elementwise.
 - parameter left: an instance that conforms to V
 - parameter right: a scalar
 - returns: a new T that conforms to V
 */
public func *<T: V> (left: T, right: Double) -> T {
    return binaryOp(left: left, right: right, f: {$0 * $1})
}

/**
 Divide a scalar value to the given instance elementwise.
 - parameter left: an instance that conforms to V
 - parameter right: a scalar
 - returns: a new T that conforms to V
 */
public func /<T: V> (left: T, right: Double) -> T {
    return binaryOp(left: left, right: right, f: {$0 / $1})
}

/**
 Add two instances that conform to V and have the same shape
 Note that if the two instances do not have the same shape,
 an error message will be logged and the left instance will
 be returned.
 - parameter left: an instance that conforms to V
 - parameter right: an instance that conforms to V
 - returns: a new T that conforms to V
 */
public func +<T: V> (left: T, right: T) -> T {
    return binaryOp(left: left, right: right, f: {$0 + $1})
}

/**
 Subtract two instances that conform to V and have the same shape
 Note that if the two instances do not have the same shape,
 an error message will be logged and the left instance will
 be returned.
 - parameter left: an instance that conforms to V
 - parameter right: an instance that conforms to V
 - returns: a new T that conforms to V
 */
public func -<T: V> (left: T, right: T) -> T {
    return binaryOp(left: left, right: right, f: {$0 - $1})
}

/**
 Multiply two instances that conform to V and have the same shape
 Note that if the two instances do not have the same shape,
 an error message will be logged and the left instance will
 be returned.
 - parameter left: an instance that conforms to V
 - parameter right: an instance that conforms to V
 - returns: a new T that conforms to V
 */
public func *<T: V> (left: T, right: T) -> T {
    return binaryOp(left: left, right: right, f: {$0 * $1})
}

/**
 Divide two instances that conform to V and have the same shape
 Note that if the two instances do not have the same shape,
 an error message will be logged and the left instance will
 be returned.
 - parameter left: an instance that conforms to V
 - parameter right: an instance that conforms to V
 - returns: a new T that conforms to V
 */
public func /<T: V> (left: T, right: T) -> T {
    return binaryOp(left: left, right: right, f: {$0 / $1})
}

/**
 Return the result of changing the sign of each element in the
 instance.
 - parameter left: an instance that conforms to V
 - returns: a new T that conforms to V
 */
public prefix func -<T: V> (left: T) -> T {
    var result = left
    for i in 0..<left.count {
        result.unsafe_set(i, -left.unsafe_get(i))
    }
    return result
}

/**
 Add a scalar value to the given instance elementwise.
 - parameter left: an instance that conforms to V
 - parameter right: a scalar
 - returns: the modified left value
 */
public func +=<T: V>( left: inout T, right: Double) -> T {
    for i in 0..<left.count {
        left.unsafe_set(i, left.unsafe_get(i) + right)
    }
    return left
}

/**
 Subtract a scalar value to the given instance elementwise.
 - parameter left: an instance that conforms to V
 - parameter right: a scalar
 - returns: the modified left value
 */
public func -=<T: V>( left: inout T, right: Double) -> T {
    for i in 0..<left.count {
        left.unsafe_set(i, left.unsafe_get(i) - right)
    }
    return left
}

/**
 Multiply a scalar value to the given instance elementwise.
 - parameter left: an instance that conforms to V
 - parameter right: a scalar
 - returns: the modified left value
 */
public func *=<T: V>( left: inout T, right: Double) -> T {
    for i in 0..<left.count {
        left.unsafe_set(i, left.unsafe_get(i) * right)
    }
    return left
}

/**
 Divide a scalar value to the given instance elementwise.
 - parameter left: an instance that conforms to V
 - parameter right: a scalar
 - returns: the modified left value
 */
public func /=<T: V>( left: inout T, right: Double) -> T {
    for i in 0..<left.count {
        left.unsafe_set(i, left.unsafe_get(i) / right)
    }
    return left
}

/**
 Perform the given assignment operation, elementwise, on the left operand
 and right operand, where the left and right operands conform to the V
 protocol and have the same shape.
 */
public func assignmentOp<T: V> (left: inout T, right: T, f: (Double, Double) -> Double) -> T {
    guard left.shape == right.shape else {
        os_log("Shape mismatch: left shape = %@, right shape = %@",
               log: .default, type: .error, "\(left.shape)", "\(right.shape)")
        return left
    }
    
    for i in 0..<left.count {
        left.unsafe_set(i, f(left.unsafe_get(i), right.unsafe_get(i)))
    }
    return left
}

/**
 Add a two operands elementwise.
 - parameter left: an instance that conforms to V
 - parameter right: an instance that conforms to V
 - returns: the modified left value
 */
public func +=<T: V>( left: inout T, right: T) -> T {
    return assignmentOp(left: &left, right: right, f: {$0 + $1})
}

/**
 Subtract a right operand from left operand elementwise.
 - parameter left: an instance that conforms to V
 - parameter right: an instance that conforms to V
 - returns: the modified left value
 */
public func -=<T: V>( left: inout T, right: T) -> T {
    return assignmentOp(left: &left, right: right, f: {$0 - $1})
}

/**
 Multiply a two operands elementwise.
 - parameter left: an instance that conforms to V
 - parameter right: an instance that conforms to V
 - returns: the modified left value
 */
public func *=<T: V>( left: inout T, right: T) -> T {
    return assignmentOp(left: &left, right: right, f: {$0 * $1})
}

/**
 Divide a right operand from left operand elementwise.
 - parameter left: an instance that conforms to V
 - parameter right: an instance that conforms to V
 - returns: the modified left value
 */
public func /=<T: V>( left: inout T, right: T) -> T {
    return assignmentOp(left: &left, right: right, f: {$0 / $1})
}


/**
 Protocol for a matrix, a 2D array.  Note that a matrix
 holds values of type Double.
 */
public protocol M: V {
    /**
     Return the value at the given row and column index. The indices are
     not checked. An index out of bounds will cause a
     fault.
     - parameter row: a row index
     - parameter column: a column index
     - returns: the value at the given row and column index
     */
    func unsafe_get(_ row: Int, _ column: Int) -> Double
    /**
     Set the value at the given row and column index to the given value. The
     indices are not checked. An index out of bounds will cause a
     fault.
     - parameter row: a row index
     - parameter column: a column index
     */
    mutating func unsafe_set(_ row: Int, _ column: Int, _ value: Double)
    /**
     Return the element at the given row and column.
     In the event that either the row or column are invalid,
     a message will be logged, get will return 0.0, and set will
     do nothing.
     - parameter row: a row index in the matrix, where row is >- 0 and < count
     */
    subscript(row: Int, col: Int) -> Double { get set }
    func get(_ row: Int, _ column: Int) -> Double
    mutating func set(_ row: Int, _ column: Int, _ newValue: Double)
}

public extension M {
    public var count: Int {
        get {
            return n*m
        }
    }
    
    var n: Int {
        get {
            return shape.n
        }
    }
    
    var m: Int {
        get {
            return shape.m
        }
    }
    
    mutating func assign(other: Matrix) {
        guard shape == other.shape else {
            os_log("Shape mismatch: expected shape = %@, actual shape = %@",
                   log: .default, type: .error, "\(shape)", "\(other.shape)")
            return
        }
        
        for (i,v) in other.values_.enumerated() {
            unsafe_set(i, v)
        }
    }
    
    func get(_ row: Int, _ column: Int) -> Double {
        if !indexIsValid(row: row, column: column) {
            rowOrColumnOfRangeLogMsg(row: row, column: column)
            return 0.0
        }
        
        return unsafe_get(row, column)
    }
    
    mutating func set(_ row: Int, _ column: Int, _ newValue: Double) {
        if !indexIsValid(row: row, column: column) {
            rowOrColumnOfRangeLogMsg(row: row, column: column)
            return
        }
        unsafe_set(row, column, newValue)
    }
    
    subscript(row: Int, column: Int) -> Double {
        get {
            return get(row, column)
        }
        
        set {
            set(row, column, newValue)
        }
    }
    
    mutating func swapRows(row1: Int, row2: Int) {
        if row1 != row2 {
            for col in 0..<m {
                let t = unsafe_get(row1, col)
                unsafe_set(row1, col, unsafe_get(row2, col))
                unsafe_set(row2, col, t)
            }
        }
    }
    
    mutating func set(value: Double, forRow: Int) {
        for j in 0..<m {
            unsafe_set(forRow, j, value)
        }
    }
    
    /**
     Return the specified row of the matrix as a vector.
     - parameter index: the index of the desired row
     - returns: the specified row of the matrix
     */
    public func getValues(forRow: Int) -> Vector {
        var values = [Double]()
        for j in 0..<m {
            values.append(unsafe_get(forRow, j))
        }
        return Vector(values: values)
    }
    
    public mutating func set(values: [Double], forRow: Int) {
        guard m == values.count else {
            os_log("Count mismatch: column length = %d, values count = %d",
                   log: .default, type: .error, n, values.count)
            return
        }
        
        for j in 0..<m {
            set(forRow, j, values[j])
        }
    }
    
    public mutating func set(values: Double..., forRow: Int) {
        set(values: Array<Double>(values), forRow: forRow)
    }
    
    public mutating func set<T: V>(values:T, forRow: Int) {
        set(values: values.values, forRow: forRow)
    }
    
    /**
     Return the specified column of the matrix as a vector.
     - parameter index: the index of the desired column
     - returns: the specified column of the matrix
     */
    public func getValues(forColumn: Int) -> Vector {
        var values = [Double]()
        for i in 0..<n {
            values.append(self[i, forColumn])
        }
        return Vector(values: values)
    }
    
    public mutating func set(value: Double, forColumn: Int) {
        for i in 0..<n {
            set(i, forColumn, value)
        }
    }
    
    public mutating func set(values: [Double], forColumn: Int) {
        guard n == values.count else {
            os_log("Count mismatch: column length = %d, values count = %d",
                   log: .default, type: .error, n, values.count)
            return
        }
        
        for i in 0..<n {
            set(i, forColumn, values[i])
        }
    }
    
    public mutating func set(values: Double..., forColumn: Int) {
        set(values: Array<Double>(values), forColumn: forColumn)
    }
    
    public mutating func set<T: V>(values:T, forColumn: Int) {
        set(values: values.values, forColumn: forColumn)
    }
    
    internal static func idx(_ fromRow: Int, _ col: Int, _ numRows: Int) -> Int {
        return col*numRows + fromRow
    }
    
    internal func indexIsValid(row: Int, column: Int) -> Bool {
        return 0 <= row && row < n && 0 <= column && column < m
    }
    
    internal func rowOrColumnOfRangeLogMsg(row: Int, column: Int) {
        os_log("Row or column out of range: row = %d, column = %d, n = %d, m = %d",
               log: .default, type: .error, row, column, n, m)
    }
}

/**
 A Vector is an
 */
public struct Vector: V {
    /// The values in the vector
    var values_: [Double]
    /// The public version of values
    public var values: [Double] {
        get {
            return values_
        }
    }
    /// The vector shape is always nx1
    public var shape: (n: Int, m: Int) {
        get {
            return (count, 1)
        }
    }
    
    init(count: Int, initialValue: Double = 0.0) {
        self.values_ = Array<Double>(repeating: initialValue, count: count)
    }
    
    init(values: [Double]) {
        self.values_ = Array<Double>(values)
    }
    
    init(values: Double...) {
        self.values_ = Array<Double>(values)
    }
    
    // Mark: Getting and setting values
    
    public func unsafe_get(_ index: Int) -> Double {
        return self.values_[index]
    }
    
    public mutating func unsafe_set(_ index: Int, _ value: Double) {
        self.values_[index] = value
    }
    
    public var description: String {
        get {
            return defaultDescription
        }
    }
    
    public func makeIterator() -> VIter<Vector> {
        return VIter(v: self)
    }
    
    func withUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Double>) throws -> R) rethrows -> R {
        return try values_.withUnsafeBufferPointer(body)
    }
    
    mutating func withUnsafeMutableBufferPointer<R>(_ body: (inout UnsafeMutableBufferPointer<Double>) throws -> R) rethrows -> R {
        return try values_.withUnsafeMutableBufferPointer(body)
    }
}

/**
 Data in the Matrix is arranged held in an
 Array in column-major order.  That means that
 the array index for a given row and column is
 equal to: (column_index*number_of_rows) + row_index.
 
 */
public struct Matrix: M {
    let n_: Int
    let m_: Int
    var values_: [Double]
    public var values: [Double] {
        get {
            return values_
        }
    }
    
    public var shape: (n: Int, m: Int) {
        get {
            return (n_, m_)
        }
    }
    
    public var description: String {
        var text = "["
        for i in 0..<n {
            if i > 0 {
                text += ",\n "
            }
            text += "["
            for j in 0..<m {
                if j > 0 {
                    text += ", "
                }
                text += "\(self[i, j])"
            }
            text += "]"
        }
        return text + "]"
    }
    
    public init() {
        self.n_ = 0
        self.m_ = 0
        self.values_ = [Double]()
    }
    
    /**
     Construct an n x m matrix with an initial value.
     - parameter n: the number of rows in the matrix
     - parameter m: the number of columns in the matrix
     - parameter initialValue: the initial value for the matrix elements (the default is 0.0)
     */
    public init(n: Int, m: Int, initialValue: Double = 0.0) {
        self.n_ = n
        self.m_ = m
        values_ = Array<Double>(repeating: initialValue, count: n*m)
    }
    
    /**
     Construct an n x 1 matrix with an initial value.
     - parameter n: the number of rows in the matrix
     - parameter initialValue: the initial value for the matrix elements (the default is 0.0)
     */
    public init(n: Int, initialValue: Double = 0.0) {
        self.init(n: n, m: 1, initialValue: initialValue)
    }
    
    /**
     Construct an 1 x m matrix with an initial value.
     - parameter m: the number of columns in the matrix
     - parameter initialValue: the initial value for the matrix elements (the default is 0.0)
     */
    public init(m: Int, initialValue: Double = 0.0) {
        self.init(n: 1, m: m, initialValue: initialValue)
    }
    
    /**
     Construct a matrix with a given shape and initial value.
     - parameter shape: the shape of the matrix (n: no. rows, m: no. columns)
     - parameter initialValue: the initial value for the matrix elements (the default is 0.0)
     */
    public init(shape: (n: Int, m: Int), initialValue: Double = 0.0) {
        self.n_ = shape.n
        self.m_ = shape.m
        values_ = Array<Double>(repeating: initialValue, count: self.n_*self.m_)
    }
    
    /**
     Construct a matrix with the shape of the given two dimensional array.
     The matrix is initialized with the values of the given array.
     If the inner arrays, the column values, are of differing lengths an
     error will be logged. The number of values initialized will be the
     minimum of the inner array length and length of the first inner array.
     - parameter values: a two dimensional array
     */
    public init(values: [[Double]]) {
        let m = values.count
        let n = values[0].count
        
        self.init(n: n, m: m)
        
        if !values.allSatisfy({$0.count == n}) {
            os_log("Count mismatch: not all columns are of the same length",
                   log: .default, type: .error)
        }
        
        for j in 0..<m {
            for i in 0..<Swift.min(values[j].count, n) {
                set(i, j, values[j][i])
            }
        }
    }
    
    public func unsafe_get(_ index: Int) -> Double {
        return values_[index]
    }
    
    public mutating func unsafe_set(_ index: Int, _ value: Double) {
        values_[index] = value
    }
    
    public func unsafe_get(_ row: Int, _ column: Int) -> Double {
        return values_[column*self.n_ + row]
    }
    
    public mutating func unsafe_set(_ row: Int, _ column: Int, _ newValue: Double) {
        values_[column*self.n_ + row] = newValue
    }
    
    /**
     Return a column-major iterator for the matrix.
     - returns: a column-major iterator for the matrix
     */
    public func makeIterator() -> VIter<Matrix> {
        return VIter(v: self)
    }
    
    /**
     Return an identity matrix with dimension n.
     - returns: an identity matrix with dimension n
     */
    public static func identity(n: Int) -> Matrix {
        var mat = Matrix(n: n, m: n)
        for i in 0..<n {
            mat.values_[i*n + i] = 1.0
        }
        return mat
    }
    
    /**
     Return a matrix with dimension nxm with random doubles between
     0 and 1.
     - parameter n: the number of rows in the matrix
     - parameter m: the number of columns in the matrix
     - returns: a matrix with dimension nxm with random doubles between
     0 and 1
     */
    public static func random(n: Int, m: Int) -> Matrix {
        var mat = Matrix(n: n, m: m)
        let count = mat.count
        mat.withUnsafeMutableBufferPointer {ptr in
            for i in 0..<count {
                ptr[i] = Double.random(in: 0.0...1.0)
            }
        }
        return mat
    }
    
    /// Return the transpose of the matrix.
    public var T: Matrix {
        get {
            var result = Matrix(n: m, m: n)
            let N = n
            let M = m
            
            return withUnsafeBufferPointer {ptr -> Matrix in
                result.withUnsafeMutableBufferPointer { rptr in
                    for r in 0..<N {
                        for c in 0..<M {
                            rptr[r*M + c] = ptr[c*N + r]
                        }
                    }
                }
                return result
            }
        }
    }
    
    private static func invertable(aptr: UnsafeBufferPointer<Double>, N: Int) -> Bool {
        for i in 0..<N {
            var invertible = false
            for j in 0..<N {
                if aptr[j*N + i] != 0.0 {
                    invertible = true
                    break
                }
            }
            
            if !invertible {
                return false
            }
        }
        return true
    }
    
    func withUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Double>) throws -> R) rethrows -> R {
        return try values_.withUnsafeBufferPointer(body)
    }
    
    mutating func withUnsafeMutableBufferPointer<R>(_ body: (inout UnsafeMutableBufferPointer<Double>) throws -> R) rethrows -> R {
        return try values_.withUnsafeMutableBufferPointer(body)
    }
    
    
    /// Return the inverted matrix.
    /// If the matrix is not invertable, nil is returned
    /// The matrix is tested for invertibility by
    /// performing a gaussian elimination and then
    /// looking for any row that is all zeros.  If
    /// one such row exists, the matrix is not invertable
    public var I: Matrix? {
        get {
            guard n_ == m_ else {
                return nil
            }
            let N = self.n
            var x = Matrix(shape: shape)
            var b = Matrix.identity(n: N)
            
            // Transform the matrix into an upper triangle
            //let indices = Matrix.gaussian(mat: &a)
            let (a, indices) = gaussian()
            
            return a.withUnsafeBufferPointer { aptr -> Matrix? in
                if Matrix.invertable(aptr: aptr, N: N) {
                    indices.withUnsafeBufferPointer { iptr in
                        x.withUnsafeMutableBufferPointer { xptr in
                            b.withUnsafeMutableBufferPointer { bptr in
                                
                                // Update the matrix b[i, j] with the ratios stored
                                for i in 0..<N-1 {
                                    for j in i+1..<N {
                                        for k in 0..<N {
                                            bptr[k*N + iptr[j]] -= aptr[i*N + iptr[j]] * bptr[k*N + iptr[i]]
                                        }
                                    }
                                }
                                
                                // Perform backward substitutions
                                let jj = (0...N-2).reversed()
                                for i in 0..<N {
                                    xptr[i*N + N-1] = bptr[i*N + iptr[N-1]]/aptr[(N-1)*N + iptr[N-1]]
                                    for j in jj {
                                        xptr[i*N + j] = bptr[i*N + iptr[j]]
                                        for k in j+1..<N {
                                            xptr[i*N + j] -= aptr[k*N + iptr[j]]*xptr[i*N + k]
                                        }
                                        xptr[i*N + j] /= aptr[j*N + iptr[j]]
                                    }
                                }
                            }
                        }
                    }
                    return x
                } else {
                    return nil
                }
            }
        }
    }
    
    mutating func buildDense() -> DenseMatrix_Double {
        return DenseMatrix_Double(rowCount: Int32(n_), columnCount: Int32(m_),
                                  columnStride: Int32(n_), attributes: SparseAttributes_t(),
                                  data: &values_)
    }
    
    private func indexOutOfRangeLogMsg(index: Int) {
        os_log("Index out of range: count = %d, index = %d",
               log: .default, type: .error, count, index)
    }
    
    public static func **(left: Matrix, right: Matrix)  -> Matrix {
        let N = left.n
        let M = left.m
        let P = right.m
        var x = Matrix(n: N, m: P)
        
        return left.withUnsafeBufferPointer { lptr -> Matrix in
            right.withUnsafeBufferPointer { rptr in
                x.withUnsafeMutableBufferPointer { xptr in
                    for r in 0..<N {
                        for c in 0..<P {
                            var t = 0.0
                            for i in 0..<M {
                                t += lptr[i*N + r] * rptr[c*M + i]
                            }
                            xptr[c*N + r] = t
                        }
                    }
                }
            }
            return x
        }
    }
    
    /**
     Return a matrix consisting of matrices L-E and U and the permutation vector.
     The permutation vector is stored as an integer array P of size N+1
     containing column indexes where the permutation matrix has "1". The last element P[N]=S+N,
     where S is the number of row exchanges needed for determinant computation, det(P)=(-1)^S.
     - parameter Tol: tolerance used to determine whether a matrix is degenerate
     - returns: the inverse of the matrix
     */
    func LUPDecompose(Tol: Double=EPSILON) -> (A: Matrix, P: [Int])? {
        let N = n_
        let M = m_
        var A = self
        var P = Array<Int>(repeating: 0, count: N+1)
        
        let success = A.withUnsafeMutableBufferPointer { aptr -> Bool in
            P.withUnsafeMutableBufferPointer { pptr in
                for i in 0...N {
                    pptr[i] = i //Unit permutation matrix, P[N] initialized with N
                }
                
                for i in 0..<N {
                    var maxA = 0.0
                    var imax = i
                    
                    for k in i..<N {
                        let absA = abs(aptr[i*N + k])
                        if (absA > maxA) {
                            maxA = absA
                            imax = k
                        }
                    }
                    
                    if (maxA < Tol) {
                        return false //failure, matrix is degenerate
                    }
                    
                    if (imax != i) {
                        //pivoting P
                        let j = pptr[i]
                        pptr[i] = pptr[imax]
                        pptr[imax] = j
                        
                        //pivoting rows of A
                        for col in 0..<M {
                            let t = aptr[col*N + i]
                            aptr[col*N + i] = aptr[col*N + imax]
                            aptr[col*N + imax] = t
                        }
                        
                        //counting pivots starting from N (for determinant)
                        pptr[N] += 1
                    }
                    
                    for j in i+1..<N {
                        aptr[i*N + j] /= aptr[i*N + i]
                        
                        for k in i+1..<N {
                            aptr[k*N + j] -= aptr[i*N + j] * aptr[k*N + i]
                        }
                    }
                }
                return true
            }
        }
        
        return success ? (A, P) : nil //decomposition done
    }
    
    /**
     Solve an equation A*x=b for x, where A is this matrix
     - parameter b: the rhs vector
     - parameter Tol: tolerance used to determine whether a matrix is degenerate
     - returns: x the solution vector of A*x=b
     */
    func LUPSolve(b: Vector, Tol: Double=EPSILON) -> Vector? {
        if let (A, P) = LUPDecompose(Tol: Tol) {
            let N = n_
            var x = Vector(count: N)
            return A.withUnsafeBufferPointer { aptr -> Vector in
                P.withUnsafeBufferPointer { pptr in
                    b.withUnsafeBufferPointer { bptr in
                        x.withUnsafeMutableBufferPointer { xptr in
                            for i in 0..<N {
                                xptr[i] = bptr[pptr[i]]
                                
                                for k in 0..<i {
                                    xptr[i] -= aptr[k*N + i] * xptr[k]
                                }
                            }
                            
                            for i in (0...N-1).reversed() {
                                for k in i+1..<N {
                                    xptr[i] -= aptr[k*N + i] * xptr[k]
                                }
                                xptr[i] /= aptr[i*N + i]
                            }
                        }
                        return x
                    }
                }
            }
        }
        return nil
    }
    
    /**
     Return the inverse of this matrix. Nil will be returned
     if it is determined during LUP decomposition that the
     matrix is degenerate
     - parameter Tol: tolerance used to determine whether a matrix is degenerate
     - returns: the inverse of the matrix
     */
    func LUPInvert(Tol: Double=EPSILON) -> Matrix? {
        if let (A, P) = LUPDecompose(Tol: Tol) {
            let N = n_
            var IA = Matrix(n: N, m: N)
            
            A.withUnsafeBufferPointer { aptr in
                P.withUnsafeBufferPointer { pptr in
                    IA.withUnsafeMutableBufferPointer { iaptr in
                        for j in 0..<N {
                            for i in 0..<N {
                                if (pptr[i] == j) {
                                    iaptr[j*N + i] = 1.0
                                } else {
                                    iaptr[j*N + i] = 0.0
                                }
                                
                                for k in 0..<i {
                                    iaptr[j*N + i] -= aptr[k*N + i]*iaptr[j*N + k]
                                }
                            }
                            
                            for i in (0...N-1).reversed()  {
                                for k in i+1..<N {
                                    iaptr[j*N + i] -= aptr[k*N + i]*iaptr[j*N + k]
                                }
                                iaptr[j*N + i] /= aptr[i*N + i]
                            }
                        }
                        
                    }
                }
            }
            return IA
        }
        return nil
    }
    
    /**
     Return the determinate of this matrix. Nil will be returned
     if it is determined that the underlying LUP decomposition of this
     matrix is degenerate
     - parameter Tol: tolerance used to determine whether a matrix is degenerate
     - returns: the determinate of this matrix
     */
    func LUPDeterminant(Tol: Double=EPSILON) -> Double? {
        if let (A, P) = LUPDecompose(Tol: Tol) {
            let N = n_
            return A.withUnsafeBufferPointer { aptr -> Double? in
                return P.withUnsafeBufferPointer { pptr -> Double? in
                    var det = aptr[0]
                    
                    for i in 0..<N {
                        det *= aptr[i*N + i];
                    }
                    
                    if ((pptr[N] - N) % 2 == 0) {
                        return det
                    }
                    else {
                        return -det;
                    }
                }
            }
        }
        return nil
    }
    
    func gaussian() -> (A: Matrix, indices: [Int]) {
        let N = n
        var indices = Array<Int>(repeating: 0, count: N)
        var c = Array<Double>(repeating: 0.0, count: N)
        var A = self
        
        indices.withUnsafeMutableBufferPointer{ iptr in
            c.withUnsafeMutableBufferPointer { cptr in
                A.values_.withUnsafeMutableBufferPointer { aptr in
                    
                    // Initialize the index
                    for i in 0..<N {
                        iptr[i] = i
                    }
                    
                    // Find the rescaling factors, one from each row
                    for i in 0..<N {
                        var c1 = 0.0
                        for j in 0..<N {
                            let idx = j*N + i
                            c1 = Swift.max(c1, abs(aptr[idx]))
                        }
                        cptr[i] = c1
                    }
                    
                    // Search the pivoting element from each column
                    var k = 0;
                    for j in 0..<N-1 {
                        var pi1 = 0.0
                        for i in j..<N {
                            let idx = j*N + iptr[i]
                            var pi0 = abs(aptr[idx])
                            if pi0 > 0.0 {
                                pi0 /= cptr[iptr[i]]
                                if pi0 > pi1 {
                                    pi1 = pi0
                                    k = i
                                }
                            }
                        }
                        
                        // Interchange rows according to the pivoting order
                        let itmp = iptr[j]
                        iptr[j] = iptr[k]
                        iptr[k] = itmp
                        for i in j+1..<N {
                            let idx1 = j*N + iptr[i]
                            let idx2 = j*N + iptr[j]
                            let pj = aptr[idx1]/aptr[idx2]
                            
                            // Record pivoting ratios below the diagonal
                            aptr[idx1] = pj
                            
                            // Modify other elements accordingly
                            for l in j+1..<N {
                                let idx1 = l*N + iptr[i]
                                let idx2 = l*N + iptr[j]
                                aptr[idx1] -= pj*aptr[idx2]
                            }
                        }
                    }
                }
            }
        }
        
        return (A, indices)
    }
}

public struct SparseMatrix: M {
    public var description: String {
        var text = "[\n"
        for (index, value) in values_ {
            let column = index/n_
            let row = index % n_
            text += "[\(row), \(column): \(value)]\n"
        }
        text += "]"
        return text
    }
    
    let n_: Int
    let m_: Int
    
    var rowIndices_: [Int32]?
    var columnStarts_:[Int]?
    var orderedValues_: [Double]?
    
    public var shape: (n: Int, m: Int)
    var values_: [Int: Double] = [:]
    /// The dense array equivalent of this sparse matrix.
    /// if this metrix is truly large, rendering it as a
    /// dense array is a bad idea.
    public var values: [Double] {
        get {
            var values = [Double]()
            for v in self {
                values.append(v)
            }
            
            return values
        }
    }
    
    /**
     Construct an n x m matrix with an initial value of 0.0.
     - parameter n: the number of rows in the matrix
     - parameter m: the number of columns in the matrix
     */
    public init(n: Int, m: Int) {
        self.n_ = n
        self.m_ = m
        self.shape = (self.n_, self.m_)
    }
    
    /**
     Construct an n x 1 matrix with an initial value of 0.0.
     - parameter n: the number of rows in the matrix
     */
    public init(n: Int) {
        self.init(n: n, m: 1)
    }
    
    /**
     Construct an 1 x m matrix with an initial value of 0.0.
     - parameter m: the number of columns in the matrix
     */
    public init(m: Int, initialValue: Double = 0.0) {
        self.init(n: 1, m: m)
    }
    
    /**
     Construct a matrix with a given shape and initial value of 0.0.
     - parameter shape: the shape of the matrix (n: no. rows, m: no. columns)
     */
    public init(shape: (n: Int, m: Int)) {
        self.init(n: shape.n, m: shape.m)
    }
    
    /**
     Construct a matrix with the same shape of the given matrix and initial value.
     - parameter matrix: the source of the constructed matrix's shape
     */
    public init<T: M>(matrix: T) {
        self.init(shape: matrix.shape)
        for (i, v) in matrix.enumerated() {
            let v = v as! Double
            unsafe_set(i, Double(v))
        }
    }
    
    /**
     Construct a matrix with the shape of the given two dimensional array.
     The matrix is initialized with the values of the given array.
     If the inner arrays, the column values, are of differing lengths an
     error will be logged. The number of values initialized will be the
     minimum of the inner array length and length of the first inner array.
     - parameter values: a two dimensional array
     */
    public init(values: [[Double]]) {
        let m = values.count
        let n = values[0].count
        
        self.init(n: n, m: m)
        
        if !values.allSatisfy({$0.count == n}) {
            os_log("Count mismatch: not all columns are of the same length",
                   log: .default, type: .error)
        }
        
        for j in 0..<m {
            for i in 0..<Swift.min(values[j].count, n) {
                let value = values[j][i]
                if value != 0.0 {
                    values_[j*self.n_ + i] = value
                }
            }
        }
    }
    
    public func unsafe_get(_ index: Int) -> Double {
        if let value = values_[index] {
            return value
        }
        return 0.0
    }
    
    public func unsafe_get(_ row: Int, _ column: Int) -> Double {
        if let value = values_[column*self.n_ + row] {
            return value
        }
        return 0.0
    }
    
    public mutating func unsafe_set(_ index: Int, _ value: Double) {
        if value != 0.0 {
            values_[index] = value
        }
    }
    
    public mutating func unsafe_set(_ row: Int, _ column: Int, _ value: Double) {
        if value != 0.0 {
            values_[column*self.n_ + row] = value
        }
    }
    
    /**
     Return a column-major iterator for the matrix.
     - returns: a column-major iterator for the matrix
     */
    public func makeIterator() -> VIter<SparseMatrix> {
        return VIter(v: self)
    }
    
    public mutating func buildSparse() -> SparseMatrix_Double {
        let indices = values_.keys.sorted(by: <)
        
        orderedValues_ = indices.map({self.values_[$0]!})
        rowIndices_ = [Int32]()
        columnStarts_ = [Int]()
        
        var lastCol = -1
        for idx in indices {
            let row = idx % n_
            let col = idx / n_
            
            rowIndices_!.append(Int32(row))
            
            if lastCol != col {
                columnStarts_!.append(idx)
                lastCol = col
            }
        }
        columnStarts_!.append(count)
        
        let structure = SparseMatrixStructure(rowCount: Int32(n_), columnCount: Int32(m_),
                                              columnStarts: &columnStarts_!, rowIndices: &rowIndices_!,
                                              attributes: SparseAttributes_t(), blockSize: 1)
        return SparseMatrix_Double(structure: structure, data: &orderedValues_!)
    }
}

