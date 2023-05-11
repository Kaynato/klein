import ./types
import ../backend/laser

# Internal accessors for generalizing some functions

template xmm*(a: Plane    ): m128 = a.p0

template xmm*(a: Rotor    ): m128 = a.p1
template xmm*(a: Branch   ): m128 = a.p1

template xmm*(a: Slider   ): m128 = a.p2
template xmm*(a: IdealLine): m128 = a.p2

template xmm*(a: Point    ): m128 = a.p3
template xmm*(a: Direction): m128 = a.p3

type
  SingleXmm* = concept x
    x.xmm is m128

