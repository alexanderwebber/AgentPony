use "collections"
use "Random"

class SimulationSpace
    let sideLength: USize val
    let numCells:   USize
    let cells:      Array[Cell tag]
    let rand:       Rand = Rand

    new create(sideLength': USize, numCells': USize) =>
        numCells   = numCells'
        cells      = Array[Cell](numCells) 
        sideLength = recover val sideLength' end

    fun getSideLength(): USize val =>
        sideLength

    fun ref loadRandomPositions()? =>
        for i in Range(0, numCells) do 
            cells(i)? = Cell(i, rand.int(4))
        end
