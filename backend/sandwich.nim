## Fast sandwich operations
## Ported from klein
## 
## 
## Purpose: Define functions of the form swAB where A and B are partition
## indices. Each function so-defined computes the sandwich operator using vector
## intrinsics. The partition index determines which basis elements are present
## in each XMM component of the operand.
##
## Notes:
## 1. The first argument is always the TARGET which is the multivector to apply
##    the sandwich operator to.
## 2. The second operator MAY be a bivector or motor (sandwiching with
##    a point or vector isn't supported at this time).
## 3. For efficiency, the sandwich operator is NOT implemented in terms of two
##    geometric products and a reversion. The result is nevertheless equivalent.

import ./laser
import ./ops
import ./symoperator
import ./pointerops
import ../pga3d/types

func sw00*(a, b: m128, p0: var m128) {.inline.} =
  ## Reflect a plane through another plane
  ## b * a * b
  ## 
  ## [ 2a (ab[2,2,3,1] + ab[3,3,1,2] + ab[1...]) 
  ##  + b (aa[-1,1,2,3] - aa[2,2,3,1] - aa[3,3,1,2])
  let a_zzwy = a.yyxz
  let a_wwyz = a.xxzy

  ## Left block
  let tmp = (b.yyxz * a_zzwy)
    .mm_add_ps(b.xxzy * a_wwyz)
    .mm_add_ss(mm_mul_ss(mm_movehdup_ps(a), mm_movehdup_ps(b)))
    .mm_mul_ps(a + a)

  ## Right block
  let a_yyzw = a.zzyx
  p0 = flipw(a_yyzw * a_yyzw)
    .mm_sub_ps(a_zzwy * a_zzwy)
    .mm_sub_ps(a_wwyz * a_wwyz)
    .mm_mul_ps(b)
    .mm_add_ps(tmp) # Combine with left block


func sw10*(a, b: m128, p1, p2: var m128) {.inline.} =
  ##                       b0(a1^2 + a2^2 + a3^2) +
  ## (2a3(a1 b1 + a2 b2) + b3(a3^2 - a1^2 - a2^2)) e12 +
  ## (2a1(a2 b2 + a3 b3) + b1(a1^2 - a2^2 - a3^2)) e23 +
  ## (2a2(a3 b3 + a1 b1) + b2(a2^2 - a3^2 - a1^2)) e31 +
  ##
  ## 2a0(a1 b2 - a2 b1) e03
  ## 2a0(a2 b3 - a3 b2) e01 +
  ## 2a0(a3 b1 - a1 b3) e02 +
  let a_yzyx = a.yzyx
  let a_yxzy = a.yxzy
  let a_xyxz = a.xyxz
  let b_wyxz = b.wyxz

  let twoz = mm_set_ps(2'f32, 2'f32, 2'f32, 0'f32)
  p1 = mm_mul_ps(a, b)
      .mm_add_ps(a_xyxz * b_wyxz)
      .mm_mul_ps(a_yxzy * twoz)

  p1 = (a_yxzy * a_yxzy)
    .mm_sub_ps(flipw(sqsum(a_yzyx, a_xyxz)))
    .mm_mul_ps(b.wxzy)
    .mm_add_ps(p1)
    .wyxz

  p2 = ((a_yzyx * b_wyxz) - (a_xyxz * b))
    .mm_mul_ps(a.wwww * twoz)
    .wyxz


func sw20*(a, b: m128, p2: var m128) {.inline.} =
  ##                       -b0(a1^2 + a2^2 + a3^2) e0123 +
  ## (-2a3(a1 b1 + a2 b2) + b3(a1^2 + a2^2 - a3^2)) e03
  ## (-2a1(a2 b2 + a3 b3) + b1(a2^2 + a3^2 - a1^2)) e01 +
  ## (-2a2(a3 b3 + a1 b1) + b2(a3^2 + a1^2 - a2^2)) e02 +
  let a_zzwy = a.yyxz
  let a_wwyz = a.xxzy

  p2 = (a_zzwy * b.wyxz)
    .mm_add_ps(a * b)
    .mm_mul_ps(a_wwyz)
    .mm_mul_ps(mm_set_ps(-2'f32, -2'f32, -2'f32, 0'f32))

  let a_yyzw = a.zzyx

  p2 = flipw(sqsum(a_yyzw, a_zzwy) - (a_wwyz * a_wwyz))
    .mm_mul_ps(b.wxzy)
    .mm_add_ps(p2)
    .wyxz


