import ../backend/laser
import ../backend/ops
import ../backend/symoperator

template toMat4x4_m123_Impl(b: m128, m: var array[4, m128]): untyped {.dirty.} =
  ## Store a number of scalar temporaries needed later
  let arr = (b * b).toArray
  let b0_2 = arr[0]
  let b1_2 = arr[1]
  let b2_2 = arr[2]
  let b3_2 = arr[3]
  
  ## The first column of the matrix we need to produce contains the scale
  ## factors of the x-coordinate (a1). This can be read off as:
  ##
  ## b0^2 + b1^2 - b3^2 - b2^2
  ## 2(b1 b2 - b3 b0)
  ## 2(b2 b0 + b1 b3)
  ## 0
  m[0] = (b.zxzw * b.zwxw) 
    .mm_xor_ps(mm_set_ps(0'f32, 0'f32, -0'f32, 0'f32))
    .mm_add_ps(b * b.wyww)
    .mm_mul_ps(mm_set_ps(0'f32, 2'f32, 2'f32, 1'f32))
    .mm_sub_ps(mm_set_ss(b3_2 + b2_2))

  ## We can perform the same exercise for y (a2) (the second column):
  ##
  ## 2(b0 b3 + b2 b1)
  ## (-b1^2 - b3^2 + b0^2 + b2^2)
  ## 2(b2 b3 - b0 b1)
  ## 0
  m[1] = (b.yxww * b.zxzw)
    .mm_xor_ps(mm_set_ps(0'f32, -0'f32, 0'f32, 0'f32))
    .mm_add_ps(b * b.xzxw)
    .mm_mul_ps(mm_set_ps(0'f32, 2'f32, -1'f32, 2'f32))
    .mm_add_ps(mm_set_ps(0'f32, 0'f32, b0_2 + b2_2, 0'f32))

  ## z (a3)
  ##
  ## 2(-b0 b2 + b1 b3)
  ## 2(b1 b0 + b2 b3)
  ## (-b2^2 + b0^2 + b3^2 - b1^2)
  ## 0
  m[2] = (b.wywy * b)
    .mm_xor_ps(mm_set_ps(0'f32, -0'f32, 0'f32, -0'f32))
    .mm_add_ps(b.zyww * b.xxww)
    .mm_mul_ps(mm_set_ps(0'f32, 1'f32, 2'f32, 2'f32))
    .mm_add_ps(mm_set_ps(0'f32, b3_2 - b1_2, 0'f32, 0'f32))


template toMat4x4_12_tr*(b, c: m128, m: var array[4, m128],
  NORMALIZED: static bool) =
  ## The derivation of this conversion follows directly from the general
  ## expansion of conjugating a point with a motor. See sw312 in
  ## klein_sw.hpp for details.
  ## 
  ## This version includes translation with c.
  ##
  ## LSB
  ## (2a0(b2 c3 - b0 c1 - b3 c2 - b1 c0) +
  ##  2a3(b1 b3 - b0 b2) +
  ##  2a2(b0 b3 + b2 b1) +
  ##  a1(b0^2 + b1^2 - b3^2 - b2^2)) e032 ## x-coordinate
  ##
  ## (2a0(b3 c1 - b0 c2 - b1 c3 - b2 c0) +
  ##  2a1(b2 b1 - b0 b3) +
  ##  2a3(b0 b1 + b3 b2) +
  ##  a2(b0^2 + b2^2 - b1^2 - b3^2)) e013 + ## y-coordinate
  ##
  ## (2a0(b1 c2 - b0 c3 - b2 c1 - b3 c0) +
  ##  2a2(b3 b2 - b0 b1) +
  ##  2a1(b0 b2 + b1 b3) +
  ##  a3(b0^2 + b3^2 - b2^2 - b1^2)) e021 + ## z-coordinate
  ##
  ## a0(b0^2 + b1^2 + b2^2 + b3^2) e123 ## w-coordinate
  ## MSB
  toMat4x4_m123_Impl(b, m)

  ## And finally w (a0)
  ##
  ## 2(b2 c3 - b0 c1 - b3 c2 - b1 c0)
  ## 2(b3 c1 - b1 c3 - b0 c2 - b2 c0)
  ## 2(b1 c2 - b2 c1 - b0 c3 - b3 c0)
  ## b0^2 + b1^2 + b2^2 + b3^2
  let tmp = (c.zxzw * b)
    .mm_add_ps(b.xwww * c.yyxw)
    .mm_add_ps(b.zyxw * c.wwww)

  m[3] = (b.yxzw * c.xzyw)
    .mm_sub_ps(tmp)
    .mm_mul_ps(mm_set_ps(0'f32, 2'f32, 2'f32, 2'f32))

  let blend_lsb =
    when NORMALIZED: 1'f32
    else:
      let b2 = (b * b).toArray()
      b2[0] + b2[1] + b2[2] + b2[3]
  m[3] = mm_blend_ps(m[3], mm_set_ps(blend_lsb, 0'f32, 0'f32, 0'f32), 0b1000'u8)


template toMat4x4_12*(b: m128, m: var array[4, m128], NORMALIZED: static bool) =
  ## toMat4x4_12 as the translation-less case
  ##   so we prevent exposure of the optional `c` argument.
  toMat4x4_m123_Impl(b, m)
  let blend_lsb =
    when NORMALIZED: 1'f32
    else:
      let b2 = (b * b).toArray()
      b2[0] + b2[1] + b2[2] + b2[3]
  m[3] = mm_blend_ps(m[3], mm_set_ps(blend_lsb, 0'f32, 0'f32, 0'f32), 0b1000'u8)
