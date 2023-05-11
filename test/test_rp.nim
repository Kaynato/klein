## Test Regressive Product (Join)

import einheit
import ../pga3d

testSuite RegressiveProduct:

  method testZLine() =
    let p1 = newPoint(0, 0, 0)
    let p2 = newPoint(0, 0, 1)
    let p12 = p1 & p2
    self.check(p12.e12 == 1)


  method testYLine() =
    let p1 = newPoint(0, -1, 0)
    let p2 = newPoint(0, 0, 0)
    let p12 = p1 & p2
    self.check(p12.e31 == 1)


  method testXLine() =
    let p1 = newPoint(-2, 0, 0)
    let p2 = newPoint(-1, 0, 0)
    let p12 = p1 & p2
    self.check(p12.e23 == 1)


  method testPlaneConstruction() =
    let p1 = newPoint(1, 3, 2)
    let p2 = newPoint(-1, 5, 2)
    let p3 = newPoint(2, -1, -4)

    let p123 = p1 & p2 & p3

    # Check that all 3 points lie on the plane
    self.check(p123.e1 + p123.e2 * 3 + p123.e3 * 2 + p123.e0 == 0)
    self.check(-p123.e1 + p123.e2 * 5 + p123.e3 * 2 + p123.e0 == 0)
    self.check(p123.e1 * 2 - p123.e2 - p123.e3 * 4 + p123.e0 == 0)
    

when isMainModule:
  einheit.runTests()