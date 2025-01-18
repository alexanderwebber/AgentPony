use "collections"
use "Random"
use "promises"

class SimulationSpace
    let _sideLength: ISize val
    let _numCells:   USize val
    let _cells:      Array[Cell]
    let _out:        OutStream
    let _rand:       Rand

    new create(sideLength': ISize, out: OutStream) =>
        _sideLength = recover val sideLength' end
        _numCells   = _sideLength * _sideLength
        _cells      = Array[Cell](_numCells) 
        _out        = out
        _rand       = Rand

    fun getSideLength(): ISize val =>
        _sideLength

    fun ref loadRandomPositions() =>
        for i in Range(0, _numCells) do 
            _cells.push(Cell(i, _rand.next() % 4, _out))
        end

    fun printCells() =>
        for i in Range(0, _numCells) do
            try _cells(i)?.printStatus() else _out.print("no cell here") end
        end

    fun loadNeighbors() =>

        let neighborCoordinates: Array[(ISize, ISize)] = [(-1, -1); (0, -1); (1, -1); (-1, 0); (1, 0); (-1, 1); (0, 1); (1, 1)]
        // Assuming periodic boundary conditions
        // (((_position +/- 1/0) % sideLength) +/- sideLength / 0) % (sideLength * sideLength)
        for cellIndex in Range(0, _numCells) do
            var i: USize = 0
            for (x, y) in neighborCoordinates.values() do
                let neighbor = (((cellIndex + x) % _sideLength) + (y * _sideLength)) % (_sideLength * _sideLength)

                try _cells(cellIndex)?.setNeighbor(_cells(i)?)   end

                i = i + 1
            end
        end