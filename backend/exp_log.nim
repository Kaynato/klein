## File: exp_log.hpp
## Purpose: Provide routines for taking bivector/motor exponentials and
## logarithms.

from math import nil

import ./laser
import ./ops
import ./symoperator

## a := p1
## b := p2
## a + b is a general bivector but it is most likely *non-simple* meaning
## that it is neither purely real nor purely ideal.
## Exponentiates the bivector and returns the motor defined by partitions 1
## and 2.

template expImpl*(a, b: m128, p1, p2: var m128) =
  ## The exponential map produces a continuous group of rotations about an
  ## axis. We'd *like* to evaluate the exp(a + b) as exp(a)exp(b) but we
  ## cannot do that in general because a and b do not commute (consider
  ## the differences between the Taylor expansion of exp(ab) and
  ## exp(a)exp(b)).
  let a2 = hi_dp_bc(a, a)
  let ab = hi_dp_bc(a, b)

  ## Next, we need the sqrt of that quantity. Since e0123 squares to 0,
  ## this has a closed form solution.
  ## Maximum relative error < 1.5*2e-12
  let a2_sqrt_rcp = rsqrt_nr1(a2)
  let u           = a2 * a2_sqrt_rcp
  ## Don't forget the minus later!
  let minus_v = ab * a2_sqrt_rcp

  ## Last, we need the norm-reciprocal to compute the normalized bivector.
  ## The original bivector * the inverse norm makes a normalized bivector.
  let norm_real  = a * a2_sqrt_rcp
  # var norm_ideal = b * a2_sqrt_rcp
  ## The real part of the bivector also interacts with the pseudoscalar to
  ## produce a portion of the normalized ideal part
  ## e12 e0123 = -e03, e31 e0123 = -e02, e23 e0123 = -e01
  ## Notice how the products above actually commute
  let norm_ideal = (b * a2_sqrt_rcp) - (a * ab * a2_sqrt_rcp * rcp_nr1(a2))

  ## The norm * our normalized bivector is the original bivector (a + b).
  ## Thus, we have: (u + vI)n = u n + v n e0123
  ##
  ## Note that n and n e0123 are perpendicular (n e0123 lies on the ideal
  ## plane, and all ideal components of n are extinguished after
  ## polarization). As a result, we can now decompose the exponential.
  ##
  ## e^(u n + v n e0123) = e^(u n) e^(v n e0123) =
  ## (cosu + sinu n) * (1 + v n e0123) =
  ## cosu + sinu n + v n cosu e0123 + v sinu n^2 e0123 =
  ## cosu + sinu n + v n cosu e0123 - v sinu e0123
  ##
  ## where we've used the fact that n is normalized and squares to -1.
  var uv: array[2, float32]
  mm_store_ss(uv[0].addr, u)
  ## Note the v here corresponds to minus_v
  mm_store_ss(uv[1].addr, minus_v)

  var sincosu: array[2, float32]
  sincosu[0] = math.sin(uv[0])
  sincosu[1] = math.cos(uv[0])

  let sinu = mm_set1_ps(sincosu[0])
  p1 = mm_set_ps(0'f32, 0'f32, 0'f32, sincosu[1]) + (sinu * norm_real)

  ## The 2nd partition has contributions from both real and ideal parts.
  let cosu = mm_set_ps(sincosu[1], sincosu[1], sincosu[1], 0'f32)
  let minus_vcosu = (minus_v * cosu)
  p2 = mm_mul_ps(sinu, norm_ideal)
    .mm_add_ps(minus_vcosu * norm_real)
    .mm_add_ps(mm_set_ps(0'f32, 0'f32, 0'f32, uv[1] * sincosu[0]))

template logImpl*(i1, i2: m128, o1, o2: var m128) =
  ## The logarithm follows from the derivation of the exponential. Working
  ## backwards, we ended up computing the exponential like so:
  ##
  ## cosu + sinu n + v n cosu e0123 - v sinu e0123 =
  ## (cosu - v sinu e0123) + (sinu + v cosu e0123) n
  ##
  ## where n is the normalized bivector. If we compute the norm, that will
  ## allow us to match it to sinu + vcosu e0123, which will then allow us
  ## to deduce u and v.

  ## The first thing we need to do is extract only the bivector components
  ## from the motor.
  let bv_mask = mm_set_ps(1'f32, 1'f32, 1'f32, 0'f32)
  let a       = bv_mask * i1
  let b       = bv_mask * i2

  ## Next, we need to compute the norm as in the exponential.
  let a2 = hi_dp_bc(a, a)
  ## TODO: handle case when a2 is 0
  let ab          = hi_dp_bc(a, b)
  let a2_sqrt_rcp = rsqrt_nr1(a2)
  let s           = a2 * a2_sqrt_rcp
  let minus_t     = ab * a2_sqrt_rcp
  ## s + t e0123 is the norm of our bivector.

  ## Store the scalar component
  var p: float32
  mm_store_ss(p.addr, i1)

  ## Store the pseudoscalar component
  var q: float32
  mm_store_ss(q.addr, i2)

  var s_scalar: float32
  mm_store_ss(s_scalar.addr, s)

  var t_scalar: float32
  mm_store_ss(t_scalar.addr, minus_t)
  t_scalar *= -1'f32

  ## p = cosu
  ## q = -v sinu
  ## s_scalar = sinu
  ## t_scalar = v cosu

  let p_zero = abs(p) < 1e-6'f32
  let (u, v) =
    if p_zero: (math.arctan2(-q, t_scalar), -q / s_scalar)
    else     : (math.arctan2(s_scalar, p), t_scalar / p)

  ## Now, (u + v e0123) * n when exponentiated will give us the motor, so
  ## (u + v e0123) * n is the logarithm. To proceed, we need to compute
  ## the normalized bivector.
  let norm_real  = a * a2_sqrt_rcp
  let norm_ideal = b * a2_sqrt_rcp - (a * ab * a2_sqrt_rcp * rcp_nr1(a2))
  let uvec = mm_set1_ps(u)

  o1 = uvec * norm_real
  o2 = (uvec * norm_ideal) - (mm_set1_ps(v) * norm_real)


