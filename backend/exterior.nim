import ./laser
import ./ops
import ./symoperator

template ext00*(a, b: m128, p1, p2: var m128) =
  ## (a1 b2 - a2 b1) e12 +
  ## (a2 b3 - a3 b2) e23 +
  ## (a3 b1 - a1 b3) e31 +
  ## (a0 b1 - a1 b0) e01 +
  ## (a0 b2 - a2 b0) e02 +
  ## (a0 b3 - a3 b0) e03
  p1 = ((a * b.wyxz) - (b * a.wyxz)).wyxz
  p2 =  (b * a.wwww) - (a * b.wwww)
  ## For both outputs above, we don't zero the lowest component because
  ## we've arranged a cancelation

## Plane ^ Branch (branch is a line through the origin)
template extPB*(a, b: m128, p3: var m128) =
  ## (a1 b1 + a2 b2 + a3 b3) e123 +
  ## (-a0 b1) e032 +
  ## (-a0 b2) e013 +
  ## (-a0 b3) e021
  p3 = (a.zwww * b)
    .mm_mul_ps(mm_set_ps(-1'f32, -1'f32, -1'f32, 0'f32))
    .mm_add_ss(hi_dp(a, b))


## p0 ^ p2 = p2 ^ p0
template ext02*(a, b: m128, p3: var m128) =
  ## (a1 b2 - a2 b1) e021
  ## (a2 b3 - a3 b2) e032 +
  ## (a3 b1 - a1 b3) e013 +
  p3 = ((a * b.wyxz) - (a.wyxz * b)).wyxz

template ext03*(a, b: m128, p2: var m128, FLIP: static bool) =
  ## (a0 b0 + a1 b1 + a2 b2 + a3 b3) e0123
  p2 = dp(a, b)
  when FLIP:
    ## p0 ^ p3 = -p3 ^ p0
    ## The exterior products p2 ^ p2, p2 ^ p3, p3 ^ p2, and p3 ^ p3 all vanish
    p2 = flipw(p2)

