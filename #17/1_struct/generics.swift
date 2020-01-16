struct A<T> {
  var value: T
}

@inline(never)
func f() -> UInt16 {
  let a = A(value: UInt16(6))
  return a.value
}

f()

// fが最適化される様子
// swift -O -Xllvm -sil-print-all -Xllvm -sil-print-only-functions=s8generics1fs6UInt16VyF generics.swift

// 特殊化されたA<UInt16>.initができてから消える様子
// swift -O -Xllvm -sil-print-all -Xllvm -sil-print-only-functions=s8generics1AV5valueACyxGx_tcfCs6UInt16V_Tg5 generics.swift
