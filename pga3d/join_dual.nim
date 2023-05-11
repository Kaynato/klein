## Regressive Product
##
## The regressive product is implemented in terms of the exterior product.
## Given multivectors $\mathbf{a}$ and $\mathbf{b}$, the regressive product
## $\mathbf{a}\vee\mathbf{b}$ is equivalent to
## $J(J(\mathbf{a})\wedge J(\mathbf{b}))$. Thus, both meets and joins
## reside in the same algebraic structure.
##
## !!! example "Joining two points"
##
##     ```nim
##         let p1 = newPoint(x1, y1, z1)
##         let p2 = newPoint(x2, y2, z2)
##
##         # l contains both p1 and p2.
##         let l = p1 & p2
##     ```
##
## !!! example "Joining a line and a point"
##
##     ```nim
##         let p1 = newPoint(x, y, z)
##         let l2 = newLine(mx, my, mz, dx, dy, dz)
##
##         # p2 contains both p1 and l2.
##         let p2 = p1 & l2
##     ```
##
## Poincaré Dual
##
## The Poincaré Dual of an element is the "subspace complement" of the
## argument with respect to the pseudoscalar in the exterior algebra. In
## practice, it is a relabeling of the coordinates to their
## dual-coordinates and is used most often to implement a "join" operation
## in terms of the exterior product of the duals of each operand.
##
## Ex: The dual of the point $\mathbf{e}_{123} + 3\mathbf{e}_{013} -
## 2\mathbf{e}_{021}$ (the point at
## $(0, 3, -2)$) is the plane
## $\mathbf{e}_0 + 3\mathbf{e}_2 - 2\mathbf{e}_3$.
## 
## WARNING: These duals use the J Map, not the Hodge complement.

import ./types
import ./exterior_meet
import ../backend/symoperator

###############
# Duals first #
###############

# Dual Types
func `!`*(a: typedesc[Plane]): typedesc[Point] {.compileTime.} = Point
func `!`*(a: typedesc[Point]): typedesc[Plane] {.compileTime.} = Plane
func `!`*(a: typedesc[Line]): typedesc[Line] {.compileTime.} = Line
func `!`*(a: typedesc[IdealLine]): typedesc[Branch] {.compileTime.} = Branch
func `!`*(a: typedesc[Branch]): typedesc[IdealLine] {.compileTime.} = IdealLine
func `!`*(a: typedesc[Dual]): typedesc[Dual] {.compileTime.} = Dual

func `!`*(a: Plane): Point {.inline.} = Point(p3: a.p0)
func `!`*(a: Point): Plane {.inline.} = Plane(p0: a.p3)
func `!`*(a: Line): Line {.inline.} = Line(p1: a.p2, p2: a.p1)
func `!`*(a: IdealLine): Branch {.inline.} = Branch(p1: a.p2)
func `!`*(a: Branch): IdealLine {.inline.} = IdealLine(p2: a.p1)
func `!`*(a: Dual): Dual {.inline.} = Dual(p: a.q, q: a.p)

# Semantic alias
template dual*[T: Plane|Point|Line|IdealLine|Branch|Dual](a: typedesc[T]): untyped = !a
template dual*[T: Plane|Point|Line|IdealLine|Branch|Dual](a: T): T.dual = !a

#########
# Joins #
#########

func `&`*(a, b: Point): Line {.inline.} = !(!a ^ !b)
func `&`*(a: Point, b: SomeLine): Plane {.inline.} = !(!a ^ !b)
func `&`*(b: SomeLine, a: Point): Plane {.inline.} = !(!a ^ !b)
func `&`*(a: Plane, b: Point): Dual {.inline.} = !(!a ^ !b)
func `&`*(b: Point, a: Plane): Dual {.inline.} = !(!a ^ !b)

# Semantic alias
template join*(a, b: Point|SomeLine|Plane): auto = a & b

###############
# Hodge Duals #
###############

# I think this is the only place where it matters
func hodgeDual*(a: Plane): Point {.inline.} = Point(p3: -a.p0)