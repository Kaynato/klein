## Planes
##
## In projective geometry, planes are the fundamental element through which all
## other entities are constructed. Lines are the meet of two planes, and points
## are the meet of three planes (equivalently, a line and a plane).
##
## The plane multivector in PGA looks like
## $d\mathbf{e}_0 + a\mathbf{e}_1 + b\mathbf{e}_2 + c\mathbf{e}_3$. Points
## that reside on the plane satisfy the familiar equation
## $d + ax + by + cz = 0$.

import ../backend/laser
import ../backend/ops
import ../backend/symoperator
import ../utils
import ./types

func newPlane*(xmm: m128): Plane =
  Plane(p0: xmm)

func newPlane*(data: ptr float32): Plane =
  Plane(p0: mm_loadu_ps(data))

func newPlane*[T: SomeNumber](x, y, z, d: T): Plane {.autoConvert: float32.} =
  ## Constructs plane in the form: ax + by + cz + d
  Plane(p0: mm_set_ps(z, y, x, d))

func newPlane*[T: SomeNumber](x, y, z, mx, my, mz: T): Plane {.autoConvert: float32.} =
  ## Construct plane from point-normal form
  ## mx(ex-x) + my(ey-y) + mz(ez-z) = 0
  ## mx ex + my ey + mz ez = mx x + my y + mz z
  let d = mx * x + my * y + mz * z
  Plane(p0: mm_set_ps(mz, my, mx, d))
  

func normalize*(p: var Plane) =
  p.p0 = hi_dp_bc(p.p0, p.p0)
    .rsqrt_nr1()
    .mm_blend_ps(mm_set_ss(1'f32), 1'u8) # TODO include no-4.1 fallback
    .mm_mul_ps(p.p0)

func normalized*(p: Plane): Plane =
  result.p0 = p.p0
  result.normalize()

func norm*(p: Plane): float32 =
  result.addr.mm_store_ss(hi_dp(p.p0, p.p0).sqrt_nr1())

func invert*(p: var Plane) =
  let invnorm = hi_dp_bc(p.p0, p.p0).rsqrt_nr1()
  p.p0 = p.p0 * invnorm * invnorm

func inverse*(p: Plane): Plane =
  result.p0 = p.p0
  result.invert()
