## Accessors: Get and set
import std/strformat

import ./types
import ./internal_access
import ../backend/laser

# ===== Setters
func set*(p: var Plane, data: array[4, float32]) {.inline.} =
  p.p0 = mm_loadu_ps(data[0].unsafeAddr)
  ## Fast unaligned load data. Data should point to (d, a, b, c) order!

func set*(p: var Point, data: array[4, float32]) {.inline.} =
  p.p3 = mm_loadu_ps(data[0].unsafeAddr)
  ## Fast unaligned load data. Data should point to (z, y, x, 1) order!

func set_normalized*(p: var Rotor, data: array[4, float32]) {.inline.} =
  p.p1 = mm_loadu_ps(data[0].unsafeAddr)
  ## Fast load operation for rotor. The data MUST be already normalized.
  ## Layout should be (a, b, c, d) for `a + b e23 + c e31 + d e12`

func set_normalized*(p: var Slider, data: array[4, float32]) {.inline.} =
  p.p2 = mm_loadu_ps(data[0].unsafeAddr)
  ## Fast load operation for slider. The data MUST be already normalized.
  ## Layout should be (0, a, b, c) for `a e01 b e02 c e03`

func set_normalized*(m: var Motor, a: array[8, float32]) {.inline.} =
  ## Unaligned load for Motor
  m.p1 = mm_loadu_ps(a[0].unsafeAddr)
  m.p2 = mm_loadu_ps(a[3].unsafeAddr)

# ===== Getters
type
  Has_p0 = concept a
    a.p0 is m128
  Has_p1 = concept a
    a.p1 is m128
  Has_p2 = concept a
    a.p2 is m128
  Has_p3 = concept a
    a.p3 is m128

func store*(xmm: m128): array[4, float32] {.inline.} =
  mm_store_ps(result[0].addr, xmm)

func store0*(xmm: m128): float32 {.inline.} =
  mm_store_ss(result.addr, xmm)

##       LSB =================== MSB
##   p0:     e0   e1   e2   e3      
##   p1:     1    e23  e31  e12    
##   p2:     I    e03  e02  e01        
##   p3:     e123 e032 e013 e021      
##                x    y    z

template e0*(a: Has_p0): float32 = store0(a.p0)
template e1*(a: Has_p0): float32 = store(a.p0)[1]
template e2*(a: Has_p0): float32 = store(a.p0)[2]
template e3*(a: Has_p0): float32 = store(a.p0)[3]

template e*(a: Has_p1): float32 = store0(a.p1)
template e23*(a: Has_p1): float32 = store(a.p1)[1]
template e31*(a: Has_p1): float32 = store(a.p1)[2]
template e12*(a: Has_p1): float32 = store(a.p1)[3]

template e0123*(a: Has_p2): float32 = store0(a.p2)
template e01*(a: Has_p2): float32 = store(a.p2)[1]
template e02*(a: Has_p2): float32 = store(a.p2)[2]
template e03*(a: Has_p2): float32 = store(a.p2)[3]

template e123*(a: Has_p3): float32 = store0(a.p3)
template e032*(a: Has_p3): float32 = store(a.p3)[1]
template e013*(a: Has_p3): float32 = store(a.p3)[2]
template e021*(a: Has_p3): float32 = store(a.p3)[3]

# Alternates
template e32*(a: Has_p1): float32 = -a.e23
template e13*(a: Has_p1): float32 = -a.e31
template e21*(a: Has_p1): float32 = -a.e12

template e10*(a: Has_p2): float32 = -a.e01
template e20*(a: Has_p2): float32 = -a.e02
template e30*(a: Has_p2): float32 = -a.e03

# ===== Additional Aliases
template pseudoscalar*(a: Has_p2): float32 = store0(a.p2)
template scalar*(a: Has_p1): float32 = store0(a.p1)

template d*(a: Plane): float32 = a.e0
template x*(a: Plane): float32 = a.e1
template y*(a: Plane): float32 = a.e2
template z*(a: Plane): float32 = a.e3

template x*(a: Point): float32 = a.e032
template y*(a: Point): float32 = a.e013
template z*(a: Point): float32 = a.e021
template w*(a: Point): float32 = a.e123

template x*(a: Branch): float32 = a.e23
template y*(a: Branch): float32 = a.e31
template z*(a: Branch): float32 = a.e12

template scalar*(a: Slider): float32 = 1'f32

template scalar*(a: Dual): float32 = a.p
template pseudoscalar*(a: Dual): float32 = a.q
template e0123*(a: Dual): float32 = a.q

# ===== Storage
template store*(a: SingleXmm): array[4, float32] = store(a.xmm)

# ===== Strings
func `$`*(x: Plane): string =
  ## ax + by + cz = d
  let arr = x.store()
  &"Plane(x: {arr[1]}, y: {arr[2]}, z: {arr[3]}, d: {arr[0]})"

func `$`*(x: Line): string =
  ## Plucker coordinates
  let d = x.p1.store() # Displacement along line
  let m = x.p2.store() # Moment
  &"Line(dx: {d[1]}, dy: {d[2]}, dz: {d[3]}; mx: {m[1]}, my: {m[2]}, mz: {m[3]}, p: {d[0]}, q: {m[0]})"

func `$`*(x: Point): string =
  let arr = x.store()
  &"Point(x: {arr[1]}, y: {arr[2]}, z: {arr[3]}, w: {arr[0]})"

func `$`*(x: Branch): string =
  let arr = x.store()
  &"Branch(x: {arr[1]}, y: {arr[2]}, z: {arr[3]})"

func `$`*(x: Rotor): string =
  let arr = x.store()
  &"Rotor(x: {arr[1]}, y: {arr[2]}, z: {arr[3]}, w: {arr[0]})"

func `$`*(x: Slider): string =
  let arr = x.store()
  &"Slider(x: {arr[1]}, y: {arr[2]}, z: {arr[3]}, d: {arr[0]})"


# ===== Human Representations?
# Convert to typical constructors, e.g. axis-angle rotor, etc.