//
//  MatrixTests.swift
//  TrainerTests
//
//  Created by John Morris on 10/4/18.
//  Copyright © 2018 John Morris. All rights reserved.
//

import XCTest
@testable import MatrixLib
import Accelerate

class VectorTests: XCTestCase {
    func testInit() {
        let v = Vector(count: 10)
        
        XCTAssertEqual(10, v.count)
        
        for i in 0..<v.count {
            XCTAssertEqual(0.0, v[i], accuracy: 0.0000001)
        }
    }
    
    func testInitWithArray() {
        let v = Vector(values: [0.0, 1.0, 2.0])
        
        XCTAssertEqual(3, v.count)
        
        for i in 0..<v.count {
            XCTAssertEqual(Double(i), v[i], accuracy: 0.0000001)
        }
    }
    
    func testInitWithVariadic() {
        let v = Vector(values: 0.0, 1.0, 2.0)
        
        XCTAssertEqual(3, v.count)
        
        for i in 0..<v.count {
            XCTAssertEqual(Double(i), v[i], accuracy: 0.0000001)
        }
    }
    
    func testSubscript() {
        var v = Vector(values: 0.0, 1.0, 2.0)
        
        v[1] = 6.0
        
        XCTAssertEqual(6.0, v[1], accuracy: 0.0000001)
    }
    
    func testAssign() {
        let v = Vector(values: 0.0, 1.0, 2.0)
        var u = v
        
        u[1] = 6.0
        
        XCTAssertEqual(1.0, v[1], accuracy: 0.0000001)
    }
    
    func testDescription() {
        let v = Vector(values: 0.0, 1.0, 2.0)
        
        XCTAssertEqual("[0.0, 1.0, 2.0]", v.description)
    }
    
    func testAddScalar() {
        let v = Vector(values: 0.0, 1.0, 2.0)
        let u = v + 1.0
        XCTAssertEqual("[1.0, 2.0, 3.0]", u.description)
    }
    
    func testMinusScalar() {
        let v = Vector(values: 0.0, 1.0, 2.0)
        let u = v - 1.0
        XCTAssertEqual("[-1.0, 0.0, 1.0]", u.description)
    }
    
    func testMultScalar() {
        let v = Vector(values: 0.0, 1.0, 2.0)
        let u = v * 2.0
        XCTAssertEqual("[0.0, 2.0, 4.0]", u.description)
    }
    
    func testDivScalar() {
        let v = Vector(values: 0.0, 1.0, 2.0)
        let u = v / 0.5
        XCTAssertEqual("[0.0, 2.0, 4.0]", u.description)
    }
    
    func testAddVector() {
        let v = Vector(values: 0.0, 1.0, 2.0)
        let u = v + v
        XCTAssertEqual("[0.0, 2.0, 4.0]", u.description)
    }
    
    func testMinusVector() {
        let v = Vector(values: 0.0, 1.0, 2.0)
        let u = v - v
        XCTAssertEqual("[0.0, 0.0, 0.0]", u.description)
    }
    
    func testMultVector() {
        let v = Vector(values: 0.0, 1.0, 2.0)
        let u = v * v
        XCTAssertEqual("[0.0, 1.0, 4.0]", u.description)
    }
    
    func testDivVector() {
        let v = Vector(values: 0.0, 1.0, 2.0)
        let u = v / v
        XCTAssertEqual("[nan, 1.0, 1.0]", u.description)
    }
}

class MatrixTests: XCTestCase {
    func testInit() {
        let m = Matrix(n: 2, m: 3)
        let shape = m.shape
        XCTAssertEqual(2, shape.n)
        XCTAssertEqual(3, shape.m)
        
        for i in 0..<m.shape.n {
            for j in 0..<m.shape.m {
                XCTAssertEqual(0.0, m[i, j], accuracy: 0.0000001)
            }
        }
    }
    
