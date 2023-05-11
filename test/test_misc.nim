## Test (misc)

import einheit
import ../pga3d
import ../backend/laser
include ./m128_print

const EPS = 1e-6

testSuite Misc:

  method testPoints() =
    let p1 = newPoint(1, 2, 3)
    let p2 = newPoint(2, 3, -1)
    let p3 = p1 + p2
    self.check(p3.x == (1 + 2))
    self.check(p3.y == (2 + 3))
    self.check(p3.z == (3 + -1))

    let p4 = p1 - p2
    self.check(p4.x == (1 - 2))
    self.check(p4.y == (2 - 3))
    self.check(p4.z == (3 - -1))

    # Adding rvalue to lvalue
    let p5 = newPoint(1, 2, 3) + p2
    self.check(p5.x == (1 + 2))
    self.check(p5.y == (2 + 3))
    self.check(p5.z == (3 + -1))

    # Adding rvalue to rvalue
    let p6 = newPoint(1, 2, 3) + newPoint(2, 3, -1)
    self.check(p6.x == (1 + 2))
    self.check(p6.y == (2 + 3))
    self.check(p6.z == (3 + -1))

  method testPlanes() =
    var p = newPlane(1, 3, 4, -5)
    var p_norm = p | p
    self.check(p_norm != 1)
    p.normalize()
    p_norm = p | p
    self.check(abs(p_norm - 1) < EPS)

  method testRotorConstrain() =
    var r1 = newRotor(1, 2, 3, 4)
    var r2 = r1.constrained()
    self.check(r1.scalar == r2.scalar)
    self.check(r1.e23 == r2.e23)
    self.check(r1.e31 == r2.e31)
    self.check(r1.e12 == r2.e12)

    r1 = -r1
    r2 = r1.constrained()
    self.check(r1.scalar == -r2.scalar)
    self.check(r1.e23 == -r2.e23)
    self.check(r1.e31 == -r2.e31)
    self.check(r1.e12 == -r2.e12)

  method testMotorConstrain() =
    var m1 = newMotor(1, 2, 3, 4, 5, 6, 7, 8)
    var m2 = m1.constrained()
    self.check(m1.scalar == m2.scalar)
    self.check(m1.e23 == m2.e23)
    self.check(m1.e31 == m2.e31)
    self.check(m1.e12 == m2.e12)
    self.check(m1.e01 == m2.e01)
    self.check(m1.e02 == m2.e02)
    self.check(m1.e03 == m2.e03)
    self.check(m1.e0123 == m2.e0123)

    m1 = -m1
    m2 = m1.constrained()
    self.check(m1.scalar == -m2.scalar)
    self.check(m1.e23 == -m2.e23)
    self.check(m1.e31 == -m2.e31)
    self.check(m1.e12 == -m2.e12)
    self.check(m1.e01 == -m2.e01)
    self.check(m1.e02 == -m2.e02)
    self.check(m1.e03 == -m2.e03)
    self.check(m1.e0123 == -m2.e0123)


when isMainModule:
  einheit.runTests()