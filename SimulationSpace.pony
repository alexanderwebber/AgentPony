class SimulationSpace
    let sideLength: USize val

    new create(sideLength': USize) =>
        sideLength = recover val sideLength' end

    fun getSideLength(): USize val =>
        sideLength
