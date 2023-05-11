## \defgroup rotor Rotors
##
## The rotor is an entity that represents a rigid rotation about an axis.
## To apply the rotor to a supported entity, the call operator is available.
##
## !!! example
##
##     ```nim
##         # Initialize a point at (1, 3, 2)
##         let p = newPoint(1, 3, 2)
##
##         # Create a normalized rotor representing a pi/2 radian
##         # rotation about the xz-axis.
##         let r = newRotor(PI * 0.5, 1, 0, 1)
##
##         # Rotate our point using the created rotor
##         let rotated = p.rotate(r)
##     ```
##     We can rotate lines and planes as well using the `rotate` proc.
##     The rotate proc is also aliased to the special operator `>@`
##
## Rotors can be multiplied to one another with the `*` operator to create
## a new rotor equivalent to the application of each factor.
##
## !!! example
##
##     ```nim
##         # Create a normalized rotor representing a $\frac{\pi}{2}$ radian
##         # rotation about the xz-axis.
##         let r1 = newRotor(PI * 0.5, 1, 0, 1)
##
##         # Create a second rotor representing a $\frac{\pi}{3}$ radian
##         # rotation about the yz-axis.
##         let r2 = newRotor(PI / 3'f32, 0, 1, 1)
##
##         # Use the geometric product to create a rotor equivalent to first
##         # applying r1, then applying r2. Note that the order of the
##         # operands here is significant.
##         let r3 = r2 * r1
##     ```
##
## The same `*` operator can be used to compose the rotor's action with other
## translators and motors.
## `*` is also aliased with the `compose` proc.

from math import nil

import ./types
import ../backend/[laser, ops, symoperator]

func newRotor*(p1: m128): Rotor =
  Rotor(p1: p1)

func newRotor*[T: SomeNumber](radians: float32, x, y, z: T): Rotor =
  ## Construct a rotor from the angle-vector representation.
  let norm = math.sqrt((x * x + y * y + z * z).float32)
  let inv_norm = 1'f32 / norm
  let halfangle = radians * 0.5'f32
  # The compiler will combine the sin/cos calls
  let scale = math.sin(halfangle) * inv_norm
  result.p1 = mm_set_ps(z.float32, y.float32, x.float32, math.cos(halfangle))
    .mm_mul_ps(mm_set_ps(scale, scale, scale, 1'f32))

func normalize*(r: var Rotor) =
  ## Normalize a rotor.
  ## A rotor is normalized if r * ~r is identity.
  r.p1 = dp_bc(r.p1, r.p1).rsqrt_nr1() * r.p1

func normalized*(r: Rotor): Rotor =
  result.p1 = r.p1
  result.normalize()

func invert*(r: var Rotor) =
  let inv_norm = hi_dp_bc(r.p1, r.p1).rsqrt_nr1()
  r.p1 = (r.p1 * inv_norm * inv_norm)
    .mm_xor_ps(mm_set_ps(-0'f32, -0'f32, -0'f32, 0'f32))

func inverse*(r: Rotor): Rotor =
  result.p1 = r.p1
  result.invert()

func constrain*(r: var Rotor) =
  ## Constrain the rotor to traverse the shortest arc
  r.p1 = (r.p1 & mm_set_ss(-0'f32)).wwww.mm_xor_ps(r.p1)

func constrained*(r: Rotor): Rotor =
  result.p1 = r.p1
  result.constrain()

func Identity*(_: typedesc[Rotor]): Rotor =
  # TODO consider identity object for skipping special case transforms
  result.p1 = mm_set_ps(0, 0, 0, 1)
