## File: geometric_product.hpp
## Purpose: Define functions of the form gpAB where A and B are partition
## indices. Each function so-defined computes the geometric product using vector
## intrinsics. The partition index determines which basis elements are present
## in each XMM component of the operand.

#pragma once

import ./laser
import ./ops
import ./symoperator

## Partition memory layouts
##     LSB --> MSB
## p0: (e0, e1, e2, e3)
## p1: (1, e12, e31, e23)
## p2: (e0123, e01, e02, e03)
## p3: (e123, e032, e013, e021)

## p0: (e0, e1, e2, e3)
## p1: (1, e23, e31, e12)
## p2: (e0123, e01, e02, e03)

template gp00*(a, b: m128, p1, p2: var m128) =
  ## (a1 b1 + a2 b2 + a3 b3) +
  ##
  ## (a2 b3 - a3 b2) e23 +
  ## (a3 b1 - a1 b3) e31 +
  ## (a1 b2 - a2 b1) e12 +
  ##
  ## (a0 b1 - a1 b0) e01 +
  ## (a0 b2 - a2 b0) e02 +
  ## (a0 b3 - a3 b0) e03
  p1 = ((a.zyxz * b.zxzy) - flipw(a.yxzy * b.yyxz)).mm_add_ss(a.xwww * b.xwww)

  ## (a0 b0, a0 b1, a0 b2, a0 b3)
  ## Sub (a0 b0, a1 b0, a2 b0, a3 b0)
  ## Note that the lowest component cancels
  p2 = (a.wwww * b) - (a * b.wwww)

## p0: (e0, e1, e2, e3)
## p3: (e123, e032, e013, e021)
## p1: (1, e12, e31, e23)
## p2: (e0123, e01, e02, e03)
template gp03*(a, b: m128, p1, p2: var m128, FLIP: static bool) =
  ## a1 b0 e23 +
  ## a2 b0 e31 +
  ## a3 b0 e12 +
  ## (a0 b0 + a1 b1 + a2 b2 + a3 b3) e0123 +
  ## (a3 b2 - a2 b3) e01 +
  ## (a1 b3 - a3 b1) e02 +
  ## (a2 b1 - a1 b2) e03
  ##
  ## With flip:
  ##
  ## a1 b0 e23 +
  ## a2 b0 e31 +
  ## a3 b0 e12 +
  ## -(a0 b0 + a1 b1 + a2 b2 + a3 b3) e0123 +
  ## (a3 b2 - a2 b3) e01 +
  ## (a1 b3 - a3 b1) e02 +
  ## (a2 b1 - a1 b2) e03

  p1 = a * b.wwww
  p1 = mm_blend_ps(p1, mm_setzero_ps(), 1)

  ## (_, a3 b2, a1 b3, a2 b1)
  p2 = (a.wxzy * b.wyxz) - (a.wyxz * b.wxzy)

  ## Compute a0 b0 + a1 b1 + a2 b2 + a3 b3 and store it in the low
  ## component
  let tmp = 
    when FLIP: flipw(dp(a, b))
    else     : dp(a, b)
  p2 = mm_add_ps(p2, tmp)

## p1: (1, e23, e31, e12)
template gp11*(a, b: m128, p1: var m128) =
  ## (a0 b0 - a1 b1 - a2 b2 - a3 b3) +
  ## (a0 b1 - a2 b3 + a1 b0 + a3 b2)*e23
  ## (a0 b2 - a3 b1 + a2 b0 + a1 b3)*e31
  ## (a0 b3 - a1 b2 + a3 b0 + a2 b1)*e12
  ## We use abcd to refer to the slots to avoid conflating bivector/scalar
  ## coefficients with cartesian coordinates
  ## In general, we can get rid of at most one swizzle
  ## p1 = (a.wwww * b) - (a.zyxz * b.zxzy)
  p1 = (a.wwww * b) - (a.zyxz * b.zxzy)

  ## In a separate register, accumulate the later components so we can
  ## negate the lower single-precision element with a single instruction
  p1 = p1 + flipw((a.yzyx * b.ywww) + (a.xxzy * b.xyxz))

## p3: (e123, e021, e013, e032)
## p2: (e0123, e01, e02, e03)
template gp33*(a, b: m128, p2: var m128) =
  ## (-a0 b0) +
  ## (-a0 b1 + a1 b0) e01 +
  ## (-a0 b2 + a2 b0) e02 +
  ## (-a0 b3 + a3 b0) e03
  ##
  ## Produce a translator by dividing all terms by a0 b0

  var tmp = a.wwww * b
  tmp     = tmp * mm_set_ps(-1'f32, -1'f32, -1'f32, -2'f32)
  tmp     = tmp + (a * b.wwww)

  ## (0, 1, 2, 3) -> (0, 0, 2, 2)
  var ss = mm_moveldup_ps(tmp)
  ss     = mm_movelh_ps(ss, ss)
  tmp    = tmp * rcp_nr1(ss)

  p2 = mm_blend_ps(tmp, mm_setzero_ps(), 1)

template gpDL*(u, v: float32, b, c: m128, p1, p2: var m128) =
  ## b1 u e23 +
  ## b2 u e31 +
  ## b3 u e12 +
  ## (-b1 v + c1 u) e01 +
  ## (-b2 v + c2 u) e02 +
  ## (-b3 v + c3 u) e03
  let u_vec = mm_set1_ps(u)
  let v_vec = mm_set1_ps(v)
  p1        =  u_vec * b
  p2        = (u_vec * c) - (v_vec * b)

