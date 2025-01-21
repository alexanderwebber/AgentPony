use "collections"
use "Random"
use "promises"

class SimulationSpace
    let _sideLength: USize val
    let _numCells:   USize val
    let _cells:      Array[Cell]
    let _out:        OutStream
    let _rand:       Rand

    new create(sideLength': USize, out: OutStream) =>
        _sideLength = recover val sideLength' end
        _numCells   = _sideLength * _sideLength
        _cells      = Array[Cell](_numCells) 
        _out        = out
        _rand       = Rand

    fun getSideLength(): USize val =>
        _sideLength

    fun ref loadRandomPositions() =>
        for i in Range(0, _numCells) do 
            _cells.push(Cell(i, _rand.next() % 2, _out))
        end

    fun loadNeighbors() =>
        let neighborCoordinates: Array[(ISize, ISize)] = [(-1, -1); (0, -1); (1, -1); (-1, 0); (1, 0); (-1, 1); (0, 1); (1, 1)]

        for cellIndex in Range(0, _numCells) do
            for (x, y) in neighborCoordinates.values() do

                let neighbor: USize = ((((cellIndex.isize() + x) %% _sideLength.isize()) + (y * _sideLength.isize())) %% (_sideLength * _sideLength).isize()).usize()

                try _cells(cellIndex)?.setNeighbor(_cells(neighbor)?)   end
            end
        end

    fun updateCellStatuses() =>
        for cell in _cells.values() do 
            cell.updateStatus()
        end

    fun printCells() =>
        for i in Range(0, _numCells) do
            try _cells(i)?.printStatus() else _out.print("no cell here") end
        end

    fun printNumCellNeighbors() =>
        for i in Range(0, _numCells) do
            try _cells(i)?.printNumNeighbors() else _out.print("no cell here") end
        end
