## Timing performance measurement

import strformat

# Try to write a line profiler macro... inject timing into every line in the context, sending times back to build seqs...

template timeit*(body: untyped): untyped =
  import std/monotimes
  from times import inNanoseconds
  let timeA = getMonoTime()
  body
  let duration = getMonoTime() - timeA
  echo duration.inNanoseconds.float / 1e6, " ms"

template timeit*(msg: string, body: untyped): untyped =
  import std/monotimes
  from times import inNanoseconds
  let timeA = getMonoTime()
  body
  let duration = getMonoTime() - timeA
  echo msg, ": ", duration.inNanoseconds.float / 1e6, " ms"

template timeit*(msg: string, iters: int, body, prep: untyped): untyped =
  from stats import RunningStat, push, mean, standardDeviation
  import std/monotimes
  from times import inNanoseconds

  var rs: RunningStat

  for _ in 1..iters:
    prep
    let timeA = getMonoTime()
    body
    let duration = getMonoTime() - timeA
    let ms = duration.inNanoseconds.float64
    rs.push(ms)
  block:
    # let msg1 {.inject.} = msg
    var msMean {.inject.}: float64 = rs.mean
    var msStd {.inject.}: float64 = rs.standardDeviation
    let iters1 {.inject.} = iters
    var timeRes {.inject.}: string
    let msRes {.inject.} = ["ns", "μs", "ms", "s"]
    var msResI {.inject.} = 0
    while msMean > 1000'f64 and msStd > 100'f64:
      msMean /= 1000'f64
      msStd /= 1000'f64
      msResI += 1
    timeRes = msRes[msResI]
    echo msg
    echo &"    (mean: {msMean:1.4f} {timeRes} | std: {msStd:1.4f} {timeRes}) over {iters1} trials."

template timeit*(msg: string, iters: int, body: untyped): untyped =
  timeit(msg, iters, body):
    discard

# macro lineProfiler(untyped: body): untyped =
  # discard
