
func `+`*(p: ptr, offset: int): type(p) {.inline.}=
  ## Pointer increment
  {.emit: "`result` = `p` + `offset`;".}
