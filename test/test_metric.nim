from math import nil

import einheit

import ../pga3d
import ../compat

const
  sqrt2 = math.sqrt(2'f32)
  EPS = 1e-6

testSuite Metric:

  method testMeasurePointToPoint() =
    let p1 = newPoint(1, 0, 0)
    let p2 = newPoint(0, 1, 0)
    let norm = squared_norm(p1 & p2)
    # Produce the squared distance between p1 and p2
    self.check(norm == 2)

  method testMeasurePointToPlane() =
    #    Plane p2
    #    /
    #   / \ line perpendicular to
    #  /   \ p2 through p1
    # 0------x--------->
    #        p1

    # (2, 0, 0)
    let p1 = newPoint(2, 0, 0)
    # Plane x - y = 0
    var p2 = newPlane(1, -1, 0, 0)
    p2.normalize()
    # Distance from point p1 to plane p2
    self.check((abs((p1 & p2).scalar) - sqrt2) < EPS)
    self.check((abs((p1 ^ p2).e0123) - sqrt2) < EPS)
    

  method testMeasurePointToLine() =
    let l = newLine(0, 1, 0, 1, 0, 0)
    let p = newPoint(0, 1, 2)
    let distance = norm(l & p)
    self.check((distance - sqrt2) < EPS)
    

  method testEulerAngles() =
    # Make 3 rotors about the x, y, and z-axes.
    let rx = newRotor(1, 1, 0, 0)
    let ry = newRotor(1, 0, 1, 0)
    let rz = newRotor(1, 0, 0, 1)
    let r = rx * ry * rz
    let ea = r.toEulerAngles
    self.check(abs(ea.roll - 1) < EPS)
    self.check(abs(ea.pitch - 1) < EPS)
    self.check(abs(ea.yaw - 1) < EPS)

    let r2 = ea.toRotor

    let buf1 = r.store()
    let buf2 = r2.store()
    
    for i in 0..<3:
      self.check(abs(buf1[i] - buf2[i]) < EPS)
    

  method testEulerAnglesPrecision() =
    let ea1 = EulerAngles(roll: math.PI * 0.2f, pitch: math.PI * 0.2f, yaw: 0f)
    let r1 = ea1.toRotor
    let ea2 = r1.toEulerAngles

    self.check(abs(ea1.roll - ea2.roll) < EPS)
    self.check(abs(ea1.pitch - ea2.pitch) < EPS)
    self.check(abs(ea1.yaw - ea2.yaw) < EPS)


when isMainModule:
  einheit.runTests()