    func testInitWithInitialValue() {
        let m = Matrix(n: 2, m: 3, initialValue: 20.0)
        
        for i in 0..<m.shape.n {
            for j in 0..<m.shape.m {
                XCTAssertEqual(20.0, m[i, j], accuracy: 0.0000001)
            }
        }
    }
    
    func testIdentity() {
        let mat = Matrix.identity(n: 3)
        
        for i in 0..<mat.n {
            for j in 0..<mat.m {
                XCTAssertEqual(i != j ? 0.0 : 1.0, mat[i, j], accuracy: 0.0000001)
            }
        }
    }
    
    func testColumnMatrix() {
        let v = Matrix(m: 10, initialValue: 20.0)
        let shape = v.shape
        XCTAssertEqual(1, shape.n)
        XCTAssertEqual(10, shape.m)
        
        for i in 0..<shape.n {
            for j in 0..<shape.m {
                XCTAssertEqual(20.0, v[i, j], accuracy: 0.0000001)
            }
        }
    }
    
    func testRowMatrix() {
        let v = Matrix(n: 10, initialValue: 20.0)
        let shape = v.shape
        XCTAssertEqual(10, shape.n)
        XCTAssertEqual(1, shape.m)
        
        for i in 0..<shape.n {
            for j in 0..<shape.m {
                XCTAssertEqual(20.0, v[i, j], accuracy: 0.0000001)
            }
        }
    }
    
    func testGetValuesForRow() {
        var mat = Matrix(n: 10, m: 5)
        for i in 0..<mat.n {
            for j in 0..<mat.m {
                mat[i, j] = Double(j)
            }
        }
        
        for i in 0..<mat.n {
            let row = mat.getValues(forRow: i)
            for j in 0..<mat.m {
                XCTAssertEqual(Double(j), row[j], accuracy: 0.0000001)
            }
        }
    }
    
    func testGetValuesForColumn() {
        var mat = Matrix(n: 10, m: 5)
        for i in 0..<mat.n {
            for j in 0..<mat.m {
                mat[i, j] = Double(j)
            }
        }
        
        for j in 0..<mat.m {
            let column = mat.getValues(forColumn: j)
            for i in 0..<mat.n {
                XCTAssertEqual(Double(j), column[i], accuracy: 0.0000001)
            }
        }
    }
    
    func testSetValueForRow() {
        var mat = Matrix(n: 3, m: 4)
        mat.set(value: 5.0, forRow: 2)
        for i in 0..<mat.n {
            for j in 0..<mat.m {
                if i == 2 {
                    XCTAssertEqual(5.0, mat[i, j], accuracy: 0.0000001)
                } else {
                    XCTAssertEqual(0.0, mat[i, j], accuracy: 0.0000001)
                }
            }
        }
    }
    
    func testSetValuesForRowVariadic() {
        var mat = Matrix(n: 3, m: 4)
        mat.set(values: 5.0, 5.0, 5.0, 5.0, forRow: 2)
        for i in 0..<mat.n {
            for j in 0..<mat.m {
                if i == 2 {
                    XCTAssertEqual(5.0, mat[i, j], accuracy: 0.0000001)
                } else {
                    XCTAssertEqual(0.0, mat[i, j], accuracy: 0.0000001)
                }
            }
        }
    }
    
    func testSetValuesForRowArray() {
        var mat = Matrix(n: 3, m: 4)
        mat.set(values: [5.0, 5.0, 5.0, 5.0], forRow: 2)
        for i in 0..<mat.n {
            for j in 0..<mat.m {
                if i == 2 {
                    XCTAssertEqual(5.0, mat[i, j], accuracy: 0.0000001)
                } else {
                    XCTAssertEqual(0.0, mat[i, j], accuracy: 0.0000001)
                }
            }
        }
    }
    
