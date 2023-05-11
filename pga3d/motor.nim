## \defgroup motor Motors
##
## A `motor` represents a kinematic motion in our algebra. From
## [Chasles'
## theorem](https://en.wikipedia.org/wiki/Chasles%27_theorem_(kinematics)), we
## know that any rigid body displacement can be produced by a translation along
## a line, followed or preceded by a rotation about an axis parallel to that
## line. The motor algebra is isomorphic to the dual quaternions but exists
## here in the same algebra as all the other geometric entities and actions at
## our disposal. Operations such as composing a motor with a rotor or
## translator are possible for example. The primary benefit to using a motor
## over its corresponding matrix operation is twofold. First, you get the
## benefit of numerical stability when composing multiple actions via the
## geometric product (`*`). Second, because the motors constitute a continuous
## group, they are amenable to smooth interpolation and differentiation.
##
## !!! example
##
##     ```nim
##         # Create a rotor representing a pi/2 rotation about the z-axis
##         # Normalization is done automatically
##         let r = newRotor(PI * 0.5'f32, 0'f32, 0'f32, 1'f32)
##
##         # Create a translator that represents a translation of 1 unit
##         # in the yz-direction. Normalization is done automatically.
##         let t = newSlider(1, 0, 1, 1)
##
##         # Create a motor that combines the action of the rotation and
##         # translation above.
##         let m = r * t
##
##         # Initialize a point at (1, 3, 2)
##         let p1 = newPoint(1, 3, 2)
##
##         # Translate p1 and rotate it to create a new point p2
##         let p2 = m >% p1
##     ```
##
## It might also be appropriate to use the general apply operator actor[acted].
##
## Motors can be multiplied to one another with the `*` operator to create
## a new motor equivalent to the application of each factor.
##
## !!! example
##
##     ```nim
##         # Suppose we have 3 motors m1, m2, and m3
##
##         # The motor m created here represents the combined action of m1,
##         # m2, and m3.
##         let m: Motor = m3 * m2 * m1
##     ```
##
## The same `*` operator can be used to compose the motor's action with other
## translators and rotors.
##
## A demonstration of using the exponential and logarithmic map to blend
## between two motors is provided in a test case
## [here](https://github.com/jeremyong/Klein/blob/master/test/test_exp_log.cpp#L48).
import ./types
import ./exp_log
import ../utils
import ../backend/[laser, ops, symoperator]
import ../backend/geometric_product

func newMotor*[T: SomeNumber](
  scalar, e23, e32, e12, e01, e02, e03, i: T): Motor {.autoConvert: float32.} =
  ## Direct initialization from components. A more common way of creating a
  ## motor is to take a product between a rotor and a translator.
  ## The arguments coorespond to the multivector constructed accordingly
  ##   by the arguments' names
  Motor(p1: mm_set_ps(e12, e32, e23, scalar),
        p2: mm_set_ps(e03, e02, e01, i))

func newMotor*(p1, p2: m128): Motor =
  Motor(p1: p1, p2: p2)

func newMotor*(angle: float32, delta: SomeNumber, axis: Line): Motor =
  ## Produce a screw motor rotating and translating along the provided axis line
  var log_m: Line
  gpDL(-angle * 0.5'f32, delta.float32 * 0.5'f32, axis.p1, axis.p2, log_m.p1, log_m.p2)
  exp(log_m)

# Explicit converters
func motor*(r: Rotor): Motor =
  Motor(p1: r.p1, p2: mm_setzero_ps())

func motor*(s: Slider): Motor =
  Motor(p1: mm_set_ss(1'f32), p2: s.p2)

# Write to motor from rotor/slider (why would you do this?)
func load*(m: var Motor, r: Rotor) =
  m.p1 = r.p1
  m.p2 = mm_setzero_ps()

func load*(m: var Motor, s: Slider) =
  m.p1 = mm_set_ss(1'f32)
  m.p2 = s.p2

func normalize*(m: var Motor) =
  let b2 = dp_bc(m.p1, m.p1)
  let s  = rsqrt_nr1(b2)
  let bc = dp_bc(flipw(m.p1), m.p2)
  let t  = bc * rcp_nr1(b2) * s
  m.p2 = (m.p2 * s) - flipw(m.p1 * t)
  m.p1 = m.p1 * s

func invert*(m: var Motor) =
  ## s, t computed as in the normalization
  let b2     = dp_bc(m.p1, m.p1)  
  let s      = rsqrt_nr1(b2)
  let bc     = dp_bc(flipw(m.p1), m.p2)
  let b2_inv = rcp_nr1(b2)
  let t      = bc * b2_inv * s
  let neg    = mm_set_ps(-0'f32, -0'f32, -0'f32, 0'f32)

  ## p1 * (s + t e0123)^2 = (s * p1 - t p1_perp) * (s + t e0123)
  ## = s^2 p1 - s t p1_perp - s t p1_perp
  ## = s^2 p1 - 2 s t p1_perp
  ## (the scalar component above needs to be negated)
  ## p2 * (s + t e0123)^2 = s^2 p2 NOTE: s^2 = b2_inv
  var st = s * t * m.p1
  m.p2   = (m.p2 * b2_inv) - flipw(st + st)
  m.p2   = mm_xor_ps(m.p2, neg)
  m.p1   = mm_xor_ps(m.p1 * b2_inv, neg)

func constrain*(m: var Motor) =
  let mask = (m.p1 & mm_set_ss(-0'f32)).wwww
  m.p1 = mm_xor_ps(m.p1, mask)
  m.p2 = mm_xor_ps(m.p2, mask)

## Copy-producing versions of in-place ops
func normalized*(m: Motor): Motor =
  result = m
  result.normalize()

func inverse*(m: Motor): Motor =
  result = m
  result.invert()

func constrained*(m: Motor): Motor =
  result = m
  result.constrain()

func sqrt*(m: Motor): Motor {.inline.} =
  ## Compute the normalized square root of the provided motor $m$.
  result.p2 = m.p2
  result.p1 = mm_add_ss(m.p1, mm_set_ss(1'f32))
  result.normalize()
