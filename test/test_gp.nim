## Test Geometric Product (compose)

import einheit
import ../pga3d
import ../backend/laser

const EPS = 1e-6

testSuite GeometricProduct:

  method testPlanePlaneMul() =
    # d*e_0 + a*e_1 + b*e_2 + c*e_3
    var p1 = newPlane(1, 2, 3, 4)
    let p2 = newPlane(2, 3, -1, -2)
    let p12: Motor = p1 * p2
    self.check(p12.scalar == 5)
    self.check(p12.e12 == -1)
    self.check(p12.e31 == 7)
    self.check(p12.e23 == -11)
    self.check(p12.e01 == 10)
    self.check(p12.e02 == 16)
    self.check(p12.e03 == 2)
    self.check(p12.e0123 == 0)

    # BUG - inserted normalization before sqrt here
    let m12 = p1/p2
    let sp12 = sqrt(m12)
    let p3 = p2.move(sp12)
    let diff = p3 - p1
    self.check(abs(diff.e0) < 1e-4)
    self.check(abs(diff.e1) < 1e-4)
    self.check(abs(diff.e2) < 1e-4)
    self.check(abs(diff.e3) < 1e-4)

    # This is ok
    p1.normalize()
    let m = p1 * p1
    self.check(abs(m.scalar - 1) < EPS)
    

  method testPlanePlaneDiv() =
    let p1 = newPlane(1, 2, 3, 4)
    let m = p1 / p1
    self.check(abs(m.scalar - 1) < EPS)
    self.check(m.e12 == 0)
    self.check(m.e31 == 0)
    self.check(m.e23 == 0)
    self.check(m.e01 == 0)
    self.check(m.e02 == 0)
    self.check(m.e03 == 0)
    self.check(m.e0123 == 0)
    

  method testPlanePointMul() =
    # d*e_0 + a*e_1 + b*e_2 + c*e_3
    let p1 = newPlane(1, 2, 3, 4)
    # x*e_032 + y*e_013 + z*e_021 + e_123
    let p2 = newPoint(-2, 1, 4)

    let p1p2 = p1 * p2
    self.check(p1p2.scalar == 0)
    self.check(p1p2.e01 == -5)
    self.check(p1p2.e02 == 10)
    self.check(p1p2.e03 == -5)
    self.check(p1p2.e12 == 3)
    self.check(p1p2.e31 == 2)
    self.check(p1p2.e23 == 1)
    self.check(p1p2.e0123 == 16)
    

  method testLineNormalization() =
    var l = newLine(1, 2, 3, 3, 2, 1)
    l.normalize()
    var m = l * ~l
    
    self.check(abs(m.scalar - 1) < EPS)
    self.check(abs(m.e23) < EPS)
    self.check(abs(m.e31) < EPS)
    self.check(abs(m.e12) < EPS)
    self.check(abs(m.e01) < EPS)
    self.check(abs(m.e02) < EPS)
    self.check(abs(m.e03) < EPS)
    self.check(abs(m.e0123) < EPS)
    

  method testBranchBranchMul() =
    var b1 = newBranch(2, 1, 3)
    var b2 = newBranch(1, -2, -3)
    let r = b2 * b1
    self.check(r.scalar == 9)
    self.check(r.e23 == 3)
    self.check(r.e31 == 9)
    self.check(r.e12 == -5)

    b1.normalize()
    b2.normalize()
    let b3 = b1.apply(sqrt(b2/b1))
    self.check(abs(b3.x - b2.x) < EPS)
    self.check(abs(b3.y - b2.y) < EPS)
    self.check(abs(b3.z - b2.z) < EPS)
    

  method testBranchBranchDiv() =
    let b = newBranch(2, 1, 3)
    let r = b / b
    self.check(abs(r.scalar - 1) < EPS)
    self.check(r.e23 == 0)
    self.check(r.e31 == 0)
    self.check(r.e12 == 0)
    

  method testLineLineMul() =
    # a*e01 + b*e02 + c*e03 + d*e23 + e*e31 + f*e12
    var l1 = newLine(1, 0, 0, 3, 2, 1)
    var l2 = newLine(0, 1, 0, 4, 1, -2)

    let l1l2 = l1 * l2
    self.check(l1l2.scalar == -12)
    self.check(l1l2.e12 == 5)
    self.check(l1l2.e31 == -10)
    self.check(l1l2.e23 == 5)
    self.check(l1l2.e01 == 1)
    self.check(l1l2.e02 == -2)
    self.check(l1l2.e03 == -4)
    self.check(l1l2.e0123 == 6)

    l1.normalize()
    l2.normalize()
    var l3 = l2.apply(sqrt(l1/l2))
    let diff = l3 - l1
    self.check(abs(diff.e01) < 1e-4)
    self.check(abs(diff.e02) < 1e-4)
    self.check(abs(diff.e03) < 1e-4)
    self.check(abs(diff.e12) < 1e-4)
    self.check(abs(diff.e23) < 1e-4)
    self.check(abs(diff.e31) < 1e-4)
    self.check(abs(diff.scalar) < 1e-4)
    self.check(abs(diff.pseudoscalar) < 1e-4)
    

  method testLineLineDiv() =
    let l = newLine(1, -2, 2, -3, 3, -4)
    var m = l / l
    self.check(abs(m.scalar - 1) < EPS)
    self.check(m.e12 == 0)
    self.check(m.e31 == 0)
    self.check(m.e23 == 0)
    self.check(abs(m.e01) < EPS)
    self.check(abs(m.e02) < EPS)
    self.check(abs(m.e03) < EPS)
    self.check(abs(m.e0123) < EPS)
    

  method testPointPlaneMul() =
    # x*e_032 + y*e_013 + z*e_021 + e_123
    let p1 = newPoint(-2, 1, 4)
    # d*e_0 + a*e_1 + b*e_2 + c*e_3
    let p2 = newPlane(1, 2, 3, 4)

    let p1p2 = p1 * p2
    self.check(p1p2.scalar == 0)
    self.check(p1p2.e01 == -5)
    self.check(p1p2.e02 == 10)
    self.check(p1p2.e03 == -5)
    self.check(p1p2.e12 == 3)
    self.check(p1p2.e31 == 2)
    self.check(p1p2.e23 == 1)
    self.check(p1p2.e0123 == -16)
    

  method testPointPointMul() =
    # x*e_032 + y*e_013 + z*e_021 + e_123
    let p1 = newPoint(1, 2, 3)
    let p2 = newPoint(-2, 1, 4)

    let p1p2 = p1 * p2
    self.check(abs(p1p2.e01 - -3) < EPS)
    self.check(abs(p1p2.e02 - -1) < EPS)
    self.check(abs(p1p2.e03 - 1) < EPS)

    let p3 = p2.apply(sqrt(p1p2))
    self.check(abs(p3.x - 1) < EPS)
    self.check(abs(p3.y - 2) < EPS)
    self.check(abs(p3.z - 3) < EPS)
    

  method testPointPointDiv() =
    let p1 = newPoint(1, 2, 3)
    let t = p1 / p1
    self.check(t.e01 == 0)
    self.check(t.e02 == 0)
    self.check(t.e03 == 0)
    

  method testSliderSliderDiv() =
    let t1 = newSlider(3, 1, -2, 3)
    let t2 = t1 / t1
    self.check(t2.e01 == 0)
    self.check(t2.e02 == 0)
    self.check(t2.e03 == 0)
    

  method testRotorSliderMul() =
    let r = newRotor(mm_set_ps(1, 0, 0, 1))
    let t = newSlider(mm_set_ps(1, 0, 0, 0))
    var m = r * t
    self.check(m.scalar == 1)
    self.check(m.e01 == 0)
    self.check(m.e02 == 0)
    self.check(m.e03 == 1)
    self.check(m.e23 == 0)
    self.check(m.e31 == 0)
    self.check(m.e12 == 1)
    self.check(m.e0123 == 1)
    

  method testSliderRotorMul() =
    let r = newRotor(mm_set_ps(1, 0, 0, 1))
    var t = newSlider(mm_set_ps(1, 0, 0, 0))
    let m = t * r
    self.check(m.scalar == 1)
    self.check(m.e01 == 0)
    self.check(m.e02 == 0)
    self.check(m.e03 == 1)
    self.check(m.e23 == 0)
    self.check(m.e31 == 0)
    self.check(m.e12 == 1)
    self.check(m.e0123 == 1)
    

  method testMotorRotorMul() =
    let r1 = newRotor(mm_set_ps(1, 2, 3, 4))
    var t = newSlider(mm_set_ps(3, -2, 1, -3))
    let r2 = newRotor(mm_set_ps(-4, 2, -3, 1))
    var m1 = (t * r1) * r2
    var m2 = t * (r1 * r2)

    self.check(m1.scalar == m2.scalar)
    self.check(m1.pseudoscalar == m2.pseudoscalar)
    self.check(m1.e01 == m2.e01)
    self.check(m1.e02 == m2.e02)
    self.check(m1.e03 == m2.e03)
    self.check(m1.e12 == m2.e12)
    self.check(m1.e23 == m2.e23)
    self.check(m1.e31 == m2.e31)
    

  method testRotorMotorMul() =
    let r1 = newRotor(mm_set_ps(1, 2, 3, 4))
    var t = newSlider(mm_set_ps(3, -2, 1, -3))
    let r2 = newRotor(mm_set_ps(-4, 2, -3, 1))
    var m1 = r2 * (r1 * t)
    var m2 = (r2 * r1) * t
    self.check(m1.scalar == m2.scalar)
    self.check(m1.pseudoscalar == m2.pseudoscalar)
    self.check(m1.e01 == m2.e01)
    self.check(m1.e02 == m2.e02)
    self.check(m1.e03 == m2.e03)
    self.check(m1.e12 == m2.e12)
    self.check(m1.e23 == m2.e23)
    self.check(m1.e31 == m2.e31)
    

  method testMotorSliderMul() =
    let r = newRotor(mm_set_ps(1, 2, 3, 4))
    let t1 = newSlider(mm_set_ps(3, -2, 1, -3))
    let t2 = newSlider(mm_set_ps(-4, 2, -3, 1))
    var m1 = (r * t1) * t2
    var m2 = r * (t1 * t2)
    self.check(m1.scalar == m2.scalar)
    self.check(m1.pseudoscalar == m2.pseudoscalar)
    self.check(m1.e01 == m2.e01)
    self.check(m1.e02 == m2.e02)
    self.check(m1.e03 == m2.e03)
    self.check(m1.e12 == m2.e12)
    self.check(m1.e23 == m2.e23)
    self.check(m1.e31 == m2.e31)
    

  method testSliderMotorMul() =
    let r = newRotor(mm_set_ps(1, 2, 3, 4))
    let t1 = newSlider(mm_set_ps(3, -2, 1, -3))
    let t2 = newSlider(mm_set_ps(-4, 2, -3, 1))
    var m1 = t2 * (r * t1)
    var m2 = (t2 * r) * t1
    self.check(m1.scalar == m2.scalar)
    self.check(m1.pseudoscalar == m2.pseudoscalar)
    self.check(m1.e01 == m2.e01)
    self.check(m1.e02 == m2.e02)
    self.check(m1.e03 == m2.e03)
    self.check(m1.e12 == m2.e12)
    self.check(m1.e23 == m2.e23)
    self.check(m1.e31 == m2.e31)
    

  method testMotorMotorMul() =
    let m1 = newMotor(2, 3, 4, 5, 6, 7, 8, 9)
    let m2 = newMotor(6, 7, 8, 9, 10, 11, 12, 13)
    let m3 = m1 * m2
    self.check(m3.scalar == -86)
    self.check(m3.e23 == 36)
    self.check(m3.e31 == 32)
    self.check(m3.e12 == 52)
    self.check(m3.e01 == -38)
    self.check(m3.e02 == -76)
    self.check(m3.e03 == -66)
    self.check(m3.e0123 == 384)
    

  method testMotorMotorDiv() =
    let m1 = newMotor(2, 3, 4, 5, 6, 7, 8, 9)
    let m2 = m1 / m1
    self.check(abs(m2.scalar - 1) < EPS)
    self.check(m2.e23 == 0)
    self.check(m2.e31 == 0)
    self.check(m2.e12 == 0)
    self.check(m2.e01 == 0)
    self.check(abs(m2.e02) < EPS)
    self.check(abs(m2.e03) < EPS)
    self.check(abs(m2.e0123) < EPS)


when isMainModule:
  einheit.runTests()