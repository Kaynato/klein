## Exponential and Logarithm
##
## The group of rotations, translations, and screws (combined rotatation and
## translation) is _nonlinear_. This means, given say, a rotor $\mathbf{r}$,
## the rotor
## $\frac{\mathbf{r}}{2}$ _does not_ correspond to half the rotation.
## Similarly, for a motor $\mathbf{m}$, the motor $n \mathbf{m}$ is not $n$
## applications of the motor $\mathbf{m}$. One way we could achieve this is
## through exponentiation for example, the motor $\mathbf{m}^3$ will perform
## the screw action of $\mathbf{m}$ three times. However, repeated
## multiplication in this fashion lacks both efficiency and numerical
## stability.
##
## The solution is to take the logarithm of the action which maps the action to
## a linear space. Using `log(A)` where `A` is one of `rotor`,
## `translator`, or `motor`, we can apply linear scaling to `log(A)`,
## and then re-exponentiate the result. Using this technique, `exp(n * log(A))`
## is equivalent to $\mathbf{A}^n$.

from math import nil
import ./types
import ./rotor
import ./arithmetic
import ../backend/[laser, ops, symoperator, exp_log]

# # # ===== Misc
func log*(m: Motor): Line {.inline.} =
  ## Takes the principal branch of the logarithm of the motor, returning a
  ## bivector. Exponentiation of that bivector without any changes produces
  ## this motor again. Scaling that bivector by $\frac{1}{n}$,
  ## re-exponentiating, and taking the result to the $n$th power will also
  ## produce this motor again. The logarithm presumes that the motor is
  ## normalized.
  logImpl(m.p1, m.p2, result.p1, result.p2)

func exp*(l: Line): Motor {.inline.} =
  ## Exponentiate a line to produce a motor that posesses this line
  ## as its axis. This routine will be used most often when this line is
  ## produced as the logarithm of an existing rotor, then scaled to subdivide
  ## or accelerate the motor's action. The line need not be a _simple bivector_
  ## for the operation to be well-defined.
  expImpl(l.p1, l.p2, result.p1, result.p2)

func log*(s: Slider): IdealLine {.inline.} =
  ## Compute the logarithm of the translator, producing an ideal line axis.
  ## In practice, the logarithm of a translator is simply the ideal partition
  ## (without the scalar $1$).
  result.p2 = s.p2

## Exponentiate an ideal line to produce a translation.
##
## The exponential of an ideal line
## $a \mathbf{e}_{01} + b\mathbf{e}_{02} + c\mathbf{e}_{03}$ is given as:
##
## $$\exp{\left[a\ee_{01} + b\ee_{02} + c\ee_{03}\right]} = 1 +\
## a\ee_{01} + b\ee_{02} + c\ee_{03}$$
func exp*(l: IdealLine): Slider {.inline.} =
  result.p2 = l.p2

func log*(r: Rotor): Branch {.inline.} =
  ## Returns the principal branch of this rotor's logarithm. Invoking
  ## `exp` on the returned `kln::branch` maps back to this rotor.
  ##
  ## Given a rotor $\cos\alpha + \sin\alpha\left[a\ee_{23} + b\ee_{31} +\
  ## c\ee_{23}\right]$, the log is computed as simply
  ## $\alpha\left[a\ee_{23} + b\ee_{31} + c\ee_{23}\right]$.
  ## This map is only well-defined if the
  ## rotor is normalized such that $a^2 + b^2 + c^2 = 1$.
  var cos_ang: float32
  mm_store_ss(cos_ang.addr, r.p1)
  let ang     = math.arccos(cos_ang)
  let sin_ang = math.sin(ang)

  result.p1 = (r.p1 * mm_set1_ps(sin_ang).rcp_nr1())
    .mm_mul_ps(mm_set1_ps(ang))
    .mm_blend_ps(mm_setzero_ps(), 1'u8)

func exp*(b: Branch): Rotor {.inline.} =
  ## Exponentiate a branch to produce a rotor.
  # Compute the rotor angle
  var ang: float32
  mm_store_ss(ang.addr, hi_dp(b.p1, b.p1).sqrt_nr1())
  let cos_ang = math.cos(ang)
  let sin_ang = math.sin(ang) / ang

  result.p1 = mm_set_ps(0'f32, 0'f32, 0'f32, cos_ang)
    .mm_add_ps(mm_set1_ps(sin_ang) * b.p1)

func sqrt*(r: Rotor): Rotor {.inline.} =
  ## Compute the square root of the provided rotor $r$.
  result.p1 = mm_add_ss(r.p1, mm_set_ss(1'f32))
  result.normalize()

func sqrt*(b: Branch): Rotor {.inline.} =
  ## Sqrt a branch to get a Rotor
  result.p1 = mm_add_ss(b.p1, mm_set_ss(1'f32))
  result.normalize()

## Compute the square root of the provided translator $t$.
func sqrt*(s: Slider): Slider {.inline.} =
  s * 0.5'f32

## Motor sqrt found in Motor.nim
