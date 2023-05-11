import ../../utils/copymacro # TODO should really put copymacro somewhere else, or use better codegen
import glm/vec

# Intializers. None of the dangerous "cross-init" stuff here please.
proc newVec2*(x, y: float32): Vec2f = vec2f(x, y)
proc newVec3*(x, y, z: float32): Vec3f = vec3f(x, y, z)
proc newVec4*(x, y, z, w: float32): Vec4f = vec4f(x, y, z, w)

proc newVec2*(x, y: int32): Vec2i = vec2i(x, y)
proc newVec3*(x, y, z: int32): Vec3i = vec3i(x, y, z)
proc newVec4*(x, y, z, w: int32): Vec4i = vec4i(x, y, z, w)

# QOL converters
DistributeSymbol(t, [float, int]):
  converter toVecf*(v: array[2, t]): Vec2f = vec2f(v[0].float32, v[1].float32)
  converter toVecf*(v: array[3, t]): Vec3f = vec3f(v[0].float32, v[1].float32, v[2].float32)
  converter toVecf*(v: array[4, t]): Vec4f = vec4f(v[0].float32, v[1].float32, v[2].float32, v[3].float32)