func f<T>(_ a: T) -> T {
    a
}

struct A<T> {
    var v: T
    init(_ v: T) {
        self.v = v
    }
}

protocol P {
    associatedtype T
}

extension P {
    func g() -> Int {
        if let n = T.self as? Int16.Type {
            return 1
        }
        return 0
    }
}

extension A: P {}

@inline(never)
func makeA() -> some P {
    A(32)
}

f(Int16(9))

makeA().g()
