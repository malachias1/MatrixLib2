# MatrixLib2
A Vector and Matrix Framework that offers a friendly alternative to Accelerate

The Vector and Matrix Framework offers a friendly alternative
to Accelerate in cases where accelerate is cumbersome or when
one exceeds simd's limitations. For what it's worth it illustrates
a variety of interesting points for someone new to swift, but skilled
in java, python, or other OO languages.

- Use of extensions to default various methods without undo loss ot
performance
- Use of operator overloading and subscripting while minimizing code
duplication
- Use of unsafe pointers in a manner that is safe and performance
enhancing
- techniques for building Accelerate Dense and Sparse Matrices

Ease of constructing and accessing matrix contents is central to the
implementation, an area in which Accelerate is dreadful (apart from simd,
which was too small for my needs).  Much of the performance penalty
one encounters is the result of constructing matrices. I suspect that
one will lose most of the performance advantages one might hope to
gain from Accelerate if one's matrices are relatively small, dense,
and frequently constructed.

## Error Handling

There are plenty of opportunities for errors when it comes to indexing
vectors and matrices.  Error handling offers two approaches.  The first
catches the error, continues in a manner that will not cause a fault,
and logs the error. The second approach does not catch the error and
errors likely result in a fault.  Internally, these unsafe access methods
are used when indices are known to be valid.

These two approaches seem to offer the right balance of safety,
performance, simplicity (i.e., preferrable to propogating
errors or returning optional values), and consistancy (i.e.,
one can't throw from a subscript).

## Memory Allocation

None of the methods below explicitly allocate memory.
Unsafe buffer pointers are obtained from swift Arrays,
not allocated.

## Performance Notes

Four performance tests were run to obtain some sense of
how well the library performed.  All the tests were performed
on a Matrix (i.e., I don't have performance numbers for Vectors)
- Using the simulator, it takes 100-200ms to invert 1000 randomly
valued 10x10 matricies, including matrix creation. This runtime seems
a little slow to me, but it is adequate for the application I
have in mind.  The same test, takes about 600-700ms on an iPhone 6
- 100,000 unsafe_get followed by unsafe_set takes about 20-30ms
- 100,000 equivalent subscript operations take about 70-80ms, which are
checked and fail silently; so, expect a significant slowdown when
using subscripts.
- 1000 matrix multiplies of two randomly valued 10x10 matrices takes
about 20ms using the simulator

Where computationally intensive operations are performed
and indices are known to be good, I use
withUnsafeBufferPointer and withUnsafeMutableBufferPointer.

The [LU Decomposition](https:en.wikipedia.org/wiki/LU_decomposition) code was ported from C code founded in wikipedia

Static versions of LU methods are implementated to allow
the LU Decomposition to be reused if beneficial. Reuse
of decompositions when possible can yield enormous performance
increases.




