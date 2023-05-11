## \defgroup lines Lines
## Klein provides three line classes: "line", "branch", and "ideal_line". The
## line class represents a full six-coordinate bivector.
## 
## The branch contains three non-degenerate components (aka, a line through
## the origin).
## 
## The ideal line represents the line at infinity. When the line is created as
## a meet of two planes or join of two points (or carefully selected Plücker
## coordinates), it will be a Euclidean line (factorizable as the meet of two
## vectors).

from math import nil

import ./types
import ../utils
import ../backend/laser
import ../backend/ops
import ../backend/symoperator


func newLine*(p1, p2: m128): Line =
  Line(p1: p1, p2: p2)
func newLine*[T: SomeNumber](e01, e02, e03, e23, e31, e12: T): Line {.autoConvert: float32.} =
  # Generate a line from plucker coordinates
  # Might be non-unique. Be careful.
  Line(p1: mm_set_ps(e12, e31, e23, 0'f32),
       p2: mm_set_ps(e03, e02, e01, 0'f32))

func newIdealLine*[T: SomeNumber](e01, e02, e03: T): IdealLine {.autoConvert: float32.} =
  IdealLine(p2: mm_set_ps(e03, e02, e01, 0'f32))
func newIdealLine*(a: m128): IdealLine =
  IdealLine(p2: a)

func newBranch*[T: SomeNumber](e23, e31, e12: T): Branch {.autoConvert: float32.} =
  ## To convince yourself this is a line through the origin, remember that
  ## such a line can be generated using the geometric product of two planes
  ## through the origin.
  Branch(p1: mm_set_ps(e12, e31, e23, 0'f32))
func newBranch*(a: m128): Branch =
  Branch(p1: a)

## Conversion
func Line*(other: IdealLine): Line =
  Line(p1: mm_setzero_ps(), p2: other.p2)
func Line*(other: Branch): Line =
  Line(p1: other.p1, p2: mm_setzero_ps())


# Standards
func X*(_: typedesc[Branch]): Branch =
  result.p1 = mm_set_ps(0'f32, 0'f32, 1'f32, 0'f32)

func Y*(_: typedesc[Branch]): Branch =
  result.p1 = mm_set_ps(0'f32, 1'f32, 0'f32, 0'f32)

func Z*(_: typedesc[Branch]): Branch =
  result.p1 = mm_set_ps(1'f32, 0'f32, 0'f32, 0'f32)



###############
## Operators ##
###############

func squared_norm*(a: Line|Branch): float32 =
  ## If a line is constructed as the regressive product (join) of
  ## two points, the squared norm provided here is the squared
  ## distance between the two points (provided the points are
  ## normalized). Returns $d^2 + e^2 + f^2$.
  mm_store_ss(result.addr, hi_dp(a.p1, a.p1))

func squared_norm*(a: IdealLine): float32 =
  mm_store_ss(result.addr, hi_dp(a.p2, a.p2))

func norm*(a: Line|IdealLine|Branch): float32 =
  math.sqrt(squared_norm(a))

func normalize*(a: var Line) =
  ## l = b + c where b is p1 and c is p2
  ## l * ~l = |b|^2 - 2(b1 c1 + b2 c2 + b3 c3)e0123
  ##
  ## sqrt(l*~l) = |b| - (b1 c1 + b2 c2 + b3 c3)/|b| e0123
  ##
  ## 1/sqrt(l*~l) = 1/|b| + (b1 c1 + b2 c2 + b3 c3)/|b|^3 e0123
  ##              = s + t e0123
  let b2 = hi_dp_bc(a.p1, a.p1)
  let s  = rsqrt_nr1(b2)
  let bc = hi_dp_bc(a.p1, a.p2)
  let t  = bc * rcp_nr1(b2) * s

  ## p1 * (s + t e0123) = s * p1 - t p1_perp
  a.p2 = (a.p2 * s) - (a.p1 * t)
  a.p1 =  a.p1 * s

func normalize*(a: var Branch) =
  a.p1 = rsqrt_nr1(hi_dp_bc(a.p1, a.p1)) * a.p1

func normalized*[T: Line|Branch](a: T): T =
  result = a
  result.normalize()

func invert*(a: var Line) =
  # s,t as in the normalization
  let b2 = hi_dp_bc(a.p1, a.p1)
  let s  = rsqrt_nr1(b2)
  let bc = hi_dp_bc(a.p1, a.p2)
  let b2inv = rcp_nr1(b2)
  let t = bc * b2inv * s
  let neg = mm_set_ps(-0'f32, -0'f32, -0'f32, 0'f32)

  let st = s * t * a.p1
  a.p2 = mm_xor_ps((a.p2 * b2inv) - (st + st), neg)
  a.p1 = mm_xor_ps(a.p1 * b2inv, neg)

func invert*(a: var Branch) =
  let invnorm = rsqrt_nr1(hi_dp_bc(a.p1, a.p1))
  let flip = mm_set_ps(-0'f32, -0'f32, -0'f32, 0'f32)
  a.p1 = mm_xor_ps(a.p1 * invnorm * invnorm, flip)

func inverse*[T: Line|Branch](a: T): T =
  result = a
  result.invert()

func revert*(l: Line): Line {.inline.} =
  let flip = mm_set_ps(-0'f32, -0'f32, -0'f32, 0'f32)
  Line(p1: mm_xor_ps(l.p1, flip),
       p2: mm_xor_ps(l.p2, flip))

template `~`*(l: Line): Line =
  l.revert()
