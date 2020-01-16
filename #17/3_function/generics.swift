func f<T: Equatable>(_ v: T) -> Bool {
    v == v
}

func g(_ v: UInt16) -> Bool {
    f(v)
}

_ = g(UInt16(9))

// swift -O -Xllvm -sil-print-all -Xllvm -sil-print-only-functions=s8generics1gySbs6UInt16VF generics.swift
// でinline展開されてfが呼ばれなくなるgの様子が見れる

// swift -O -Xllvm -sil-print-all -Xllvm -sil-print-only-functions=s8generics1fySbxSQRzlFs6UInt16V_Tg5 generics.swift
// で特殊化されたfが生成されたあと↑でinline化されどこからも呼ばれなくなり消える様子が見れる