    func testSetValuesForRowV() {
        var mat = Matrix(n: 3, m: 4)
        mat.set(values: Vector(count: 4, initialValue: 5.0), forRow: 2)
        for i in 0..<mat.n {
            for j in 0..<mat.m {
                if i == 2 {
                    XCTAssertEqual(5.0, mat[i, j], accuracy: 0.0000001)
                } else {
                    XCTAssertEqual(0.0, mat[i, j], accuracy: 0.0000001)
                }
            }
        }
    }
    
    func testSetValuesForRowM() {
        var mat = Matrix(n: 3, m: 4)
        mat.set(values: Matrix(n: 4, initialValue: 5.0), forRow: 2)
        for i in 0..<mat.n {
            for j in 0..<mat.m {
                if i == 2 {
                    XCTAssertEqual(5.0, mat[i, j], accuracy: 0.0000001)
                } else {
                    XCTAssertEqual(0.0, mat[i, j], accuracy: 0.0000001)
                }
            }
        }
    }
    
    func testSetValueForColumn() {
        var mat = Matrix(n: 3, m: 4)
        mat.set(value: 5.0, forColumn: 2)
        for i in 0..<mat.n {
            for j in 0..<mat.m {
                if j == 2 {
                    XCTAssertEqual(5.0, mat[i, j], accuracy: 0.0000001)
                } else {
                    XCTAssertEqual(0.0, mat[i, j], accuracy: 0.0000001)
                }
            }
        }
    }
    
    func testSetValuesForColumnVariadic() {
        var mat = Matrix(n: 3, m: 4)
        mat.set(values: 5.0, 5.0, 5.0, forColumn: 2)
        for i in 0..<mat.n {
            for j in 0..<mat.m {
                if j == 2 {
                    XCTAssertEqual(5.0, mat[i, j], accuracy: 0.0000001)
                } else {
                    XCTAssertEqual(0.0, mat[i, j], accuracy: 0.0000001)
                }
            }
        }
    }
    
    func testSetValuesForColumnArray() {
        var mat = Matrix(n: 3, m: 4)
        mat.set(values: [5.0, 5.0, 5.0], forColumn: 2)
        for i in 0..<mat.n {
            for j in 0..<mat.m {
                if j == 2 {
                    XCTAssertEqual(5.0, mat[i, j], accuracy: 0.0000001)
                } else {
                    XCTAssertEqual(0.0, mat[i, j], accuracy: 0.0000001)
                }
            }
        }
    }
    
    func testSetValuesForColumnV() {
        var mat = Matrix(n: 3, m: 4)
        mat.set(values: Vector(count: 3, initialValue: 5.0), forColumn: 2)
        for i in 0..<mat.n {
            for j in 0..<mat.m {
                if j == 2 {
                    XCTAssertEqual(5.0, mat[i, j], accuracy: 0.0000001)
                } else {
                    XCTAssertEqual(0.0, mat[i, j], accuracy: 0.0000001)
                }
            }
        }
    }
    
    func testSetValuesForColumnM() {
        var mat = Matrix(n: 3, m: 4)
        mat.set(values: Matrix(n: 3, initialValue: 5.0), forColumn: 2)
        for i in 0..<mat.n {
            for j in 0..<mat.m {
                if j == 2 {
                    XCTAssertEqual(5.0, mat[i, j], accuracy: 0.0000001)
                } else {
                    XCTAssertEqual(0.0, mat[i, j], accuracy: 0.0000001)
                }
            }
        }
    }
    
    func testSubsriptSet() {
        var m = Matrix(n: 2, m: 3)
        
        for i in 0..<m.shape.n {
            for j in 0..<m.shape.m {
                m[i,j] = Double(i*j)
            }
        }
        
        for i in 0..<m.shape.n {
            for j in 0..<m.shape.m {
                XCTAssertEqual(Double(i*j), m[i, j], accuracy: 0.0000001)
            }
        }
    }
    
