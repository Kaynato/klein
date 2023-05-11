## Test Sandwich and Reflect
from math import nil

import einheit

import ../pga3d
import ../compat
import ../backend/laser
import ../backend/pointerops
import ../backend/ops
import ../backend/sandwich

import ./m128_print

testSuite Sandwich:

  method testSimdSandwich() =
    let a = mm_set_ps(4'f32, 3'f32, 2'f32, 1'f32)
    let b = mm_set_ps(-1'f32, -2'f32, -3'f32, -4'f32)

    var ab: array[4, float32]
    mm_store_ps(ab[0].addr, sw02(a, b))

    self.check(ab[0] == 9'f32)
    self.check(ab[1] == 2'f32)
    self.check(ab[2] == 3'f32)
    self.check(ab[3] == 4'f32)

  method testReflectPlane() =
    let p1 = newPlane(3, 2, 1, -1)
    let p2 = newPlane(1, 2, -1, -3)
    let p3 = p2.reflect(p1)

    self.check(p3.e0 == 30'f32)
    self.check(p3.e1 == 22'f32)
    self.check(p3.e2 == -4'f32)
    self.check(p3.e3 == 26'f32)

  method testReflectLine() =
    let p = newPlane(3, 2, 1, -1)
    let l1 = newLine(1, -2, 3, 6, 5, -4)
    let l2 = l1.reflect(p)

    self.check(l2.e01 == 28'f32)
    self.check(l2.e02 == -72'f32)
    self.check(l2.e03 == 32'f32)

    self.check(l2.e12 == 104'f32)
    self.check(l2.e31 == 26'f32)
    self.check(l2.e23 == 60'f32)

  method testReflectPoint() =
    let plane = newPlane(3, 2, 1, -1)
    let point1 = newPoint(4, -2, -1)
    let point2 = point1.reflect(plane)

    self.check(point2.e021 == -26'f32)
    self.check(point2.e013 == -52'f32)
    self.check(point2.e032 == 20'f32)
    self.check(point2.e123 == 14'f32)

  method testRotateLine() =
    # Use an unnormalized rotor for testing correctness
    var r: Rotor
    r.set_normalized([1'f32, 4'f32, -3'f32, 2'f32])

    let l1 = newLine(-1, 2, -3, -6, 5, 4)
    let l2 = l1.rotate(r)

    self.check(l2.e01 == -110'f32)
    self.check(l2.e02 == 20'f32)
    self.check(l2.e03 == 10'f32)
    self.check(l2.e12 == -240'f32)
    self.check(l2.e31 == 102'f32)
    self.check(l2.e23 == -36'f32)

  method testRotatePoint() =
    let r = newRotor(math.PI * 0.5'f32, 0, 0, 1)
    let p1 = newPoint(1, 0, 0)
    let p2 = p1.rotate(r)

    self.check(abs(p2.x - 0'f32) < 1e-6)
    self.check(abs(p2.y - -1'f32) < 1e-6)
    self.check(p2.z == 0'f32)

  method testSlideLine() =
    var s: Slider
    s.set_normalized([0'f32, -5'f32, -2'f32, 2'f32])

    let l1 = newLine(-1, 2, -3, -6, 5, 4)
    let l2 = l1.slide(s)

    self.check(l2.e01 == 35'f32)
    self.check(l2.e02 == -14'f32)
    self.check(l2.e03 == 71'f32)
    self.check(l2.e12 == 4'f32)
    self.check(l2.e31 == 5'f32)
    self.check(l2.e23 == -6'f32)

  method testSlidePoint() =
    let s = newSlider(1, 0, 0, 1)
    let p1 = newPoint(1, 0, 0)
    let p2 = p1.slide(s)

    self.check(p2.x == 1'f32)
    self.check(p2.y == 0'f32)
    self.check(abs(p2.z - 1'f32) < 1e-6)

  method testConstructMotor() =
    let r = newRotor(math.PI * 0.5'f32, 0, 0, 1)
    let t = newSlider(1, 0, 0, 1)
    let p1 = newPoint(1, 0, 0)

    var m = r * t
    
    var p2 = p1.move(m)
    self.check(abs(p2.x - 0) < 1e-6)
    self.check(abs(p2.y - -1) < 1e-6)
    self.check(abs(p2.z - 1) < 1e-6)

    ## Rotation and translation about the same axis commutes
    m  = t * r
    p2 = p1.move(m)
    self.check(abs(p2.x - 0) < 1e-6)
    self.check(abs(p2.y - -1) < 1e-6)
    self.check(abs(p2.z - 1) < 1e-6)

    let l = log(m)
    self.check(l.e23 == 0)
    self.check(abs(l.e12 - 0.7854) < 0.001)
    self.check(l.e31 == 0)
    self.check(l.e01 == 0)
    self.check(l.e02 == 0)
    self.check(abs(l.e03 - -0.5) < 1e-6)

  method testConstructMotorViaScrewAxis() =
    let m = newMotor(math.PI * 0.5'f32, 1'f32, newLine(0, 0, 0, 0, 0, 1))
    let p1 = newPoint(1, 0, 0)
    let p2 = p1.move(m)
    self.check(abs(p2.x - 0) < 1e-6)
    self.check(abs(p2.y - 1) < 1e-6)
    self.check(abs(p2.z - 1) < 1e-6)

  method testMotorPlane() =
    let m = newMotor(1, 4, 3, 2, 5, 6, 7, 8)
    let p1 = newPlane(3, 2, 1, -1)
    let p2 = p1.move(m)
    self.check(p2.x == 78)
    self.check(p2.y == 60)
    self.check(p2.z == 54)
    self.check(p2.d == 358)

  method testMotorPlaneVariadic() =
    let m = newMotor(1, 4, 3, 2, 5, 6, 7, 8)
    let ps = [newPlane(3, 2, 1, -1), newPlane(3, 2, 1, -1)]
    var ps2: array[2, Plane]
    m.move(ps[0].unsafeAddr, ps2[0].addr, 2)

    for p in ps2:
      self.check(p.x == 78)
      self.check(p.y == 60)
      self.check(p.z == 54)
      self.check(p.d == 358)

  method testMotorPoint() =
    let m = newMotor(1, 4, 3, 2, 5, 6, 7, 8)
    let p1 = newPoint(-1, 1, 2)
    let p2 = p1.move(m)
    self.check(p2.x == -12)
    self.check(p2.y == -86)
    self.check(p2.z == -86)
    self.check(p2.w == 30)

  method testMotorPointVariadic() =
    let m = newMotor(1, 4, 3, 2, 5, 6, 7, 8)
    let ps = [newPoint(-1, 1, 2), newPoint(-1, 1, 2)]
    var ps2: array[2, Point]
    m.move(ps, ps2)

    for p in ps2:
      self.check(p.x == -12)
      self.check(p.y == -86)
      self.check(p.z == -86)
      self.check(p.w == 30)

  method testMotorLine() =
    let m = newMotor(2, 4, 3, -1, -5, -2, 2, -3)
    # a*e01 + b*e01 + c*e02 + d*e23 + e*e31 + f*e12
    let l1 = newLine(-1, 2, -3, -6, 5, 4)
    let l2 = l1.move(m)
    self.check(l2.e01 == 6)
    self.check(l2.e02 == 522)
    self.check(l2.e03 == 96)
    self.check(l2.e12 == -214)
    self.check(l2.e31 == -148)
    self.check(l2.e23 == -40)

  method testMotorLineVariadic() =
    let m = newMotor(2, 4, 3, -1, -5, -2, 2, -3)
    # a*e01 + b*e01 + c*e02 + d*e23 + e*e31 + f*e12
    let ls = [newLine(-1, 2, -3, -6, 5, 4), newLine(-1, 2, -3, -6, 5, 4)]
    var ls2: array[2, Line]
    m.move(ls, ls2)

    for l in ls2:
      self.check(l.e01 == 6)
      self.check(l.e02 == 522)
      self.check(l.e03 == 96)
      self.check(l.e12 == -214)
      self.check(l.e31 == -148)
      self.check(l.e23 == -40)

  method testMotorOrigin() =
    let r = newRotor(math.PI * 0.5'f32, 0, 0, 1)
    let t = newSlider(1, 0, 0, 1)
    let m = r * t
    let p = moveOrigin(m)
    self.check(p.x == 0)
    self.check(p.y == 0)
    self.check(abs(p.z - 1) < 1e-6)

  method testMotorToMatrix() =
    let m = newMotor(1, 4, 3, 2, 5, 6, 7, 8)
    let p1    = mm_set_ps(1, 2, 1, -1)
    let m_mat = m.toMat4x4()
    let p2    = p1 * m_mat
    let buf   = p2.toArray

    self.check(buf[0] == -12)
    self.check(buf[1] == -86)
    self.check(buf[2] == -86)
    self.check(buf[3] == 30)

  method testMotorToMatrix_3x4() =
    var m = newMotor(1, 4, 3, 2, 5, 6, 7, 8)
    m.normalize()
    let p1    = mm_set_ps(1, 2, 1, -1)
    let m_mat = m.toMat3x4()
    let p2    = p1 * m_mat
    let buf   = p2.toArray

    self.check(abs(buf[0] - (-12'f32 / 30)) < 1e-6)
    self.check(abs(buf[1] - (-86'f32 / 30)) < 1e-6)
    self.check(abs(buf[2] - (-86'f32 / 30)) < 1e-6)
    self.check(buf[3] == 1)

  method testNormalizeMotor() =
    var m = newMotor(1, 4, 3, 2, 5, 6, 7, 8)
    m.normalize()
    let norm = m * ~m
    self.check(abs(norm.scalar - 1) < 1e-6)
    self.check(abs(norm.e0123 - 0) < 1e-6)

  method testMotorSqrt() =
    let m = newMotor(math.PI * 0.5'f32, 3, newLine(3, 1, 2, 4, -2, 1).normalized())

    var m2 = sqrt(m)
    m2 = m2 * m2

    self.check((m.scalar - m2.scalar) < 1e-6)
    self.check((m.e01 - m2.e01) < 1e-6)
    self.check((m.e02 - m2.e02) < 1e-6)
    self.check((m.e03 - m2.e03) < 1e-6)
    self.check((m.e23 - m2.e23) < 1e-6)
    self.check((m.e31 - m2.e31) < 1e-6)
    self.check((m.e12 - m2.e12) < 1e-6)
    self.check((m.e0123 - m2.e0123) < 1e-6)

  method testRotorSqrt() =
    let r = newRotor(math.PI * 0.5'f32, 1, 2, 3)

    var r2 = sqrt(r)
    r2     = r2 * r2
    self.check(abs(r2.scalar - r.scalar) < 1e-6)
    self.check(abs(r2.e23 - r.e23) < 1e-6)
    self.check(abs(r2.e31 - r.e31) < 1e-6)
    self.check(abs(r2.e12 - r.e12) < 1e-6)

  method testNormalizeRotor() =
    var r: Rotor
    r.p1 = mm_set_ps(4, -3, 3, 28)
    r.normalize()
    let norm = r * ~r
    self.check(abs(norm.scalar - 1) < 1e-6)
    self.check(abs(norm.e12 - 0) < 1e-6)
    self.check(abs(norm.e31 - 0) < 1e-6)
    self.check(abs(norm.e23 - 0) < 1e-6)


when isMainModule:
  einheit.runTests()

