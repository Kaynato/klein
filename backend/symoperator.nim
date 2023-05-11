## Symbolic operators for ease of using SSE ops
## 
## Do not use in ambiguous contexts.
## Meant for use only where most (or all) operations are SSE operations.
import ./laser

# template mm_load_ps*(aligned_mem_addr: ptr float32): m128 = mm_load_ps(a, b)
# template mm_loadu_ps*(data: ptr float32): m128 = mm_loadu_ps(a, b)
# template mm_store_ps*(mem_addr: ptr float32, a: m128) = mm_store_ps(a, b)
# template mm_storeu_ps*(mem_addr: ptr float32, a: m128) = mm_storeu_ps(a, b)
template `+`*(a, b: m128): m128 = mm_add_ps(a, b)
template `-`*(a, b: m128): m128 = mm_sub_ps(a, b)
template `*`*(a, b: m128): m128 = mm_mul_ps(a, b)
# template mm_max_ps*(a, b: m128): m128 = mm_max_ps(a, b)
# template mm_min_ps*(a, b: m128): m128 = mm_min_ps(a, b)
template `&`*(a, b: m128): m128 = mm_and_ps(a, b)
template `|`*(a, b: m128): m128 = mm_or_ps(a, b)
template `xor`*(a, b: m128): m128 = mm_xor_ps(a, b)

# template mm_set_ps*(d, c, b, a: float32): m128 = mm_set_ps(a, b)
template sqrt*(a: m128): m128 = mm_sqrt_ps(a)
template rsqrt*(a: m128): m128 = mm_rsqrt_ps(a)
# template mm_movemask_ps*(a: m128): uint8 = mm_movemask_ps(a, b)
template `==`*(a, b: m128): m128 = mm_cmpeq_ps(a, b)
template `~&`*(a, b: m128): m128 = mm_andnot_ps(a, b)
template `<`*(a, b: m128): m128 = mm_cmplt_ps(a, b)

template flipw*(a: m128): m128 = mm_xor_ps(a, mm_set_ss(-0'f32))
template `-`*(a: m128): m128 = mm_xor_ps(a, mm_set1_ps(-0'f32))


  
