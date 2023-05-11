## \defgroup gp Geometric Product
##
## The geometric product extends the exterior product with a notion of a
## metric. When the subspace intersection of the operands of two basis
## elements is non-zero, instead of the product extinguishing, the grade
## collapses and a scalar weight is included in the final result according
## to the metric. The geometric product can be used to build rotations, and
## by extension, rotations and translations in projective space.
##
## !!! example "Rotor composition"
##
##     ```nim
##         let r1 = newRotor(ang1, x1, y1, z1)
##         let r2 = newRotor(ang2, x2, y2, z2)
##
##         # Compose rotors with the geometric product
##         let r3 = r1 * r2 # r3 combines r2 and r1 in that order
##     ```
##
## !!! example "Two reflections"
##
##     ```nim
##         let p1 = newPlane(x1, y1, z1, d1)
##         let p2 = newPlane(x2, y2, z2, d2)
##
##         # The geometric product of two planes combines their reflections
##         let m3 = p1 * p2 # m3 combines p2 and p1 in that order
##         # If p1 and p2 were parallel, m3 would be a translation. Otherwise,
##         # m3 would be a rotation.
##     ```
##
## Another common usage of the geometric product is to create a transformation
## that takes one entity to another. Suppose we have two entities $a$ and $b$
## and suppose that both entities are normalized such that $a^2 = b^2 = 1$.
## Then, the action created by $\sqrt{ab}$ is the action that maps $b$ to $a$.
##
## !!! example "Motor between two lines"
##
##     ```nim
##         let l1 = newLine(mx1, my1, mz1, dx1, dy1, dz1)
##         let l2 = newLine(mx2, my2, mz2, dx2, dy2, dz2)
##         # Ensure lines are normalized if they aren't already
##         l1.normalize()
##         l2.normalize()
##         let m = sqrt(l1 * l2)
##         let l3 = l2.move()
##         # l3 will be projectively equivalent to l1.
##     ```
##
## Also provided are division operators that multiply the first argument by the
## inverse of the second argument.
## \addtogroup gp
## @{


import ./types
import ./arithmetic
import ./plane
import ./point
import ./slider
import ./rotor
import ./motor
import ../backend/[laser, ops, geometric_product, symoperator]

# Plane
func `*`*(a, b: Plane): Motor {.inline.} =
  gp00(a.p0, b.p0, result.p1, result.p2)

func `*`*(a: Plane, b: Point): Motor {.inline.} =
  gp03(a.p0, b.p3, result.p1, result.p2, FLIP=false)

func `*`*(b: Point, a: Plane): Motor {.inline.} =
  gp03(a.p0, b.p3, result.p1, result.p2, FLIP=true)


# Self-Self types
func `*`*(a, b: Branch): Rotor {.inline.} =
  gp11(a.p1, b.p1, result.p1)

func `*`*(a, b: Line): Motor {.inline.} =
  ## Generates a motor $m$ that produces a screw motion about the common normal
  ## to lines $a$ and $b$. The motor given by $\sqrt{m}$ takes $b$ to $a$
  ## provided that $a$ and $b$ are both normalized.
  gpLL(a.p1, a.p2, b.p1, b.p2, result.p1, result.p2)

func `*`*(a, b: Point): Slider {.inline.} =
  ## Generates a translator $t$ that produces a displacement along the line
  ## between points $a$ and $b$. The translator given by $\sqrt{t}$ takes $b$ to
  ## $a$.
  gp33(a.p3, b.p3, result.p2)

func `*`*(a, b: Rotor): Rotor {.inline.} =
  ## Composes two rotational actions such that the produced rotor has the same
  ## effect as applying rotor $b$, then rotor $a$.
  gp11(a.p1,  b.p1, result.p1)

func `*`*(a: Dual, b: Line): Line {.inline.} =
  ## The product of a dual number and a line effectively weights the line with a
  ## rotational and translational quantity. Subsequent exponentiation will
  ## produce a motor along the screw axis of line $b$ with rotation and
  ## translation given by half the scalar and pseudoscalar parts of the dual
  ## number $a$ respectively.
  gpDL(a.p, a.q, b.p1, b.p2, result.p1, result.p2)

template `*`*(b: Line, a: Dual): Line = a * b


# Rotor-Slider
func `*`*(a: Rotor, b: Slider): Motor {.inline.} =
  result.p1 = a.p1
  gpRT(a.p1, b.p2, result.p2, FLIP=false)

func `*`*(b: Slider, a: Rotor): Motor {.inline.} =
  result.p1 = a.p1
  gpRT(a.p1, b.p2, result.p2, FLIP=true)

func `*`*(a, b: Slider): Slider {.inline.} =
  a + b

# Rotor/Slider - Motor
func `*`*(a: Rotor, b: Motor): Motor {.inline.} =
  gp11(a.p1, b.p1, result.p1)
  gp12(a.p1, b.p2, result.p2, FLIP=false)

func `*`*(b: Motor, a: Rotor): Motor {.inline.} =
  gp11(b.p1, a.p1, result.p1)
  gp12(a.p1, b.p2, result.p2, FLIP=true)

func `*`*(a: Slider, b: Motor): Motor {.inline.} =
  result.p1 = b.p1
  gpRT(b.p1, a.p2, result.p2, FLIP=true)
  result.p2 = result.p2 + b.p2

func `*`*(b: Motor, a: Slider): Motor {.inline.} =
  result.p1 = b.p1
  gpRT(b.p1, a.p2, result.p2, FLIP=false)
  result.p2 = result.p2 + b.p2

func `*`*(a, b: Motor): Motor {.inline.} =
  gpMM(a.p1, a.p2, b.p1, b.p2, result.p1, result.p2)


## Division

func `/`*[T: Plane|Point|Branch|Rotor|Slider|Line|Motor](a, b: T): auto {.inline.} =
  ## Construct an object $m$ such that $\sqrt{m}$ takes $b$ to $a$.
  ##
  ## example:
  ##     ```nim
  ##         let p1 = newPlane(x1, y1, z1, d1)
  ##         let p2 = newPlane(x2, y2, z2, d2)
  ##         let m = sqrt(p2/p1)
  ##         let p3: Plane = p2.move(m)
  ##         # p3 will be approximately equal to p1
  ##     ```
  a * inverse(b)

func `/`*[T: Rotor|Slider|Motor](a: Motor, b: T): Motor {.inline.} =
  a * inverse(b)
