trait CountingHandler
    fun     counter():                USize
    fun ref updateCounter(v: USize):  USize

    fun ref resetCounter() =>
        updateCounter(0)

    fun ref incrementCounter() =>
        let v = counter() + 1
        updateCounter(v)

    