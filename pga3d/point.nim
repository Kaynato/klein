## Points
##
## A point is represented as the multivector
## $x\mathbf{e}_{032} + y\mathbf{e}_{013} + z\mathbf{e}_{021} +
## \mathbf{e}_{123}$. The point has a trivector representation because it is
## the fixed point of 3 planar reflections (each of which is a grade-1
## multivector). In practice, the coordinate mapping can be thought of as an
## implementation detail.
## 
## Directions
## Directions in $\mathbf{P}(\mathbb{R}^3_{3, 0, 1})$ are represented using
## points at infinity (homogeneous coordinate 0). Having a homogeneous
## coordinate of zero ensures that directions are translation-invariant.

import std/math
import ./types
import ../utils
import ../backend/[laser, ops, symoperator]

func newPoint*[T: SomeNumber](x, y, z: T): Point {.autoConvert: float32.} =
  ## Construct a point from coordinates. Homogeneous coordinate automatically 1.
  Point(p3: mm_set_ps(z, y, x, 1'f32))

func normalize*(r: var Point) =
  r.p3 = r.p3.wwww.rcp_nr1() * r.p3

func invert*(r: var Point) =
  let inv_norm = r.p3.wwww.rcp_nr1()
  r.p3 = r.p3 * inv_norm * inv_norm

func inverse*(r: Point): Point =
  result.p3 = r.p3
  result.invert()

func Origin*(_: typedesc[Point]): Point =
  Point(p3: mm_set_ss(1'f32))

# Standards
func X*(_: typedesc[Point]): Point =
  result.p3 = mm_set_ps(0'f32, 0'f32, 1'f32, 1'f32)

func Y*(_: typedesc[Point]): Point =
  result.p3 = mm_set_ps(0'f32, 1'f32, 0'f32, 1'f32)

func Z*(_: typedesc[Point]): Point =
  result.p3 = mm_set_ps(1'f32, 0'f32, 0'f32, 1'f32)

# Direction

func norm*(d: Direction): float32 = 
  mm_store_ss(result.addr, hi_dp_bc(d.p3, d.p3))

func normalize*(d: var Direction) =
  d.p3 = d.p3 * rsqrt_nr1(hi_dp_bc(d.p3, d.p3))

func newDirection*[T: SomeNumber](x, y, z: T): Direction {.autoConvert: float32.} =
  ## Construct a normalized direction.
  ## Directions are points at infinity.
  result.p3 = mm_set_ps(z, y, x, 0'f32)
  result.normalize()

func normalized*[T: Point|Direction](r: T): T =
  result.p3 = r.p3
  result.normalize()

# Standards
# TODO consider special case objects for skipping special case transforms
func X*(_: typedesc[Direction]): Direction =
  result.p3 = mm_set_ps(0'f32, 0'f32, 1'f32, 0'f32)

func Y*(_: typedesc[Direction]): Direction =
  result.p3 = mm_set_ps(0'f32, 1'f32, 0'f32, 0'f32)

func Z*(_: typedesc[Direction]): Direction =
  result.p3 = mm_set_ps(1'f32, 0'f32, 0'f32, 0'f32)

