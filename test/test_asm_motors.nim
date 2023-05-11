## Compare generated assembly of argument
## 1. ptr m128, count
## 2. ptr Motor, count
## 3. openArray[Motor]
## 3. openArray[Motor] with explicit return
# ( On Godbolt )

import ./m128_print
import ../backend/pointerops

{.pragma: x86_type, byCopy, header:"<x86intrin.h>".}
{.pragma: x86, noDecl, header:"<x86intrin.h>".}

type m128* {.importc: "__m128", x86_type.} = object
    raw: array[4, float32]
    
func mm_add_ps*(a, b: m128): m128 {.importc: "_mm_add_ps", x86.}
func mm_mul_ps*(a, b: m128): m128 {.importc: "_mm_mul_ps", x86.}
func mm_set_ps*(d, c, b, a: float32): m128 {.importc: "_mm_set_ps", x86.}
func mm_storeu_ps*(mem_addr: ptr float32, a: m128) {.importc: "_mm_storeu_ps", x86.}

template `+`*(a, b: m128): m128 = mm_add_ps(a, b)
template `-`*(a, b: m128): m128 = mm_sub_ps(a, b)
template `*`*(a, b: m128): m128 = mm_mul_ps(a, b)

proc sqsum*(a, b: m128): m128 = (a * a) + (b * b)

type Motor = object
  p1, p2: m128

proc `$`(m: Motor): string =
  $(m.p1.toArray) & ", " & $(m.p2.toArray)

proc `$`(m: openArray[Motor]): string =
  result.add "[\n"
  for motor in m:
    result.add "  " & $motor
  result.add "]"



proc testProc1*(mIn: ptr m128, b, c: m128, mOut: ptr m128, count: int) =
  for i in countup(0, count*2, 2):
    (mOut+i  )[] = sqsum((mIn+i)[] + c, b + (mIn+i+1)[])
    (mOut+i+1)[] = sqsum((mIn+i)[] + b, c + (mIn+i+1)[])

proc testProc2*(mIn: ptr Motor, b, c: m128, mOut: ptr Motor, count: int) =
  for i in 0..<count:
    (mOut+i)[].p1 = sqsum((mIn+i)[].p1 + c, b + (mIn+i)[].p2)
    (mOut+i)[].p2 = sqsum((mIn+i)[].p1 + b, c + (mIn+i)[].p2)

proc testProc3*(mIn: openArray[Motor], b, c: m128, mOut: var openArray[Motor]) =
  for i in 0..<mIn.len:
    mOut[i].p1 = sqsum(mIn[i].p1 + c, b + mIn[i].p2)
    mOut[i].p2 = sqsum(mIn[i].p1 + b, c + mIn[i].p2)

proc testProc4*[I](mIn: array[I, Motor], b, c: m128): array[I, Motor] =
  for i in 0..<mIn.len:
    result[i].p1 = sqsum(mIn[i].p1 + c, b + mIn[i].p2)
    result[i].p2 = sqsum(mIn[i].p1 + b, c + mIn[i].p2)

proc testProc5*(mIn: seq[Motor], b, c: m128): seq[Motor] =
  # result = newSeq[Motor](mIn.len)
  for m in mIn:
    result.add Motor(p1: sqsum(m.p1 + c, b + m.p2),
                     p2: sqsum(m.p1 + b, c + m.p2))

proc testProc2Wrapped1*(mIn: openArray[Motor], b, c: m128): ptr Motor =
  result = cast[ptr Motor](alloc0(sizeof(Motor) * mIn.len))
  testProc2(cast[ptr Motor](mIn[0].unsafeAddr), b, c, result, mIn.len)

when isMainModule:
  
  var u1 = mm_set_ps(5'f, 6'f, 7'f, 8'f)
  var u2 = mm_set_ps(5'f, 6'f, 7'f, 8'f)
  var v1 = mm_set_ps(1'f, 2'f, 3'f, 4'f)
  var v2 = mm_set_ps(1'f, 2'f, 3'f, 4'f)
  var uv1 = sqsum(u1, v1)
  var uv2 = sqsum(u1, v2)
  var uv3 = sqsum(u2, v1)
  var uv4 = sqsum(u2, v2)
  var w1 = mm_set_ps(1.5'f32, 2.22'f32, 3'f32, 8.9'f32)
  var w2 = mm_set_ps(1.2'f32, 4.32'f32, 3'f32, 9.8'f32)

  var m1 = Motor(p1: u1, p2: u2)
  var m2 = Motor(p1: v1, p2: v2)
  var m3 = Motor(p1: uv1, p2: uv2)
  var m4 = Motor(p1: uv3, p2: uv4)

  var ret1: array[8, m128]
  var ret2: array[4, Motor]
  var ret3: array[4, Motor]

  import perf

  var arg1 = [u1, u2, v1, v2, uv1, uv2, uv3, uv4]
  perf.timeit("Proc1", 100000):
    testProc1(cast[ptr m128](arg1.addr), w1, w2, cast[ptr m128](ret1.addr), 4)
  # echo [Motor(p1: ret1[0], p2: ret1[1]),
  #       Motor(p1: ret1[2], p2: ret1[3]),
  #       Motor(p1: ret1[4], p2: ret1[5]),
  #       Motor(p1: ret1[6], p2: ret1[7])]

  var arg2 = [m1, m2, m3, m4]
  perf.timeit("Proc2", 100000):
    testProc2(cast[ptr Motor](arg2.addr), w1, w2, cast[ptr Motor](ret2.addr), 4)
  # echo ret2

  # perf.timeit("Proc2w1", 100000):
    # discard testProc2Wrapped1(arg2, w1, w2)

  perf.timeit("Proc3", 100000):
    testProc3(arg2, w1, w2, ret3)
  # echo ret3

  perf.timeit("Proc4", 100000):
    ret3 = testProc4(arg2, w1, w2)
    
  
  var arg3 = @arg2
  var ret4: seq[Motor]
  perf.timeit("Proc4", 100000):
    ret4 = testProc5(arg3, w1, w2)
  # echo ret4