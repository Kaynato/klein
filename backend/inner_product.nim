import ./laser
import ./ops
import ./symoperator

func dot00*(a, b: m128, p1: var m128) {.inline.} =
  ## a1 b1 + a2 b2 + a3 b3
  p1 = hi_dp(a, b)

## The symmetric inner product on these two partitions commutes
func dot03*(a, b: m128, p1, p2: var m128) {.inline.} =
  ## (a2 b1 - a1 b2) e03 +
  ## (a3 b2 - a2 b3) e01 +
  ## (a1 b3 - a3 b1) e02 +
  ## a1 b0 e23 +
  ## a2 b0 e31 +
  ## a3 b0 e12
  p1 = (a * b.wwww)
    .mm_blend_ps(mm_setzero_ps(), 1'u8)
    .mm_and_ps(mm_castsi128_ps(mm_set_epi32(-1, -1, -1, 0)))
  p2 = ((b * a.wyxz) - (a * b.wyxz)).wyxz

func dot11*(a, b: m128, p1: var m128) {.inline.} =
  p1 = flipw(hi_dp_ss(a, b))
    

func dot33*(a, b: m128, p1: var m128) {.inline.} =
  ## -a0 b0
  p1 = mm_set_ss(-1'f32) * a * b
  

## Point | Line
func dotPTL*(a, b: m128, p0: var m128) {.inline.} =
  ## (a1 b1 + a2 b2 + a3 b3) e0 +
  ## -a0 b1 e1 +
  ## -a0 b2 e2 +
  ## -a0 b3 e3
  let dp = hi_dp_ss(a, b)
  p0 = a.wwww * b
  p0 = mm_xor_ps(p0, mm_set_ps(-0'f32, -0'f32, -0'f32, 0'f32))
  p0 = mm_blend_ps(p0, dp, 1)


## Plane | Ideal Line
func dotPIL*(a, c: m128, p0: var m128, FLIP: static bool) {.inline.} =
  p0 = hi_dp(a, c)
  when not FLIP:
    p0 = mm_xor_ps(p0, mm_set_ss(-0'f32))
    

## Plane | Line
func dotPL*(a, b, c: m128, p0: var m128, FLIP: static bool) {.inline.} =
  when FLIP:
    ## (a1 c1 + a2 c2 + a3 c3) e0 +
    ## (a1 b2 - a2 b1) e3
    ## (a2 b3 - a3 b2) e1 +
    ## (a3 b1 - a1 b3) e2 +
    p0 = (a * b.wyxz) - (a.wyxz * b)
    p0 = mm_add_ss(p0.wyxz, hi_dp_ss(a, c))
  else:
    ## -(a1 c1 + a2 c2 + a3 c3) e0 +
    ## (a2 b1 - a1 b2) e3
    ## (a3 b2 - a2 b3) e1 +
    ## (a1 b3 - a3 b1) e2 +
    p0 = (a.wyxz * b) - (a * b.wyxz)
    p0 = mm_sub_ss(p0.wyxz, hi_dp_ss(a, c))