func f<T>(_ v: T) -> T { v }

@inline(never)
func g() -> UInt16 {
  f(UInt16(5))
}

g()