func sw30*(a, b: m128, p3: var m128) {.inline.} =
  ##                                b0(a1^2 + a2^2 + a3^2)  e123 +
  ## (-2a1(a0 b0 + a3 b3 + a2 b2) + b1(a2^2 + a3^2 - a1^2)) e032 +
  ## (-2a2(a0 b0 + a1 b1 + a3 b3) + b2(a3^2 + a1^2 - a2^2)) e013 +
  ## (-2a3(a0 b0 + a2 b2 + a1 b1) + b3(a1^2 + a2^2 - a3^2)) e021
  let a_yxzy = a.yxzy
  let a_zyxz = a.zyxz

  p3 = (a.wwww * b.wwww) + (a_yxzy * b.wxzy) + (a_zyxz * b.wyxz)
  p3 = p3 * a * mm_set_ps(-2'f32, -2'f32, -2'f32, 0'f32)

  let a_wyzw = a.xzyx
  p3 = p3 + b * (sqsum(a_zyxz, a_yxzy) - flipw(a_wyzw * a_wyzw))

func sw02*(a, b: m128): m128 {.inline.} =
  ## Apply a translator to a plane.
  ## Assumes e0123 component of p2 is exactly 0
  ## p0: (e0, e1, e2, e3)
  ## p2: (e0123, e01, e02, e03)
  ## b * a * ~b
  ## 
  ## The low component of p2 is expected to be the scalar component instead
  ## (a0 b0^2 + 2a1 b0 b1 + 2a2 b0 b2 + 2a3 b0 b3) e0 +
  ## (a1 b0^2) e1 + (a2 b0^2) e2 + (a3 b0^2) e3
  ##
  ## Because the plane is projectively equivalent on multiplication by a
  ## scalar, we can divide the result through by b0^2
  ##
  ## (a0 + 2a1 b1 / b0 + 2a2 b2 / b0 + 2a3 b3 / b0) e0 +
  ## a1 e1 + a2 e2 + a3 e3
  ##
  ## The additive term clearly contains a dot product between the plane's
  ## normal and the translation axis, demonstrating that the plane
  ## "doesn't care" about translations along its span. More precisely, the
  ## plane translates by the projection of the translator on the plane's
  ## normal.
  var inv_b = rcp_nr1(b)
  ## 2 / b0
  inv_b = mm_add_ss(inv_b, inv_b) & mm_castsi128_ps(mm_set_epi32(0, 0, 0, -1))
  ## (a1*b1 + a2*b2 + a3*b3 in low component) * (2/b0) + plane
  mm_mul_ss(hi_dp(a, b), inv_b) + a

func swL2*(a, d, c: m128, p1, p2: var m128) {.inline.} =
  ## Apply a translator to a line
  ## a := p1 input
  ## d := p2 input
  ## c := p2 translator
  ## out points to the start address of a line (p1, p2)
  ## 
  ## a0 + a1 e23 + a2 e31 + a3 e12 +
  ## (2a0 c0 + d0) e0123 +
  ## (2(a2 c3 - a3 c2 - a1 c0) + d1) e01 +
  ## (2(a3 c1 - a1 c3 - a2 c0) + d2) e02 +
  ## (2(a1 c2 - a2 c1 - a3 c0) + d3) e03
  p1 = a
  ## Add and subtract the same in lowbits to cancel
  p2 = (a.wyxz * c.wxzy) - (a.wxzy * c.wyxz) - flipw(a * c.wwww)
  p2 = p2 + p2 + d

func sw32*(a, b: m128): m128 {.inline.} =
  ## Apply a translator to a point.
  ## Assumes e0123 component of p2 is exactly 0
  ## p2: (e0123, e01, e02, e03)
  ## p3: (e123, e032, e013, e021)
  ## b * a * ~b
  ## a0 e123 +
  ## (a1 - 2 a0 b1) e032 +
  ## (a2 - 2 a0 b2) e013 +
  ## (a3 - 2 a0 b3) e021
  (b * a.wwww) * (mm_set_ps(-2'f32, -2'f32, -2'f32, 0'f32)) + a

