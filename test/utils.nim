# Test utilities

type Approx*[T: SomeFloat] = object
  val*: T
  eps*: T

proc approx*[T](v: T, eps: T=1e-6.T): Approx[T] =
  Approx[T](val: v, eps: eps)

proc `==`*[T](a: T, b: Approx[T]): bool =
  abs(a - b.val) < b.eps

proc `==`*[T](b: Approx[T], a: T): bool =
  abs(a - b.val) < b.eps

proc `$`*[T](a: Approx[T]): string =
  "Approx(" & $a.val & " +/- " $a.eps & ")"

proc toString*(a: Approx): string =
  "Approx(" & $a.val & " +/- " $a.eps & ")"
