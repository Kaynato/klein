## Test exp-log

from math import PI
import einheit
import ../pga3d
import ./m128_print

const EPS1 = 1e-6

testSuite ExpLog:

  method testRotorExpLog() =
    let r = newRotor(PI * 0.5f, 0.3f, -3, 1)
    let b = log(r)
    let r2 = exp(b)

    self.check(abs(r2.scalar - r.scalar) < EPS1)
    self.check(abs(r2.e12 - r.e12) < EPS1)
    self.check(abs(r2.e31 - r.e31) < EPS1)
    self.check(abs(r2.e23 - r.e23) < EPS1)
    

  method testRotorSqrt() =
    let r1 = newRotor(PI * 0.5f, 0.3f, -3, 1)
    let r2 = sqrt(r1)
    let r3 = r2 * r2
    self.check(abs(r1.scalar - r3.scalar) < EPS1)
    self.check(abs(r1.e12 - r3.e12) < EPS1)
    self.check(abs(r1.e31 - r3.e31) < EPS1)
    self.check(abs(r1.e23 - r3.e23) < EPS1)
    

  method testMotorExpLogSqrt() =
    ## Construct a motor from a translator and rotor
    let r = newRotor(PI * 0.5f, 0.3f, -3, 1)
    let t = newSlider(12f, -2f, 0.4f, 1f)
    let m1 = r * t

    let l  = log(m1)
    let m2 = exp(l)

    self.check(abs(m1.scalar - m2.scalar) < EPS1)
    self.check(abs(m1.e12 - m2.e12) < EPS1)
    self.check(abs(m1.e31 - m2.e31) < EPS1)
    self.check(abs(m1.e23 - m2.e23) < EPS1)
    self.check(abs(m1.e01 - m2.e01) < EPS1)
    self.check(abs(m1.e02 - m2.e02) < EPS1)
    self.check(abs(m1.e03 - m2.e03) < EPS1)
    self.check(abs(m1.e0123 - m2.e0123) < EPS1)

    let m3 = sqrt(m1) * sqrt(m1)
    self.check(abs(m1.scalar - m3.scalar) < EPS1)
    self.check(abs(m1.e12 - m3.e12) < EPS1)
    self.check(abs(m1.e31 - m3.e31) < EPS1)
    self.check(abs(m1.e23 - m3.e23) < EPS1)
    self.check(abs(m1.e01 - m3.e01) < EPS1)
    self.check(abs(m1.e02 - m3.e02) < EPS1)
    self.check(abs(m1.e03 - m3.e03) < EPS1)
    self.check(abs(m1.e0123 - m3.e0123) < EPS1)
    

  method testMotorSlerp() =
    ## Construct a motor from a translator and rotor
    let r = newRotor(PI * 0.5f, 0.3f, -3, 1)
    let t = newSlider(12f, -2f, 0.4f, 1f)
    let m1 = r * t
    let l   = log(m1)
    ## Divide the motor action into three equal steps
    let step = l / 3
    let m_step = exp(step)
    let m2     = m_step * m_step * m_step
    self.check(abs(m1.scalar - m2.scalar) < EPS1)
    self.check(abs(m1.e12 - m2.e12) < EPS1)
    self.check(abs(m1.e31 - m2.e31) < EPS1)
    self.check(abs(m1.e23 - m2.e23) < EPS1)
    self.check(abs(m1.e01 - m2.e01) < EPS1)
    self.check(abs(m1.e02 - m2.e02) < EPS1)
    self.check(abs(m1.e03 - m2.e03) < 2e-6)
    self.check(abs(m1.e0123 - m2.e0123) < EPS1)
    

  method testMotorBlend() =
    let r1 = newRotor(PI * 0.5f, 0, 0, 1)
    let t1 = newSlider(1, 0, 0, 1)
    let m1 = r1 * t1

    let r2 = newRotor(PI * 0.5f, 0.3f, -3, 1)
    let t2 = newSlider(12f, -2f, 0.4f, 1f)
    let m2 = r2 * t2

    let motion = m2 * ~m1
    let step   = log(motion) / 4
    let motor_step = exp(step)

    ## Applying motor_step 0 times to m1 is m1.
    ## Applying motor_step 4 times to m1 is m2 * ~m1
    let motor_out = motor_step * motor_step * motor_step * motor_step * m1
    self.check(abs(motor_out.scalar - m2.scalar) < EPS1)
    self.check(abs(motor_out.e12 - m2.e12) < EPS1)
    self.check(abs(motor_out.e31 - m2.e31) < EPS1)
    self.check(abs(motor_out.e23 - m2.e23) < EPS1)
    self.check(abs(motor_out.e01 - m2.e01) < EPS1)
    self.check(abs(motor_out.e02 - m2.e02) < EPS1)
    self.check(abs(motor_out.e03 - m2.e03) < 3e-6)
    self.check(abs(motor_out.e0123 - m2.e0123) < 2e-6)
    
when isMainModule:
  einheit.runTests()