func swMM*(mIn: ptr m128, b: m128, cPtr, mOut: ptr m128,
           count: int=1, VARIADIC, TRANSLATE, INPUT_P2: static bool) {.inline.} =
  ## Apply a motor to a motor (works on lines as well)
  ## in points to the start of an array of motor inputs (alternating p1 and
  ## p2) out points to the start of an array of motor outputs (alternating p1
  ## and p2)
  ##
  ## Note: in and out are permitted to alias iff a == out.
  ##       VARIADIC implies TRANSLATE implies INPUT_P2
  ## 
  ## p1 block
  ## a0(b0^2 + b1^2 + b2^2 + b3^2) +
  ## (a1(b1^2 + b0^2 - b3^2 - b2^2) +
  ##     2a2(b0 b3 + b1 b2) + 2a3(b1 b3 - b0 b2)) e23 +
  ## (a2(b2^2 + b0^2 - b1^2 - b3^2) +
  ##     2a3(b0 b1 + b2 b3) + 2a1(b2 b1 - b0 b3)) e31
  ## (a3(b3^2 + b0^2 - b2^2 - b1^2) +
  ##     2a1(b0 b2 + b3 b1) + 2a2(b3 b2 - b0 b1)) e12 +
  let b_xwyz   = b.wxzy
  let b_wyxz   = b.wyxz
  let b_zwww   = b.zwww

  let tmp = sqsum(b, b_zwww) - flipw(sqsum(b.yxzy, b.xyxz))
  ## tmp needs to be scaled by a and set to p1

  let b_xxxx = b.wwww
  let scale  = mm_set_ps(2'f32, 2'f32, 2'f32, 0'f32)
  let tmp2   = ((b_xxxx * b_xwyz) + (b * b_wyxz)) * scale
  ## tmp2 needs to be scaled by (a0, a2, a3, a1) and added to p1

  let tmp3 = ((b * b_xwyz) - (b_xxxx * b_wyxz)) * scale
  ## tmp3 needs to be scaled by (a0, a3, a1, a2) and added to p1

  ## p2 block
  ## (d coefficients are the components of the input line p2)
  ## (2a0(b0 c0 - b1 c1 - b2 c2 - b3 c3) +
  ##  d0(b1^2 + b0^2 + b2^2 + b3^2)) e0123 +
  ##
  ## (2a1(b1 c1 - b0 c0 - b3 c3 - b2 c2) +
  ##  2a3(b1 c3 + b2 c0 + b3 c1 - b0 c2) +
  ##  2a2(b1 c2 + b0 c3 + b2 c1 - b3 c0) +
  ##  2d2(b0 b3 + b2 b1) +
  ##  2d3(b1 b3 - b0 b2) +
  ##  d1(b0^2 + b1^2 - b3^2 - b2^2)) e01 +
  ##
  ## (2a2(b2 c2 - b0 c0 - b3 c3 - b1 c1) +
  ##  2a1(b2 c1 + b3 c0 + b1 c2 - b0 c3) +
  ##  2a3(b2 c3 + b0 c1 + b3 c2 - b1 c0) +
  ##  2d3(b0 b1 + b3 b2) +
  ##  2d1(b2 b1 - b0 b3) +
  ##  d2(b0^2 + b2^2 - b1^2 - b3^2)) e02 +
  ##
  ## (2a3(b3 c3 - b0 c0 - b1 c1 - b2 c2) +
  ##  2a2(b3 c2 + b1 c0 + b2 c3 - b0 c1) +
  ##  2a1(b3 c1 + b0 c2 + b1 c3 - b2 c0) +
  ##  2d1(b0 b2 + b1 b3) +
  ##  2d2(b3 b2 - b0 b1) +
  ##  d3(b0^2 + b3^2 - b2^2 - b1^2)) e03

  ## Rotation

  ## tmp scaled by d and added to p2
  ## tmp2 scaled by (d0, d2, d3, d1) and added to p2
  ## tmp3 scaled by (d0, d3, d1, d2) and added to p2
  when TRANSLATE:
    ## Translation
    let c = cPtr[]
    let c_wwww  = c.wwww
    let c_xzwy = c.wyxz
    let c_xwyz = c.wxzy

    ## scaled by a and added to p2
    var tmp4 = (b * c) -
      (b_zwww * c.zwww) -
      (b.yxxz * c.yxxz) -
      (b.xyzy * c.xyzy)
    tmp4 = tmp4 + tmp4

    ## scaled by (a0, a3, a1, a2), added to p2
    let tmp5 = ((b * c_xwyz) +
                (b_wyxz * c_wwww) +
                (b_xwyz * c) -
                (b_xxxx * c_xzwy)) * scale

    ## scaled by (a0, a2, a3, a1), added to p2
    let tmp6 = ((b * c_xzwy) +
                (b_xxxx * c_xwyz) +
                (b_wyxz * c) -
                (b_xwyz * c_wwww)) * scale

  let limit = when VARIADIC: count else: 1
  let stride = when INPUT_p2: 2 else: 1
  for i in 0..<limit:
    let p1_in = (mIn + stride * i)[]
    let p1_in_xzwy = p1_in.wyxz
    let p1_in_xwyz = p1_in.wxzy
    (mOut+i*stride)[] = (tmp * p1_in) + (tmp2 * p1_in_xzwy) + (tmp3 * p1_in_xwyz)

    when INPUT_P2:
      let p2_in = (mIn + stride * i + 1)[]
      (mOut+i*stride + 1)[] = (tmp * p2_in) + (tmp2 * p2_in.wyxz) + (tmp3 * p2_in.wxzy)

    when TRANSLATE:
      assert INPUT_P2
      (mOut+i*stride+1)[] = (mOut+i*stride+1)[] + (tmp4 * p1_in) + (tmp5 * p1_in_xwyz) + (tmp6 * p1_in_xzwy)

