use "collections"
use "Random"
use "promises"

class SimulationSpace
    let _sideLength: USize val
    let _numCells:   USize
    let _cells:      Array[Cell tag]
    let _rand:       Rand = Rand
    let _out:        OutStream

    new create(sideLength': USize, numCells': USize, out: OutStream) =>
        _numCells   = numCells'
        _cells      = Array[Cell](_numCells) 
        _sideLength = recover val sideLength' end
        _out        = out

    fun getSideLength(): USize val =>
        _sideLength

    fun ref loadRandomPositions()? =>
        for i in Range(0, _numCells) do 
            _cells(i)? = Cell(i, _rand.int(4), _out)
        end

    fun printCells()? =>
        for i in Range(0, _numCells) do
            _cells(i)?.printStatus()
        end