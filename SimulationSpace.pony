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
            _cells.push(Cell(i, _rand.next() % 4, _out))
        end

    fun printCells() =>
        for i in Range(0, _numCells) do
            try _cells(i)?.printStatus() else _out.print("no cell here") end
        end

    fun loadNeighbors() =>
        // Assuming periodic boundary conditions
        // (((_position +/- 1/0) % sideLength) +/- sideLength / 0) % (sideLength * sideLength)
        for i in Range(0, _numCells) do
            let neighborOne   = (((i - 1) % _sideLength) - _sideLength) % (_sideLength * _sideLength)
            let neighborTwo   = (((i)     % _sideLength) - _sideLength) % (_sideLength * _sideLength)
            let neighborThree = (((i + 1) % _sideLength) - _sideLength) % (_sideLength * _sideLength)

            let neighborFour  = (((i - 1) % _sideLength)) % (_sideLength * _sideLength)
            let neighborFive  = (((i + 1) % _sideLength)) % (_sideLength * _sideLength)

            let neighborSix   = (((i - 1) % _sideLength) + _sideLength) % (_sideLength * _sideLength)
            let neighborSeven = (((i)     % _sideLength) + _sideLength) % (_sideLength * _sideLength)
            let neighborEight = (((i + 1) % _sideLength) + _sideLength) % (_sideLength * _sideLength)

            try _cells(i)?.setNeighbor(_cells(neighborOne)?)   end
            try _cells(i)?.setNeighbor(_cells(neighborTwo)?)   end
            try _cells(i)?.setNeighbor(_cells(neighborThree)?) end
            try _cells(i)?.setNeighbor(_cells(neighborFour)?)  end
            try _cells(i)?.setNeighbor(_cells(neighborFive)?)  end
            try _cells(i)?.setNeighbor(_cells(neighborSix)?)   end
            try _cells(i)?.setNeighbor(_cells(neighborSeven)?) end
            try _cells(i)?.setNeighbor(_cells(neighborEight)?) end

        end