func sw012*(a: ptr m128, b: m128, c: ptr m128, mOut: ptr m128,
            count: int=1, VARIADIC: static bool=false, TRANSLATE: static bool=true) {.inline.} =
  ## Apply a motor to a plane
  ## a := p0
  ## b := p1
  ## c := p2
  ## If Translate is false, c is ignored (rotor application).
  ## If Variadic is true, a and out must point to a contiguous block of memory
  ## equivalent to _m128[count]
  ## 
  ## LSB
  ##
  ## (2a3(b0 c3 + b1 c2 + b3 c0 - b2 c1) +
  ##  2a2(b0 c2 + b3 c1 + b2 c0 - b1 c3) +
  ##  2a1(b0 c1 + b2 c3 + b1 c0 - b3 c2) +
  ##  a0 (b2^2 + b1^2 + b0^2 + b3^2)) e0 +
  ##
  ## (2a2(b0 b3 + b2 b1) +
  ##  2a3(b1 b3 - b0 b2) +
  ##  a1 (b0^2 + b1^2 - b3^2 - b2^2)) e1 +
  ##
  ## (2a3(b0 b1 + b3 b2) +
  ##  2a1(b2 b1 - b0 b3) +
  ##  a2 (b0^2 + b2^2 - b1^2 - b3^2)) e2 +
  ##
  ## (2a1(b0 b2 + b1 b3) +
  ##  2a2(b3 b2 - b0 b1) +
  ##  a3 (b0^2 + b3^2 - b2^2 - b1^2)) e3
  ##
  ## MSB
  ##
  ## Note the similarity between the results here and the rotor and
  ## translator applied to the plane. The e1, e2, and e3 components do not
  ## participate in the translation and are identical to the result after
  ## the rotor was applied to the plane. The e0 component is displaced
  ## similarly to the manner in which it is displaced after application of
  ## a translator.

  ## Double-cover scale
  let dc_scale = mm_set_ps(2'f32, 2'f32, 2'f32, 1'f32)
  let b_xwyz   = b.wxzy
  let b_wyxz   = b.wyxz
  let b_xxxx   = b.wwww

  ## Scale later with (a0, a2, a3, a1)
  let tmp1 =  (b.ywww * b.yxzy)
    .mm_add_ps(b.zyxz * b.zzyx)
    .mm_mul_ps(dc_scale)

  ## Scale later with (a0, a3, a1, a2)
  let tmp2 = (b * b_xwyz)
    .mm_sub_ps(flipw(b.xwww * b.xyxz))
    .mm_mul_ps(dc_scale)

  ## Alternately add and subtract to improve low component stability
  ## Scale later with a
  let tmp3 = (b * b)
    .mm_sub_ps(b_xwyz * b_xwyz)
    .mm_add_ps(b_xxxx * b_xxxx)
    .mm_sub_ps(b_wyxz * b_wyxz)

  ## Compute
  ## 0 * _ +
  ## 2a1(b0 c1 + b2 c3 + b1 c0 - b3 c2) +
  ## 2a2(b0 c2 + b3 c1 + b2 c0 - b1 c3) +
  ## 2a3(b0 c3 + b1 c2 + b3 c0 - b2 c1)
  ## by decomposing into four vectors, factoring out the a components

  when TRANSLATE:
    var tmp4 = (b_xxxx * c[])
      .mm_add_ps(c[].wxzy * b_wyxz)
      .mm_add_ps(c[].wwww * b)
      .mm_sub_ps(c[].wyxz * b_xwyz)
      .mm_mul_ps(dc_scale)

  ## The temporaries (tmp1, tmp2, tmp3, tmp4) strictly only depend on b and c.
  let limit = when VARIADIC: count else: 1
  for i in 0..<limit:
    ## Compute the lower block for components e1, e2, and e3
    let ai = (a+i)[]
    (mOut+i)[] = (tmp1 * ai.wyxz)
      .mm_add_ps(tmp2 * ai.wxzy)
      .mm_add_ps(tmp3 * ai)

    when TRANSLATE:
      (mOut+i)[] = (mOut+i)[] + hi_dp(tmp4, ai)

