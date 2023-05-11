## \defgroup dot Symmetric Inner Product
##
## The symmetric inner product takes two arguments and contracts the lower
## graded element to the greater graded element. If lower graded element
## spans an index that is not contained in the higher graded element, the
## result is annihilated. Otherwise, the result is the part of the higher
## graded element "most unlike" the lower graded element. Thus, the
## symmetric inner product can be thought of as a bidirectional contraction
## operator.
##
## There is some merit in providing both a left and right contraction
## operator for explicitness. However, when using Klein, it's generally
## clear what the interpretation of the symmetric inner product is with
## respect to the projection on various entities.
##
## !!! example "Angle between planes"
##
##     ```nim
##         let a = newPlane(x1, y1, z1, d1)
##         let b = newPlane(x2, y2, z2, d2)
##
##         # Compute the cos of the angle between two planes
##         let cos_ang: float = a | b
##     ```
##
## !!! example "Line to plane through point"
##
##     ```nim
##         let a = newPoint(x1, y1, z1)
##         let b = newPlane(x2, y2, z2, d2)
##
##         # The line l contains a and the shortest path from a to plane b.
##         let l: Line = a | b
##     ```

import ./types
import ../backend/ops
import ../backend/laser
import ../backend/inner_product

# Self-self
func `|`*(a, b: Plane): float32 {.inline.} =
  var tmp: m128
  dot00(a.p0, b.p0, tmp)
  mm_store_ss(result.addr, tmp)

func `|`*(a, b: Line): float32 {.inline.} =
  var tmp: m128
  dot11(a.p1, b.p1, tmp)
  mm_store_ss(result.addr, tmp)

func `|`*(a, b: Point): float32 {.inline.} =
  var tmp: m128
  dot33(a.p3, b.p3, tmp)
  mm_store_ss(result.addr, tmp)


func `|`*(a: Plane, b: Line): Plane {.inline.} =
  dotPL(a.p0, b.p1, b.p2, result.p0, FLIP=false)
func `|`*(b: Line, a: Plane): Plane {.inline.} =
  dotPL(a.p0, b.p1, b.p2, result.p0, FLIP=true)

func `|`*(a: Plane, b: IdealLine): Plane {.inline.} =
  dotPIL(a.p0, b.p2, result.p0, FLIP=false)
func `|`*(b: IdealLine, a: Plane): Plane {.inline.} =
  dotPIL(a.p0, b.p2, result.p0, FLIP=true)

func `|`*(a: Plane, b: Point): Line {.inline.} =
  dot03(a.p0, b.p3, result.p1, result.p2)
func `|`*(b: Point, a: Plane): Line {.inline.} =
  a|b


func `|`*(a: Point, b: Line): Plane {.inline.} =
  dotPTL(a.p3, b.p1, result.p0)
func `|`*(b: Line, a: Point): Plane {.inline.} =
  a|b