    func testSequence() {
        var m = Matrix(n: 2, m: 3)
        
        for i in 0..<m.shape.n {
            for j in 0..<m.shape.m {
                m[i,j] = Double(i*j)
            }
        }
        
        m[1,1] = 20.0
        XCTAssertEqual(20.0, m.max() ?? 0.0, accuracy: 0.0000001)
    }
    
    func testPlus() {
        let x = Matrix(n: 2, m: 3)
        let y = x + 1
        let shape = x.shape
        
        for i in 0..<shape.n {
            for j in 0..<shape.m {
                XCTAssertEqual(0.0, x[i, j], accuracy: 0.0000001)
                XCTAssertEqual(1.0, y[i, j], accuracy: 0.0000001)
            }
        }
        
    }
    
    func testPlusMatix() {
        let x = Matrix(n: 2, m: 3)
        let y = x + Matrix(n: 2, m: 3, initialValue: 6.0)
        let shape = x.shape
        
        for i in 0..<shape.n {
            for j in 0..<shape.m {
                XCTAssertEqual(0.0, x[i, j], accuracy: 0.0000001)
                XCTAssertEqual(6.0, y[i, j], accuracy: 0.0000001)
            }
        }
        
    }
    
    func testMinus() {
        let x = Matrix(n: 2, m: 3)
        let y = x - 1
        let shape = x.shape
        
        for i in 0..<shape.n {
            for j in 0..<shape.m {
                XCTAssertEqual(0.0, x[i, j], accuracy: 0.0000001)
                XCTAssertEqual(-1.0, y[i, j], accuracy: 0.0000001)
            }
        }
        
    }
    
    func testMinusMatix() {
        let x = Matrix(n: 2, m: 3)
        let y = x - Matrix(n: 2, m: 3, initialValue: 6.0)
        let shape = x.shape
        
        for i in 0..<shape.n {
            for j in 0..<shape.m {
                XCTAssertEqual(0.0, x[i, j], accuracy: 0.0000001)
                XCTAssertEqual(-6.0, y[i, j], accuracy: 0.0000001)
            }
        }
    }
    
    func testUnaryMinus() {
        let x = -Matrix(n: 2, m: 3, initialValue: 6.0)
        let shape = x.shape
        
        for i in 0..<shape.n {
            for j in 0..<shape.m {
                XCTAssertEqual(-6.0, x[i, j], accuracy: 0.0000001)
            }
        }
    }
    
    func testElementwiseMult() {
        let x = Matrix(n: 2, m: 3, initialValue: 6.0) * Matrix(n: 2, m: 3, initialValue: 2.0)
        let shape = x.shape
        
        for i in 0..<shape.n {
            for j in 0..<shape.m {
                XCTAssertEqual(12.0, x[i, j], accuracy: 0.0000001)
            }
        }
    }
    
    func testMult() {
        let x = Matrix(n: 2, m: 3, initialValue: 6.0) ** Matrix(n: 3, m: 1, initialValue: 2.0)
        let shape = x.shape
        
        XCTAssertEqual(2, shape.n)
        XCTAssertEqual(1, shape.m)
        
        for i in 0..<shape.n {
            for j in 0..<shape.m {
                XCTAssertEqual(36.0, x[i, j], accuracy: 0.0000001)
            }
        }
    }
    
    func testTranspose() {
        var x = Matrix(n: 2, m: 3)
        
        for i in 0..<x.n {
            x[i, 0] = 1.0
        }
        
        let y = x.T
        let shape = y.shape
        
        XCTAssertEqual(3, shape.n)
        XCTAssertEqual(2, shape.m)
        
        for i in 0..<shape.n {
            for j in 0..<shape.m {
                if i == 0 {
                    XCTAssertEqual(1.0, y[i, j], accuracy: 0.0000001)
                } else {
                    XCTAssertEqual(0.0, y[i, j], accuracy: 0.0000001)
                }
            }
        }
    }
    
    func testDescription() {
        var x = Matrix(n: 5, m: 3)
        
        for i in 0..<x.n {
            for j in 0..<x.m {
                x[i,j] = Double((i+1)*j)
            }
        }
        
        print(x)
    }
    
