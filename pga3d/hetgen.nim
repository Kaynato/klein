#[
  Generation of types between different types

  Includes some semantic shortcuts for sqrt(dst/src) convention
]#

import math
import ./types
import ./arithmetic
import ./plane
import ./point
import ./line
import ./slider
import ./rotor
import ./motor
import ./products
import ./hetops
import ./exp_log
import ./access
import ../utils
import ../backend/[laser, ops, geometric_product, symoperator]


func newRotor*(axis: Direction, radians: float32): Rotor =
  ## Construct a rotor from the angle-direction representation.
  ## Assumes the axis is already normalized
  let halfang = 0.5 * radians
  let scale = math.sin(halfang)
  var w = math.cos(halfang).float32
  result.p1 = (axis.p3 * mm_set1_ps(scale)) + mm_load_ss(w.addr)


func newSlider*[T: SomeNumber](axis: Direction, delta: T): Slider =
  ## Construct a slider as a displacement along a normalized axis
  let v = -delta.float32 * 0.5'f32
  Slider(p2: mm_set_ps(v, v, v, 0'f32) * axis.p3)


func sliderTo*(src, dst: Point, raw: static[bool]=false): Slider {.inline.} =
  when raw: sqrt(dst/src)
  else    : sqrt(dst.normalized/src.normalized)

func sliderToOrigin*(src: Point): Slider =
  newSlider(src.p3 * mm_set_ps(0.5'f32, 0.5'f32, 0.5'f32, 0.0f))


func rotorTo*(src, dst: Branch, raw: static[bool]=false): Rotor {.inline.} =
  when raw: sqrt(dst/src)
  else    : sqrt(dst.normalized/src.normalized)

# RotorTo direction all of form:
# let p1 = flipw((a.yzyx * b.ywww) + (a.xxzy * b.xyxz)) - (a.zyxz * b.zxzy)

func rotorToY*(src: Branch, minus: static[bool]=false): Rotor =
  ## Rotor to Y. Optimized significantly for the special case.
  # [-y -x +w +z]
  let flip =
    when minus: mm_set_ps(-0'f32, -0'f32,  0'f32,  0'f32)
    else      : mm_set_ps( 0'f32,  0'f32, -0'f32, -0'f32)
  src.normalized.inverse.p1.yxwz.mm_xor_ps(flip).newRotor.sqrt

func rotorToZ*(src: Branch, minus: static[bool]=false): Rotor =
  ## Rotor to Z. Optimized significantly for the special case.
  ## For some reason the mapping is wxyz. So 1 is on x, not z. Weird.
  let flip =
    when minus: mm_set_ps(-0'f32,  0'f32, -0'f32,  0'f32)
    else      : mm_set_ps( 0'f32, -0'f32,  0'f32, -0'f32)
  # normal: [-x +y -z +w]
  # flip  : [+x -y +z -w]
  src.normalized.inverse.p1.xyzw.mm_xor_ps(flip).newRotor.sqrt

func rotorToX*(src: Branch, minus: static[bool]=false): Rotor =
  ## Rotor to X. Optimized significantly for the special case.
  ## For some reason the mapping is wxyz. So 1 is on z, not x. Weird.
  let flip =
    when minus: mm_set_ps( 0'f32, -0'f32, -0'f32,  0'f32)
    else      : mm_set_ps(-0'f32,  0'f32,  0'f32, -0'f32)
  # normal: [-z +w +x -y]
  src.normalized.inverse.p1.zwxy.mm_xor_ps(flip).newRotor.sqrt


func motorTo*(src, dst: Plane | Line, raw: static[bool]=false): Motor {.inline.} =
  when raw: sqrt(dst/src)
  else    : sqrt(dst.normalized/src.normalized)




if isMainModule:

  var s1 = newSlider(4'f32, 1, 0, -5)
  var s2 = newDirection(1, 0, -5).newSlider(4)
  
  doAssert (s1 - s2).p2.toArray().sum() < 1e-6

  echo newDirection(0, 0, -5).newSlider(5)
  echo newDirection(0, 0, 5).newSlider(-5)
  echo newDirection(0, 0, 1).newSlider(-5)
  echo Direction.Z.newSlider(-5)

  let b1 = newBranch(3, 6, 1)
  echo b1.rotate(b1.rotorToZ())
  echo b1.rotate(b1.rotorToZ(minus=true))
  echo b1.rotate(b1.rotorToY())
  echo b1.rotate(b1.rotorToY(minus=true))
  echo b1.rotate(b1.rotorToX())
  echo b1.rotate(b1.rotorToX(minus=true))
  # echo b1.rotate(b1.rotorToY(minus=true))
