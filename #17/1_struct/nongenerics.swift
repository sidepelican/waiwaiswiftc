struct A {
  var value: UInt16
}

func f() -> A {
  let a = A(value: UInt16(6))
  return a
}

_ = f()