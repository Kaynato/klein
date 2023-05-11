## Fast special basic operations with SSE
## Ported from klein

# TODO test me in wandbox
import ./laser
import ./symoperator
export laser

{.passC: "-msse4.1".}
# TODO We could try to detect and have a fallback? I guess???

template hi_dp   *(a, b: m128): m128 = mm_dp_ps(a, b, 0b11100001)
template hi_dp_bc*(a, b: m128): m128 = mm_dp_ps(a, b, 0b11101111)
template dp      *(a, b: m128): m128 = mm_dp_ps(a, b, 0b11110001)
template dp_bc   *(a, b: m128): m128 = mm_dp_ps(a, b, 0xff)

# End of sse4.1 part

template toArray*(a: m128): array[4, float32] =
  var arr: array[4, float32]
  mm_storeu_ps(cast[ptr float32](arr.addr), a)
  arr

template eq*(a, b: m128): bool =
  ## Test for numeric equality
  a.mm_cmpeq_ps(b).mm_movemask_ps() == 0b1111'u8

func approx_eq*(a, b: m128, eps: float32): bool {.inline.} = 
  ## Approx equal
  mm_sub_ps(a, b)
    .mm_andnot_ps(mm_set1_ps(-0'f32))
    .mm_cmplt_ps(mm_set1_ps(eps))
    .mm_movemask_ps() == 0b1111'u8

template sqsum*(a, b: m128): m128 =
  (a * a) + (b * b)

template shuffle_mask*(w, z, y, x: static uint32): uint8 =
  (w shl 6) or (z shl 4) or (y shl 2) or x

template swizzle*(xmm: m128, w, z, y, x: static uint32): m128 =
  ## Little-endian XMM register swizzle
  ## swizzle(xmm, 3, 2, 1, 0) is the identity
  mm_shuffle_ps(xmm, xmm, shuffle_mask(w, z, y, x))

# You know, I could overload the dot operator, maybe? Maybe?
# wzyx order for more appropriate matching with actual internal data rep
template wwww*(xmm: m128): m128 = xmm.swizzle(0, 0, 0, 0)
template zwww*(xmm: m128): m128 = xmm.swizzle(0, 0, 0, 1)
template ywww*(xmm: m128): m128 = xmm.swizzle(0, 0, 0, 2)
template xwww*(xmm: m128): m128 = xmm.swizzle(0, 0, 0, 3)

template wyww*(xmm: m128): m128 = xmm.swizzle(0, 0, 2, 0)
template zyww*(xmm: m128): m128 = xmm.swizzle(0, 0, 2, 1)
template yxww*(xmm: m128): m128 = xmm.swizzle(0, 0, 3, 2)
template xxww*(xmm: m128): m128 = xmm.swizzle(0, 0, 3, 3)
template wywy*(xmm: m128): m128 = xmm.swizzle(0, 2, 0, 2)
template xzyw*(xmm: m128): m128 = xmm.swizzle(0, 2, 1, 3)
template xyzw*(xmm: m128): m128 = xmm.swizzle(0, 1, 2, 3)
template zxzw*(xmm: m128): m128 = xmm.swizzle(0, 1, 3, 1)
template yxzw*(xmm: m128): m128 = xmm.swizzle(0, 1, 3, 2)
template zwxw*(xmm: m128): m128 = xmm.swizzle(0, 3, 0, 1)
template xzxw*(xmm: m128): m128 = xmm.swizzle(0, 3, 1, 3)
template zyxw*(xmm: m128): m128 = xmm.swizzle(0, 3, 2, 1)
template yyxw*(xmm: m128): m128 = xmm.swizzle(0, 3, 2, 2)

template zzzz*(xmm: m128): m128 = xmm.swizzle(1, 1, 1, 1)
template wyxz*(xmm: m128): m128 = xmm.swizzle(1, 3, 2, 0)
template zyxz*(xmm: m128): m128 = xmm.swizzle(1, 3, 2, 1)
template yyxz*(xmm: m128): m128 = xmm.swizzle(1, 3, 2, 2)
template xyxz*(xmm: m128): m128 = xmm.swizzle(1, 3, 2, 3)

template yxxz*(xmm: m128): m128 = xmm.swizzle(1, 3, 3, 2)
template yxwz*(xmm: m128): m128 = xmm.swizzle(1, 0, 3, 2)

template yyyy*(xmm: m128): m128 = xmm.swizzle(2, 2, 2, 2)
template xyzy*(xmm: m128): m128 = xmm.swizzle(2, 1, 2, 3)

template wxzy*(xmm: m128): m128 = xmm.swizzle(2, 1, 3, 0)
template zxzy*(xmm: m128): m128 = xmm.swizzle(2, 1, 3, 1)
template yxzy*(xmm: m128): m128 = xmm.swizzle(2, 1, 3, 2)
template xxzy*(xmm: m128): m128 = xmm.swizzle(2, 1, 3, 3)

template zwxy*(xmm: m128): m128 = xmm.swizzle(2, 3, 0, 1)
template zzxy*(xmm: m128): m128 = xmm.swizzle(2, 3, 1, 1)
template xzxy*(xmm: m128): m128 = xmm.swizzle(2, 3, 1, 3)

template xxxx*(xmm: m128): m128 = xmm.swizzle(3, 3, 3, 3)
template zyzx*(xmm: m128): m128 = xmm.swizzle(3, 1, 2, 1)
template xyzx*(xmm: m128): m128 = xmm.swizzle(3, 1, 2, 3)
template zzyx*(xmm: m128): m128 = xmm.swizzle(3, 2, 1, 1)
template yzyx*(xmm: m128): m128 = xmm.swizzle(3, 2, 1, 2)
template xzyx*(xmm: m128): m128 = xmm.swizzle(3, 2, 1, 3)


template hi_dp_ss*(a, b: m128): m128 =
  ## Dot-product high components and caller ignores high components
  let tmp = a * b
  let s = mm_movehdup_ps(tmp) + tmp
  let r = s + mm_unpacklo_ps(tmp, tmp)
  mm_movehl_ps(r, r)

template rcp_nr1*(a: m128): m128 =
  ## Reciprocal with one newton-raphson refinement
  ## 6 ops
  ## f(x) = 1/x - a
  ## f'(x) = -1/x^2
  ## x_{n+1} = x_n - f(x)/f'(x)
  ##         = 2x_n - a x_n^2
  ##         = x_n (2 - a x_n)
  ## ~2.7x baseline with ~22 bits of accuracy
  var res = mm_rcp_ps(a)
  res * (mm_set1_ps(2'f32) - (a * res))

  # var buf: array[4, float]

  # res = (res + res) - (a * res * res)
  # (res + res) - (a * res * res)

template rcp_nr*(a: m128, n: static int): m128 =
  ## Reciprocal with n newton-raphson refinements
  ## 7 ops, 13 ops, 19 ops - cycle might vary.
  ## 2 iterations is already good enough.
  var res = mm_rcp_ps(a)
  for _ in 1..n:
    res = (res + res) - (a * res * res)
  res

template rsqrt_nr1*(a: m128): m128 =
  ## Reciprocal sqrt with one newton-raphson refinement
  ## 
  ## f(x) = 1/x^2 - a
  ## f'(x) = -1/(2x^(3/2))
  ## Let x_n be the estimate, and x_{n+1} be the refinement
  ## x_{n+1} = x_n - f(x)/f'(x)
  ##         = 0.5 * x_n * (3 - a x_n^2)
  ## 
  ## From Intel optimization manual: expected performance is ~5.2x
  ## baseline (sqrtps + divps) with ~22 bits of accuracy
  let xn = mm_rsqrt_ps(a)
  mm_set1_ps(0.5'f32) * xn * (mm_set1_ps(3.0'f32) - (xn * xn * a))

template sqrt_nr1*(a: m128): m128 =
  ## Sqrt with one newton-raphson refinement. Computed from `nrsqrt_nr1`
  a.rsqrt_nr1().mm_mul_ps(a)

when isMainModule:
  func toArray(a: m128): array[4, float32] =
    mm_storeu_ps(cast[ptr float32](result.addr), a)

  let a = mm_set1_ps(4'f32)
  echo a.toArray

  let b1 = mm_rsqrt_ps(a)
  echo b1.toArray

  let b2 = rsqrt_nr1(a)
  echo b2.toArray

  let c = mm_sqrt_ps(a)
  echo c.toArray

  let d = hi_dp_bc(a, mm_set1_ps(2.3'f32))
  echo d.toArray

  let x = mm_set_ps(1'f, 2'f, 3'f, 4'f)
  echo x.toArray
  echo swizzle(x, 3, 2, 1, 0).toArray
  echo swizzle(x, 1, 1, 1, 1).toArray
  echo swizzle(x, 2, 3, 0, 1).toArray