    func testSwapRows() {
        var x = Matrix(n: 5, m: 3)
        
        for i in 0..<x.n {
            for j in 0..<x.m {
                x[i,j] = Double((i+1)*j)
            }
        }
        
        var y = x
        
        y.swapRows(row1: 0, row2: 1)
        for j in 0..<x.m {
            XCTAssertEqual(y[0, j], x[1, j])
        }
        
        for j in 0..<x.m {
            XCTAssertEqual(y[1, j], x[0, j])
        }
    }
    
    func testInvert() {
        var x = Matrix(n: 3, m: 3)
        
        x.set(values: 2.0, -1.0, 0.0, forRow: 0)
        x.set(values: -1.0, 2.0, -1.0, forRow: 1)
        x.set(values: 0.0, -1.0, 2.0, forRow: 2)
        
        if let y = x.I {
            XCTAssertEqual(0.75, y[0,0], accuracy: 0.000001)
            XCTAssertEqual(0.5, y[0,1], accuracy: 0.000001)
            XCTAssertEqual(0.25, y[0,2], accuracy: 0.000001)
            XCTAssertEqual(0.5, y[1,0], accuracy: 0.000001)
            XCTAssertEqual(1.0, y[1,1], accuracy: 0.000001)
            XCTAssertEqual(0.5, y[1,2], accuracy: 0.000001)
            XCTAssertEqual(0.25, y[2,0], accuracy: 0.000001)
            XCTAssertEqual(0.5, y[2,1], accuracy: 0.000001)
            XCTAssertEqual(0.75, y[2,2], accuracy: 0.000001)
        } else {
            XCTFail()
        }
    }
    
    func testLUPDecomposition() {
        let x = Matrix(values: [[2.0, 7.0, 6.0],
                                [9.0, 5.0, 1.0],
                                [4.0, 3.0, 8.0]])
        
        if let (A, P) = x.LUPDecompose() {
            print(A)
            print(P)
            XCTAssertEqual(9.0, A[0,0], accuracy: 0.001)
            XCTAssertEqual(5.0, A[0,1], accuracy: 0.001)
            XCTAssertEqual(1.0, A[0,2], accuracy: 0.001)
            XCTAssertEqual(0.2222, A[1,0], accuracy: 0.001)
            XCTAssertEqual(5.8889, A[1,1], accuracy: 0.001)
            XCTAssertEqual(5.7778, A[1,2], accuracy: 0.001)
            XCTAssertEqual(0.4444,A[2,0], accuracy: 0.001)
            XCTAssertEqual(0.1321, A[2,1], accuracy: 0.001)
            XCTAssertEqual(6.7925, A[2,2], accuracy: 0.001)
        } else {
            XCTFail()
        }
        
    }
    
    func testLUPInvert() {
        var x = Matrix(n: 3, m: 3)
        
        x.set(values: 2.0, -1.0, 0.0, forRow: 0)
        x.set(values: -1.0, 2.0, -1.0, forRow: 1)
        x.set(values: 0.0, -1.0, 2.0, forRow: 2)
        
        if let y = x.LUPInvert() {
            XCTAssertEqual(0.75, y[0,0], accuracy: 0.000001)
            XCTAssertEqual(0.5, y[0,1], accuracy: 0.000001)
            XCTAssertEqual(0.25, y[0,2], accuracy: 0.000001)
            XCTAssertEqual(0.5, y[1,0], accuracy: 0.000001)
            XCTAssertEqual(1.0, y[1,1], accuracy: 0.000001)
            XCTAssertEqual(0.5, y[1,2], accuracy: 0.000001)
            XCTAssertEqual(0.25, y[2,0], accuracy: 0.000001)
            XCTAssertEqual(0.5, y[2,1], accuracy: 0.000001)
            XCTAssertEqual(0.75, y[2,2], accuracy: 0.000001)
        } else {
            XCTFail()
        }
    }
    
