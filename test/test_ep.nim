## Test Exterior Product

import einheit
import ../pga3d

testSuite ExteriorProduct:

  method testPlanePlane() =
    let p1 = newPlane(1, 2, 3, 4)
    let p2 = newPlane(2, 3, -1, -2)
    let p12 = p1 ^ p2
    self.check(p12.e01 == 10'f)
    self.check(p12.e02 == 16'f)
    self.check(p12.e03 == 2'f)
    self.check(p12.e12 == -1'f)
    self.check(p12.e31 == 7'f)
    self.check(p12.e23 == -11'f)


  method testPlaneLine() =
    # d*e_0 + a*e_1 + b*e_2 + c*e_3
    let p1 = newPlane(1, 2, 3, 4)
    let l1 = newLine(0, 0, 1, 4, 1, -2)

    let p1l1 = p1 ^ l1
    self.check(p1l1.e021 == 8)
    self.check(p1l1.e013 == -5)
    self.check(p1l1.e032 == -14)
    self.check(p1l1.e123 == 0)

  method testPlaneIdealLine() =
    let p1 = newPlane(1, 2, 3, 4)
    let l1 = newIdealLine(-2, 1, 4)

    let p1l1 = p1 ^ l1
    self.check(p1l1.e021 == 5)
    self.check(p1l1.e013 == -10)
    self.check(p1l1.e032 == 5)
    self.check(p1l1.e123 == 0)
    

  method testPlanePoint() =
    let p1 = newPlane(1, 2, 3, 4)
    let p2 = newPoint(-2, 1, 4)
    let p1p2 = p1 ^ p2
    self.check(p1p2.scalar == 0)
    self.check(p1p2.e0123 == 16)
    

  method testLinePlane() =
    let p1 = newPlane(1, 2, 3, 4)
    let l1 = newLine(0, 0, 1, 4, 1, -2)

    let p1l1 = l1 ^ p1
    self.check(p1l1.e021 == 8)
    self.check(p1l1.e013 == -5)
    self.check(p1l1.e032 == -14)
    self.check(p1l1.e123 == 0)
    

  method testLineLine() =
    let l1 = newLine(1, 0, 0, 3, 2, 1)
    let l2 = newLine(0, 1, 0, 4, 1, -2)

    let l1l2 = l1 ^ l2
    self.check(l1l2.e0123 == 6)
    

  method testLineIdealLine() =
    # a*e01 + b*e01 + c*e02 + d*e23 + e*e31 + f*e12
    let l1 = newLine(0, 0, 1, 3, 2, 1)
    # a*e01 + b*e02 + c*e03
    let l2 = newIdealLine(-2, 1, 4)

    let l1l2 = l1 ^ l2
    self.check(l1l2.e0123 == 0)
    self.check(l1l2.scalar == 0)
    

  method testIdealLinePlane() =
    # d*e_0 + a*e_1 + b*e_2 + c*e_3
    let p1 = newPlane(1, 2, 3, 4)

    # a*e01 + b*e02 + c*e03
    let l1 = newIdealLine(-2, 1, 4)

    let p1l1 = l1 ^ p1
    self.check(p1l1.e021 == 5)
    self.check(p1l1.e013 == -10)
    self.check(p1l1.e032 == 5)
    self.check(p1l1.e123 == 0)
    

  method testPointPlane() =
    let p1 = newPoint(-2, 1, 4)
    let p2 = newPlane(1, 2, 3, 4)

    let p1p2 = p1 ^ p2
    self.check(p1p2.e0123 == -16)
    

when isMainModule:
  einheit.runTests()