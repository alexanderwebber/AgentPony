trait CountingHandler
    fun     counter():                USize
    fun     epoch():                  USize
    fun ref updateEpoch(v: USize):    USize
    fun ref updateCounter(v: USize):  USize

    fun ref incrementEpoch() =>
        let v = epoch() + 1
        updateEpoch(v)

    fun ref resetCounter() =>
        updateCounter(0)

    fun ref incrementCounter() =>
        let v = counter() + 1
        updateCounter(v)

    