template gpRT*(a, b: m128, p2: var m128, FLIP: static bool) =
  ## (a1 b1 + a2 b2 + a3 b3) e0123 +
  ## (a0 b1 + a3 b2 - a2 b3) e01 +
  ## (a0 b2 + a1 b3 - a3 b1) e02 +
  ## (a0 b3 + a2 b1 - a1 b2) e03
  ## 
  ## When flip, instead:
  ## (a1 b1 + a2 b2 + a3 b3) e0123 +
  ## (a0 b1 + a2 b3 - a3 b2) e01 +
  ## (a0 b2 + a3 b1 - a1 b3) e02 +
  ## (a0 b3 + a1 b2 - a2 b1) e03
  p2 = (a.zwww * b.zzyx)
  when FLIP:
    p2 = p2 + (a.yyxz * b.yxzy) - flipw(a.xxzy * b.xyxz)
  else:
    p2 = p2 + (a.yxzy * b.yyxz) - flipw(a.xyxz * b.xxzy)

template gp12*(a, b: m128, p2: var m128, FLIP: static bool) =
  gpRT(a, b, p2, FLIP)
  p2 = p2 - flipw(a * b.wwww)

## Optimized line * line operation
template gpLL*(l1p1, l1p2, l2p1, l2p2: m128, p1, p2: var m128) =
  ## l1: (p1: a, p2: d)
  ## l2: (p1: b, p2: c)
  ## (-a1 b1 - a3 b3 - a2 b2) +
  ## (a2 b1 - a1 b2) e12 +
  ## (a1 b3 - a3 b1) e31 +
  ## (a3 b2 - a2 b3) e23 +
  ## (a1 c1 + a3 c3 + a2 c2 + b1 d1 + b3 d3 + b2 d2) e0123
  ## (a3 c2 - a2 c3         + b2 d3 - b3 d2) e01 +
  ## (a1 c3 - a3 c1         + b3 d1 - b1 d3) e02 +
  ## (a2 c1 - a1 c2         + b1 d2 - b2 d1) e03 +
  let a = l1p1
  let d = l1p2
  let b = l2p1
  let c = l2p2
  let flip = mm_set_ss(-0'f32)

  p1 = mm_xor_ps(flip, a.zyzx * b.zzxy) - (a.xzxy * b.xyzx)
  let a2 = mm_unpackhi_ps(a, a)
  let b2 = mm_unpackhi_ps(b, b)
  p1     = mm_sub_ss(p1, mm_mul_ss(a2, b2))

  p2 =          (a.zxzy * c.zyxz) -
      (mm_xor_ps(a.xyxz * c.xxzy, flip)) +
                (b.zyxz * d.zxzy) -
      (mm_xor_ps(b.xxzy * d.xyxz, flip))
  let c2 = mm_unpackhi_ps(c, c)
  let d2 = mm_unpackhi_ps(d, d)
  p2 = p2.mm_add_ss(a2 * c2).mm_add_ss(b2 * d2)

## Optimized motor * motor operation
template gpMM*(m1p1, m1p2, m2p1, m2p2: m128, p1, p2: var m128) =
  ## (a0 c0 - a1 c1 - a2 c2 - a3 c3) +
  ## (a0 c1 + a3 c2 + a1 c0 - a2 c3) e23 +
  ## (a0 c2 + a1 c3 + a2 c0 - a3 c1) e31 +
  ## (a0 c3 + a2 c1 + a3 c0 - a1 c2) e12 +
  ##
  ## (a0 d0 + b0 c0 + a1 d1 + b1 c1 + a2 d2 + a3 d3 + b2 c2 + b3 c3)
  ##  e0123 +
  ## (a0 d1 + b1 c0 + a3 d2 + b3 c2 - a1 d0 - a2 d3 - b0 c1 - b2 c3)
  ##  e01 +
  ## (a0 d2 + b2 c0 + a1 d3 + b1 c3 - a2 d0 - a3 d1 - b0 c2 - b3 c1)
  ##  e02 +
  ## (a0 d3 + b3 c0 + a2 d1 + b2 c1 - a3 d0 - a1 d2 - b0 c3 - b1 c2)
  ##  e03
  let a = m1p1
  let b = m1p2
  let c = m2p1
  let d = m2p2

  let a_wwww = a.wwww
  let a_yzyx = a.yzyx
  let a_zxzy = a.zxzy
  let a_xyxz = a.xyxz
  let c_xxzy = c.xxzy
  let c_zyxz = c.zyxz
  let s_flip = mm_set_ss(-0'f32)

  p1    = a_wwww * c
  var t = (a_zxzy * c_zyxz) + (a_yzyx * c.ywww)
  t     = mm_xor_ps(t, s_flip)
  p1    = (p1 + t) - (a_xyxz * c_xxzy)

  p2 = (a_wwww * d     ) +
       (b      * c.wwww) +
       (a_zxzy * d.zyxz) +
       (b.zxzy * c_zyxz)

  t = (a_yzyx * d.ywww) +
      (a_xyxz * d.xxzy) +
      (b.ywww * c.yzyx) +
      (b.xyxz * c_xxzy)

  p2 = p2 - t.mm_xor_ps(s_flip)

