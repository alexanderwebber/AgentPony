trait EpochHandler
    fun     epoch():                  USize
    fun ref updateEpoch(v: USize):    USize

    fun ref incrementEpoch() =>
        let v = epoch() + 1
        updateEpoch(v)