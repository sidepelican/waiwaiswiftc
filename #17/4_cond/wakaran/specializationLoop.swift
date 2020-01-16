
class A {
    init() { }

    var count: Int16 = 0
    func f<T>(_ v: T) -> T {
        count += 1
        if count > 100 {
            return v
        }

        return g(v)
    }

    func g<T>(_ v: T) -> T {
        if count % 2 == 0 {
            return f(v)
        } else {
            return B(v).v
        }
    }
}

struct B<T> {
    var v: T
    init(_ v: T) {
        self.v = v
    }
}


A().f(Int16(9))
