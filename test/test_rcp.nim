## Numerical stability of sse reciprocal

import ../backend/laser
import ../backend/ops
import ../backend/symoperator

import ./m128_print
import ./perf

const N = 100

when isMainModule:
  let a1 = mm_set_ps(1f, 2f, 63f, 121f)

  var rec = a1
  for i in 1..N:
    rec = rec.rcp_nr1().rcp_nr1()
  echo (a1 - rec)

  rec = a1
  for i in 1..N:
    rec = rec.rcp_nr(1).rcp_nr(1)
  echo (a1 - rec)

  rec = a1
  for i in 1..N:
    rec = rec.rcp_nr(2).rcp_nr(2)
  echo (a1 - rec)

  rec = a1
  for i in 1..N:
    rec = rec.rcp_nr(3).rcp_nr(3)
  echo (a1 - rec)

  # 15.58 ns
  timeit("RCP NR 1*", 10000000):
    rec = rec.rcp_nr1()    
  
  timeit("RCP NR 1", 10000000):
    rec = rec.rcp_nr(1)

  timeit("RCP NR 2", 10000000):
    rec = rec.rcp_nr(2)

  timeit("RCP NR 3", 10000000):
    rec = rec.rcp_nr(3)