    func testLUPSolve() {
        let A = Matrix(values: [[10.0, 1.0, 0.0, 2.5],
                                [1.0, 12.0, -0.3, 1.1],
                                [0.0, -0.3, 9.5, 0.0],
                                [2.5, 1.1, 0.0, 6.0]])
        let b = Vector(values: 2.2, 2.85, 2.79, 2.87)
        
        if let x = A.LUPSolve(b: b) {
            XCTAssertEqual(0.10, x[0], accuracy: 0.000001)
            XCTAssertEqual(0.20, x[1], accuracy: 0.000001)
            XCTAssertEqual(0.30, x[2], accuracy: 0.000001)
            XCTAssertEqual(0.40, x[3], accuracy: 0.000001)
        } else {
            XCTFail()
        }
        
    }
    
    func testQ() {
        let dt = 0.06346651825433926
        let dt3 = pow(dt, 3.0)/6
        let dt2 = pow(dt, 2.0)/2
        var q1 = Matrix(n: 6, m: 1)
        var q2 = Matrix(n: 6, m: 1)
        let σ = 32.313599999999994
        q1[0,0] = dt3
        q1[1,0] = dt2
        q1[2,0] = dt
        q1[3,0] = 0.0
        q1[4,0] = 0.0
        q1[5,0] = 0.0
        q2[0,0] = 0.0
        q2[1,0] = 0.0
        q2[2,0] = 0.0
        q2[3,0] = dt3
        q2[4,0] = dt2
        q2[5,0] = dt
        
        let q = (q1 ** (q1.T)) * σ + (q2 ** (q2.T)) * σ
        print(q)
        print("dt3=\(dt3), dt2=\(dt2), dt=\(dt)")
    }
    
    func testSparseMultiply() {
        var A = SparseMatrix(matrix: Matrix(n: 2, m: 3, initialValue: 6.0))
        var x = Matrix(n: 3, m: 1, initialValue: 2.0)
        var y = Matrix(n: 2, m: 1)
        let A_ = A.buildSparse()
        let x_ = x.buildDense()
        let y_ = y.buildDense()
        
        SparseMultiply(A_, x_, y_)
        
        for i in 0..<y.n {
            for j in 0..<y.m {
                XCTAssertEqual(36.0, y[i, j], accuracy: 0.0000001)
            }
        }
    }
    
    /**
     The below test replicates what would need to be
     done to use SparseMultiply in Matrix. It is substantially
     slower than what I have implemented. If, however, one is not
     building matrices all the time it could be somewhat faster.
     */
    func testPerformanceSparseMultiply() {
        let AA = SparseMatrix(matrix: Matrix.random(n: 10, m: 10))
        let xx = Matrix.random(n: 10, m: 10)
        
        self.measure {
            for _ in 0..<1000 {
                var A = SparseMatrix(matrix: AA)
                var x = xx
                let A_ = A.buildSparse()
                let x_ = x.buildDense()
                var y = Matrix(n: 10, m: 10)
                let y_ = y.buildDense()
                SparseMultiply(A_, x_, y_)
            }
        }
    }
    
    func testPerformanceMultiply() {
        let A = Matrix.random(n: 10, m: 10)
        let x = Matrix.random(n: 10, m: 10)
        
        self.measure {
            for _ in 0..<1000 {
                let _ = A**x
            }
        }
    }
    
    func testPerformanceInvert() {
        // This is an example of a performance test case.
        self.measure {
            for _ in 0..<1000 {
                let x = Matrix.random(n: 10, m: 10)
                let _ = x.I
            }
        }
    }
    
    func testPerformanceLUPInvert() {
        // This is an example of a performance test case.
        self.measure {
            for _ in 0..<1000 {
                let x = Matrix.random(n: 10, m: 10)
                let _ = x.LUPInvert()
            }
        }
    }
    
}

