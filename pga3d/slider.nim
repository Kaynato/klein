## Sliders
##
## A slider represents a rigid-body displacement along a normalized axis.
## To apply the slider to a supported entity, the `slide` operator
## is available.
##
## !!! example
##
##     ```nim
##         # Initialize a point at (1, 3, 2)
##         let p = newPoint(1, 3, 2)
##
##         # Create a normalized slider representing a 4-unit
##         # displacement along the xz-axis.
##         let r = newSlider(4, 1, 0, 4)
##
##         # Displace our point using the created slider
##         let translated = p >> r
##     ```
##     We can translate lines and planes as well using the slide operator.
##
## Sliders can be multiplied to one another with the `*` operator to create
## a new slider equivalent to the application of each factor.
##
## !!! example
##
##     ```nim
##         # Suppose we have 3 sliders t1, t2, and t3
##
##         # The slider t created here represents the combined action of
##         # t1, t2, and t3.
##         let t: Slider = t3 * t2 * t1
##     ```
##
## The same `*` operator can be used to compose the slider's action with
## other rotors and motors.

from math import nil

import ./types
import ../utils
import ../backend/[laser, symoperator]

func newSlider*[T: SomeNumber](delta, x, y, z: T): Slider {.autoConvert: float32.} =
  ## Construct a slider as a displacement along a normalized axis
  let invnorm = 1'f32 / math.sqrt(x * x + y * y + z * z)
  let v = -delta * 0.5'f32 * invnorm
  Slider(p2: mm_set_ps(v, v, v, 0'f32) * mm_set_ps(z, y, x, 0'f32))

func newSlider*(xmm: m128): Slider =
  Slider(p2: xmm)

func invert*(r: var Slider) =
  r.p2 = mm_xor_ps(r.p2, mm_set_ps(-0'f32, -0'f32, -0'f32, 0'f32))

func inverse*(r: Slider): Slider =
  result.p2 = r.p2
  result.invert()

func Identity*(_: typedesc[Slider]): Slider =
  Slider(p2: mm_setzero_ps())
