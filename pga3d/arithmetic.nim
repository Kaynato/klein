## Arithmetic with PGA3D objects

import ./types
import ./internal_access
import ../backend/laser
import ../backend/ops
import ../backend/symoperator
import ../utils

##############################
## Addition and subtraction ##
##############################

func `+=`*[T: SingleXmm](a: var T, b: T) {.inline.} = xmm(a) = xmm(a) + xmm(b)
func `-=`*[T: SingleXmm](a: var T, b: T) {.inline.} = xmm(a) = xmm(a) - xmm(b)
func `+`*[T: SingleXmm](a, b: T): T {.inline.} = xmm(result) = xmm(a) + xmm(b)
func `-`*[T: SingleXmm](a, b: T): T {.inline.} = xmm(result) = xmm(a) - xmm(b)

func `+`*(a, b: Dual): Dual {.inline.} =
  result.p = a.p + b.p
  result.q = a.q + b.q
func `-`*(a, b: Dual): Dual {.inline.} =
  result.p = a.p - b.p
  result.q = a.q - b.q

func `+=`*[T: Motor | Line](a: var T, b: T) {.inline.} =
  a.p1 = a.p1 + b.p1
  a.p2 = a.p2 + b.p2
func `-=`*[T: Motor | Line](a: var T, b: T) {.inline.} =
  a.p1 = a.p1 - b.p1
  a.p2 = a.p2 - b.p2
func `+`*[T: Motor | Line](a, b: T): T {.inline.} =
  result.p1 = a.p1 + b.p1
  result.p2 = a.p2 + b.p2
func `-`*[T: Motor | Line](a, b: T): T {.inline.} =
  result.p1 = a.p1 - b.p1
  result.p2 = a.p2 - b.p2

func `+=`*(a: var Dual, b: Dual): Dual {.inline.} =
  a.p += b.p
  a.q += b.q
func `-=`*(a: var Dual, b: Dual): Dual {.inline.} =
  a.p -= b.p
  a.q -= b.q

###########
## Minus ##
###########

func `-`*[T: Plane|Point](a: T): T {.inline.} =
  ## Offset-preserving negation
  xmm(result) = mm_xor_ps(xmm(a), mm_set_ps(-0'f32, -0'f32, -0'f32, 0'f32))

func `-`*[T: Rotor|IdealLine|Branch|Direction](a: T): T {.inline.} =
  ## Unary minus
  xmm(result) = mm_xor_ps(xmm(a), mm_set1_ps(-0'f32))

func `-`*[T: Motor|Line](a: T): T {.inline.} =
  let flip = mm_set1_ps(-0'f32)
  result.p1 = mm_xor_ps(a.p1, flip)
  result.p2 = mm_xor_ps(a.p2, flip)

###############
## Reversion ##
###############

func revert*[T: Rotor|IdealLine|Branch](r: T): T {.inline.} =
  xmm(result) = mm_xor_ps(mm_set_ps(-0'f32, -0'f32, -0'f32, 0'f32), xmm(r))

func revert*[T: Motor|Line](m: T): T {.inline.} =
  let flip = mm_set_ps(-0'f32, -0'f32, -0'f32, 0'f32)
  result.p1 = mm_xor_ps(m.p1, flip)
  result.p2 = mm_xor_ps(m.p2, flip)

template `~`*[T: Motor|Rotor](m: T): T =
  m.revert()

#####################
## Uniform scaling ##
#####################

func `*=`*[T: SomeNumber, X: SingleXmm](a: var X, b: T) {.inline, autoConvert: float32.} =
  xmm(a) = xmm(a) * mm_set1_ps(b)
func `*`*[T: SomeNumber, X: SingleXmm](a: X, b: T): X {.inline, autoConvert: float32.} =
  xmm(result) = xmm(a) * mm_set1_ps(b)
func `*`*[T: SomeNumber, X: SingleXmm](a: T, b: X): X {.inline, autoConvert: float32.} =
  xmm(result) = xmm(b) * mm_set1_ps(a)

func `*=`*[T: SomeNumber](a: var Dual, s: T) {.inline, autoConvert: float32.} =
  a.p *= s
  a.q *= s
func `*`*[T: SomeNumber](a: Dual, s: T): Dual {.inline, autoConvert: float32.} =
  Dual(p: a.p * s, q: a.q * s)
func `*`*[T: SomeNumber](s: T, a: Dual): Dual {.inline, autoConvert: float32.} =
  Dual(p: a.p * s, q: a.q * s)

func `*=`*[T: SomeNumber, X: Motor](a: var X, b: T) {.inline, autoConvert: float32.} =
  let s = mm_set1_ps(b)
  a.p1 = a.p1 * s
  a.p2 = a.p2 * s
func `*`*[T: SomeNumber, X: Motor](a: X, b: T): X {.inline, autoConvert: float32.} =
  let s = mm_set1_ps(b)
  result.p1 = a.p1 * s
  result.p2 = a.p2 * s
func `*`*[T: SomeNumber, X: Motor](a: T, b: X): X {.inline, autoConvert: float32.} =
  let s = mm_set1_ps(a)
  result.p1 = b.p1 * s
  result.p2 = b.p2 * s

## Uniform inverse scaling
func `/=`*[T: SomeNumber](a: var SingleXmm, s: T) {.inline, autoConvert: float32.} =
  xmm(a) = xmm(a) * rcp_nr1(mm_set1_ps(s))
func `/`*[T: SomeNumber, X: SingleXmm](a: X, s: T): X {.inline, autoConvert: float32.} =
  xmm(result) = xmm(a) * rcp_nr1(mm_set1_ps(s))

func `/=`*[T: SomeNumber](a: var Dual, s: T) {.inline, autoConvert: float32.} =
  a.p /= s
  a.q /= s
func `/`*[T: SomeNumber](a: Dual, s: T): Dual {.inline, autoConvert: float32.} =
  Dual(p: a.p / s, q: a.q/s)

func `/=`*[X: Motor|Line](a: var X, b: SomeNumber) {.inline.} =
  let s = rcp_nr1(mm_set1_ps(b))
  a.p1 = a.p1 * s
  a.p2 = a.p2 * s
func `/`*[X: Motor|Line](a: X, b: SomeNumber): X {.inline.} =
  let s = rcp_nr1(mm_set1_ps(b.float32))
  result.p1 = a.p1 * s
  result.p2 = a.p2 * s

################
## Comparison ##
################

proc `==`*(a, b: SingleXmm): bool = eq(xmm(a), xmm(b))

proc `==`*(a, b: Line | Motor): bool =
  mm_movemask_ps(a.p1 == b.p1 & a.p2 == b.p2) == 0xF'u8

func approx_eq*(a, b: SingleXmm, eps: float32): bool {.inline.} =
  approx_eq(xmm(a), xmm(b), eps)

proc approx_eq*(a, b: Line | Motor, eps: float32): bool =
  let eps = mm_set1_ps(eps)
  let neg = mm_set1_ps(-0'f32)
  let cmp1 = (neg ~& (a.p1 - b.p1)) < eps
  let cmp2 = (neg ~& (a.p2 - b.p2)) < eps
  mm_movemask_ps(cmp1 & cmp2) == 0xF'u8
