## Geometry for vulkan rendering - subset of PGA3D
import glm
import compat/[matrixconvert, conversion]
import backend/symoperator
import backend/laser
import backend/ops
import pga3d
from math import nil

export glm
# This might be a horrible idea

## Auxiliary math
const
  PI_2 = math.PI * 0.5'f32

func copysignf(mag, sign: float32): float32 {.importc.}

## Standard Rendering Objects

type
  EulerAngles* = object
    ## Euler angles in radians
    roll*, pitch*, yaw*: float32

  MMat3x4 {.union.} = object
    ## 3x4 column-major matrix for converting rotors/motors
    ##   to matrix for Shaders. Due to SIMD representation,
    ##   the storage requirement is identical to 4x4's.
    cols*: array[4, m128]
    data*: array[16, float32]

  MMat4x4 {.union.} = object
    ## 4x4 column-major matrix for converting rotors/motors
    ##   to matrix for Shaders.
    cols*: array[4, m128]
    data*: array[16, float32]

func apply*(mat: MMat3x4 | MMat4x4, p: m128): m128 =
  ## Apply this matrix's linear transform to the packed point
  ## Given that the point is (x, y, z, 1'f)
  (mat.cols[0] * p.wwww)
    .mm_add_ps(mat.cols[1] * p.zzzz)
    .mm_add_ps(mat.cols[2] * p.yyyy)
    .mm_add_ps(mat.cols[3] * p.xxxx)

template `*`*(a: m128, mat: MMat3x4 | MMat4x4): m128 =
  ## Matrix multiplication
  mat.apply(a)

######################
## Angle Conversion ##
######################

func toRotor*(ea: EulerAngles): Rotor =
  ## Construct a Rotor from Euler Angles
  let half_y = ea.yaw * 0.5'f32
  let half_p = ea.pitch * 0.5'f32
  let half_r = ea.roll * 0.5'f32

  let cos_y = math.cos(half_y)
  let sin_y = math.sin(half_y)
  let cos_p = math.cos(half_p)
  let sin_p = math.sin(half_p)
  let cos_r = math.cos(half_r)
  let sin_r = math.sin(half_r)

  result.p1 = mm_set_ps(
    cos_r * cos_p * sin_y - sin_r * sin_p * cos_y,
    cos_r * sin_p * cos_y + sin_r * cos_p * sin_y,
    sin_r * cos_p * cos_y - cos_r * sin_p * sin_y,
    cos_r * cos_p * cos_y + sin_r * sin_p * sin_y
  )

  result.normalize()


func toEulerAngles*(r: Rotor): EulerAngles =
  ## Construct Euler Angles from a Rotor.
  let buf = r.p1.toArray
  let test = (buf[1] * buf[2]) + (buf[3] * buf[0])

  if test > 0.4999'f32:
      result.roll  = 2'f32 * math.arctan2(buf[1], buf[0])
      result.pitch = PI_2
      result.yaw   = 0'f32
      return
  elif test < -0.4999'f32:
      result.roll  = -2'f32 * math.arctan2(buf[1], buf[0])
      result.pitch = -PI_2
      result.yaw   = 0'f32
      return

  let buf1_2 = buf[1] * buf[1]
  let buf2_2 = buf[2] * buf[2]
  let buf3_2 = buf[3] * buf[3]

  result.roll = math.arctan2(2 * (buf[0] * buf[1] + buf[2] * buf[3]), 1 - 2 * (buf1_2 + buf2_2))

  let sinp = 2 * ((buf[0] * buf[2]) - (buf[1] * buf[3]))
  result.pitch = 
    if abs(sinp) > 1: copysignf(PI_2, sinp)
    else:             math.arcsin(sinp)

  result.yaw = math.arctan2(2 * (buf[0] * buf[3] + buf[1] * buf[2]), 1 - 2 * (buf2_2 + buf3_2))

#######################
## Matrix Conversion ##
#######################

func toMat3x4*(r: Rotor): MMat3x4 =
  ## Convert the rotor to a 3x4 column-major matrix.
  ## Only valid for normalized rotors (but preferred in that case)
  toMat4x4_12(r.p1, result.cols, NORMALIZED=true)

func toMat4x4*(r: Rotor): MMat4x4 =
  ## Convert the rotor to a 4x4 column-major matrix.
  toMat4x4_12(r.p1, result.cols, NORMALIZED=false)

func toMat3x4*(m: Motor): MMat3x4 =
  ## Convert the rotor to a 3x4 column-major matrix.
  ## Only valid for normalized motors (but preferred in that case)
  toMat4x4_12_tr(m.p1, m.p2, result.cols, NORMALIZED=true)

func toMat4x4*(m: Motor): MMat4x4 =
  ## Convert the rotor to a 4x4 column-major matrix.
  toMat4x4_12_tr(m.p1, m.p2, result.cols, NORMALIZED=false)

# To GLM type

converter toGLMMat4*(m: MMat3x4): Mat4[float32] = result.arr = cast[array[4, Vec[4, float32]]](m.data)
converter toGLMMat4*(m: MMat4x4): Mat4[float32] = result.arr = cast[array[4, Vec[4, float32]]](m.data)

### ### ### ### ### ###

### Vec3f Conversion

func newPoint*(v: Vec3f): Point = newPoint(v.x, v.y, v.z)
func newBranch*(v: Vec3f): Branch = newBranch(v.x, v.y, v.z)

### ### ### ### ### ###

### GL Functions

func worldToView*(eye: Point; forward, up: Branch): Motor =
  ## Generate a lookAt Motor from 3 points
  ## Eye point (camera location) -> Origin
  ## Forward direction as point  -> -Z
  ## Up direction (as point)     -> +Y
  ## Forward and Up are defined relative to origin
  
  # Camera eye to origin translation
  let ts = eye.sliderToOrigin()
  
  # Rotor for forward -> -Z
  # Rotate "up" and then find final correction rotor r2
  let r1 = forward.rotorToZ(minus=true)
  let r2 = up.rotate(r1).rotorToY()

  result = r2 * r1 * ts

