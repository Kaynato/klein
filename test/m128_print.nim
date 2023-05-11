# To print m128
import strformat
import strutils
import ../backend/laser
import ../backend/ops

proc `$`*(m: m128): string =
  $(m.toArray)

proc `$`*(m: openArray[m128]): string =
  result.add "[\n"
  for xmm in m:
    result.add "  " & $(xmm.toArray)
  result.add "]"

func hexRead*(a: m128): string {.used.} =
  let buf = cast[array[4, int32]](a.toArray)
  return &"[{buf[0].toHex} {buf[1].toHex} {buf[2].toHex} {buf[3].toHex}]"