func sw312*(a: ptr m128, b: m128, c, mOut: ptr m128,
            count: int=1, VARIADIC, TRANSLATE: static bool) {.inline.} =
  ## Apply a motor to a point
  ## LSB
  ## a0(b1^2 + b0^2 + b2^2 + b3^2) e123 +
  ##
  ## (2a0(b2 c3 - b0 c1 - b3 c2 - b1 c0) +
  ##  2a3(b1 b3 - b0 b2) +
  ##  2a2(b0 b3 +  b2 b1) +
  ##  a1(b0^2 + b1^2 - b3^2 - b2^2)) e032
  ##
  ## (2a0(b3 c1 - b0 c2 - b1 c3 - b2 c0) +
  ##  2a1(b2 b1 - b0 b3) +
  ##  2a3(b0 b1 + b3 b2) +
  ##  a2(b0^2 + b2^2 - b1^2 - b3^2)) e013 +
  ##
  ## (2a0(b1 c2 - b0 c3 - b2 c1 - b3 c0) +
  ##  2a2(b3 b2 - b0 b1) +
  ##  2a1(b0 b2 + b1 b3) +
  ##  a3(b0^2 + b3^2 - b2^2 - b1^2)) e021 +
  ## MSB
  ##
  ## Sanity check: For c1 = c2 = c3 = 0, the computation becomes
  ## indistinguishable from a rotor application and the homogeneous
  ## coordinate a0 does not participate. As an additional sanity check,
  ## note that for a normalized rotor and homogenous point, the e123
  ## component will remain unity.
  let two    = mm_set_ps(2'f32, 2'f32, 2'f32, 0'f32)
  let b_xxxx = b.wwww
  let b_xwyz = b.wxzy
  let b_wyxz = b.wyxz

  ## tmp1 needs to be scaled by (_, a3, a1, a2)
  let tmp1 = ((b * b_xwyz) - (b_xxxx * b_wyxz)) * two
  ## tmp2 needs to be scaled by (_, a2, a3, a1)
  let tmp2 = ((b_xxxx * b_xwyz) + (b_wyxz * b)) * two

  ## tmp3 needs to be scaled by (a0, a1, a2, a3)
  ## BUG (changed from klein order - check asm optimization if becomes issue)
  let tmp3 = sqsum(b, b.zwww) -
    flipw(sqsum(b.yxzy, b.xyxz))

  when TRANSLATE:
    let tmp4 = (b_wyxz * c[].wxzy)
      .mm_sub_ps(c[] * b_xxxx)
      .mm_sub_ps(c[].wyxz * b_xwyz)
      .mm_sub_ps(c[].wwww * b)
      .mm_mul_ps(two)
    ## Mask low component and scale other components by 2

    ## tmp4 needs to be scaled by (_, a0, a0, a0)

  let limit = when VARIADIC: count else: 1
  for i in 0..<limit:
    let ai = (a+i)[]
    (mOut+i)[] = (tmp1 * ai.wxzy)
       .mm_add_ps(tmp2 * ai.wyxz)
       .mm_add_ps(tmp3 * ai)

    when TRANSLATE:
      (mOut+i)[] = (mOut+i)[] + (tmp4 * ai.wwww)

func swo12*(b, c: m128, p3: var m128) {.inline.} =
  ## Conjugate origin with motor. Unlike other operations the motor MUST be
  ## normalized prior to usage b is the rotor component (p1) c is the
  ## translator component (p2)
  ## 
  ##  (b0^2 + b1^2 + b2^2 + b3^2) e123 +
  ## 2(b2 c3 - b1 c0 - b0 c1 - b3 c2) e032 +
  ## 2(b3 c1 - b2 c0 - b0 c2 - b1 c3) e013 +
  ## 2(b1 c2 - b3 c0 - b0 c3 - b2 c1) e021
  let tmp = (c.wwww * b)
    .mm_add_ps(b.wwww * c)
    .mm_add_ps(b.wxzy * c.wyxz)
  p3 = (b.wyxz * c.wxzy)
    .mm_sub_ps(tmp)
    .mm_mul_ps(mm_set_ps(2'f32, 2'f32, 2'f32, 0'f32))
    .mm_add_ps(mm_set_ss(1'f32))
  ## b0^2 + b1^2 + b2^2 + b3^2 assumed to equal 1
  ## Set the low component to unity

