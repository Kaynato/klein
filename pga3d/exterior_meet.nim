## \defgroup ext Exterior Product (and Meet)
##
## The exterior product between two basis elements extinguishes if the two
## operands share any common index. Otherwise, the element produced is
## equivalent to the union of the subspaces. A sign flip is introduced if
## the concatenation of the element indices is an odd permutation of the
## cyclic basis representation. The exterior product extends to general
## multivectors by linearity.
##
## !!! example "Meeting two planes"
##
##     ```nim
##         let p1 = newPlane(x1, y1, z1, d1)
##         let p2 = newPlane(x2, y2, z2, d2)
##
##         # l lies at the intersection of p1 and p2.
##         let l: Line = p1 ^ p2
##     ```
##
## !!! example "Meeting a line and a plane"
##
##     ```nim
##         let p1 = newPlane(x, y, z, d)
##         let l2 = newLine(mx, my, mz, dx, dy, dz)
##
##         # p2 lies at the intersection of p1 and l2.
##         let p2: Point = p1 ^ l2
##     ```

import ./types
import ./access
import ../backend/[exterior, laser, symoperator, ops]

# Plane-Plane
func `^`*(a, b: Plane): Line {.inline.} =
  ext00(a.p0, b.p0, result.p1, result.p2)

# Plane-Branch
func `^`*(a: Plane, b: Branch): Point {.inline.} =
  extPB(a.p0, b.p1, result.p3)
func `^`*(b: Branch, a: Plane): Point {.inline.} = a ^ b

# Plane-IdealLine
func `^`*(a: Plane, b: IdealLine): Point {.inline.} =
  ext02(a.p0, b.p2, result.p3)
func `^`*(b: IdealLine, a: Plane): Point {.inline.} = a ^ b

# Plane-Line
func `^`*(a: Plane, b: Line): Point {.inline.} =
  extPB(a.p0, b.p1, result.p3)
  var tmp: m128
  ext02(a.p0, b.p2, tmp)
  result.p3 = result.p3 + tmp
func `^`*(b: Line, a: Plane): Point {.inline.} = a ^ b


# Plane-Point
func `^`*(a: Plane, b: Point): Dual {.inline.} =
  var tmp: m128
  ext03(a.p0, b.p3, tmp, FLIP=false)
  result.p = 0'f32
  mm_store_ss(result.q.addr, tmp)
func `^`*(b: Point, a: Plane): Dual {.inline.} =
  var tmp: m128
  ext03(a.p0, b.p3, tmp, FLIP=true)
  result.p = 0'f32
  mm_store_ss(result.q.addr, tmp)


# Branch-IdealLine
func `^`*(a: Branch, b: IdealLine): Dual {.inline.} =
  result.q = 0'f32
  mm_store_ss(result.p.addr, hi_dp_ss(a.p1, b.p2))
func `^`*(b: IdealLine, a: Branch): Dual {.inline.} = a ^ b

# Line-IdealLine
func `^`*(a: Line, b: IdealLine): Dual {.inline.} =
  Branch(p1: a.p1) ^ b
func `^`*(b: IdealLine, a: Line): Dual {.inline.} = a ^ b

# Line-Branch
func `^`*(a: Line, b: Branch): Dual {.inline.} =
  IdealLine(p2: a.p2) ^ b
func `^`*(b: Branch, a: Line): Dual {.inline.} = a ^ b

# Line-Line
func `^`*(a, b: Line): Dual {.inline.} =
  result.p = 0'f32
  result.q = hi_dp_ss(a.p1, b.p2).store0() +
             hi_dp_ss(b.p1, a.p2).store0()
  

# Semantic Alias
template meet*(a, b: Plane|SomeLine|Point): auto =
  a ^ b

