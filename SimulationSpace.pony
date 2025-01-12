class SimulationSpace
    let sideLength: USize val

    new create(sideLength': USize, numCells': USize) =>
        let numCells: USize           = numCells'
        let cells:    Array[LifeCell] = Array[LifeCell](numCells) 
        sideLength                    = recover val sideLength' end

    fun getSideLength(): USize val =>
        sideLength
