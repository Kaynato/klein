# Hair-tearing prohibition of allocating for things with m128 in them

type
  m128* {.importc: "__m128", byCopy, header:"<x86intrin.h>".} = object
      raw: array[4, float32]
  nim_m128* = distinct array[4, float32]

func mm_set_ps*(d, c, b, a: float32): m128 {.importc: "_mm_set_ps", noDecl, header:"<x86intrin.h>".}

when isMainModule:
  ## Minimal example
  var data = cast[ptr UncheckedArray[nim_m128]](alloc0(sizeof(m128) * 4))
  
  # These are ok
  cast[ptr array[4, float32]](data)[0] = 1'f32
  echo cast[ptr array[4, float32]](data)[]
  let xmm = mm_set_ps(4'f32, 3'f32, 2'f32, 1'f32)

  # This is to see that the pointers are exactly the same
  echo cast[int](cast[ptr UncheckedArray[array[4, float32]]](data)[0].addr)
  echo cast[int](cast[ptr UncheckedArray[m128]](data)[].addr)

  # Can we do a trick like this?
  var xmmSeq = newSeq[nim_m128](4)
  xmmSeq[0] = cast[nim_m128](xmm)
  # Finding: As long as target memory is not m128, we're ok.
  # m128 is invalid target memory. That's it.
  # Though preferably we should make a custom container
  #   which uses mm_load / mm_set...

  # This is not ok
  # data[][0] = cast[nim_m128](mm_set_ps(4'f32, 3'f32, 2'f32, 1'f32))
  
  # Motivating example (inaccessible - comment out prior to see)
  # var xmmSeq = newSeq[nim_m128](4)
  # xmmSeq[0] = cast[nim_m128](mm_set_ps(4'f32, 3'f32, 2'f32, 1'f32))


  # echo cast[int](data[0].addr)
  # for i in 0..<cap:
  #   for j in 0..<4:
  #     echo cast[ptr array[4, float32]](data)[][j]

  #   echo type(cast[ptr m128](data)[])

  #   cast[ptr m128](data)[] = mm_set_ps(1'f32, 2'f32, 3'f32, 4'f32)

  # echo cast[int](data[1].addr)
  
  # dealloc(data)



  # var planes = [newPlane(3, 2, 1, -1), newPlane(1, 2, -1, -3)]
  # echo planes.addr[]
  # echo cast[ptr m128](planes.addr)[]
  # echo cast[ptr m128](planes.addr + 1)[]
