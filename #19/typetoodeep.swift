struct A<T> {
    var v: T
    init(_ v: T) {
        self.v = v
    }
}

func use<T>(_ v: T) -> T{
    v
}

let a49 = A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(A(Int16(9))))))))))))))))))))))))))))))))))))))))))))))))))
let a50 = A(a49)

use(a49)
use(a50)
