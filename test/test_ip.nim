## Test Inner Product

import einheit
import ../pga3d
import ../backend/laser

const EPS = 1e-6

testSuite InnerProduct:

  method testPlanePlane() =
    # d*e_0 + a*e_1 + b*e_2 + c*e_3
    let p1 = newPlane(1, 2, 3, 4)
    let p2 = newPlane(2, 3, -1, -2)
    let p12 = p1 | p2
    self.check(p12 == 5)

  method testPlaneLine() =
    # d*e_0 + a*e_1 + b*e_2 + c*e_3
    let p1 = newPlane(1, 2, 3, 4)

    # a*e01 + b*e01 + c*e02 + d*e23 + e*e31 + f*e12
    let l1 = newLine(0, 0, 1, 4, 1, -2)

    let p1l1 = p1 | l1
    self.check(p1l1.e0 == -3)
    self.check(p1l1.e1 == 7)
    self.check(p1l1.e2 == -14)
    self.check(p1l1.e3 == 7)


  method testPlaneIdealLine() =
    # d*e_0 + a*e_1 + b*e_2 + c*e_3
    let p1 = newPlane(1, 2, 3, 4)

    # a*e01 + b*e02 + c*e03
    let l1 = newIdealLine(-2, 1, 4)

    let p1l1 = p1 | l1
    self.check(p1l1.e0 == -12)

  method testPlanePoint() =
    # d*e_0 + a*e_1 + b*e_2 + c*e_3
    let p1 = newPlane(1, 2, 3, 4)
    # x*e_032 + y*e_013 + z*e_021 + e_123
    let p2 = newPoint(-2, 1, 4)

    let p1p2 = p1 | p2
    self.check(p1p2.e01 == -5)
    self.check(p1p2.e02 == 10)
    self.check(p1p2.e03 == -5)
    self.check(p1p2.e12 == 3)
    self.check(p1p2.e31 == 2)
    self.check(p1p2.e23 == 1)

  method testLinePlane() =
    # d*e_0 + a*e_1 + b*e_2 + c*e_3
    let p1 = newPlane(1, 2, 3, 4)

    # a*e01 + b*e01 + c*e02 + d*e23 + e*e31 + f*e12
    let l1 = newLine(0, 0, 1, 4, 1, -2)

    let p1l1 = l1 | p1
    self.check(p1l1.e0 == 3)
    self.check(p1l1.e1 == -7)
    self.check(p1l1.e2 == 14)
    self.check(p1l1.e3 == -7)

  method testLineLine() =
    # a*e01 + b*e01 + c*e02 + d*e23 + e*e31 + f*e12
    let l1 = newLine(1, 0, 0, 3, 2, 1)
    let l2 = newLine(0, 1, 0, 4, 1, -2)

    let l1l2 = l1 | l2
    self.check(l1l2 == -12)

  method testLinePoint() =
    # a*e01 + b*e01 + c*e02 + d*e23 + e*e31 + f*e12
    let l1 = newLine(0, 0, 1, 3, 2, 1)
    # x*e_032 + y*e_013 + z*e_021 + e_123
    let p2 = newPoint(-2, 1, 4)

    let l1p2 = l1 | p2
    self.check(l1p2.e0 == 0)
    self.check(l1p2.e1 == -3)
    self.check(l1p2.e2 == -2)
    self.check(l1p2.e3 == -1)

  method testPointPlane() =
    # x*e_032 + y*e_013 + z*e_021 + e_123
    let p1 = newPoint(-2, 1, 4)
    # d*e_0 + a*e_1 + b*e_2 + c*e_3
    let p2 = newPlane(1, 2, 3, 4)

    let p1p2 = p1 | p2
    self.check(p1p2.e01 == -5)
    self.check(p1p2.e02 == 10)
    self.check(p1p2.e03 == -5)
    self.check(p1p2.e12 == 3)
    self.check(p1p2.e31 == 2)
    self.check(p1p2.e23 == 1)

    
  method testPointLine() =
    # a*e01 + b*e01 + c*e02 + d*e23 + e*e31 + f*e12
    let l1 = newLine(0, 0, 1, 3, 2, 1)
    # x*e_032 + y*e_013 + z*e_021 + e_123
    let p2 = newPoint(-2, 1, 4)

    let l1p2 = p2 | l1
    self.check(l1p2.e0 == 0)
    self.check(l1p2.e1 == -3)
    self.check(l1p2.e2 == -2)
    self.check(l1p2.e3 == -1)


  method testPointPoint() =
    # x*e_032 + y*e_013 + z*e_021 + e_123
    let p1 = newPoint(1, 2, 3)
    let p2 = newPoint(-2, 1, 4)

    let p1p2 = p1 | p2
    self.check(p1p2 == -1)


  method testProjectPointToLine() =
    let p1 = newPoint(2, 2, 0)
    let p2 = newPoint(0, 0, 0)
    let p3 = newPoint(1, 0, 0)
    let l = p2 & p3
    var p4 = (l | p1) ^ l
    p4.normalize()

    self.check(abs(p4.e123 - 1) < EPS)
    self.check(abs(p4.x - 2) < EPS)
    self.check(abs(p4.y - 0) < EPS)
    self.check(abs(p4.z - 0) < EPS)


when isMainModule:
  einheit.runTests()