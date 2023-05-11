## \defgroup dualn Dual Numbers
## A dual number is a multivector of the form $p + q\mathbf{e}_{0123}$.

import ./types

func newDual*(p, q: float): Dual {.inline.} =
  Dual(p: p, q: q)
