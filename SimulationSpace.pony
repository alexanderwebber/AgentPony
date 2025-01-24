use "collections"
use "Random"
use "promises"

class SimulationSpace
    let _sideLength:         USize val
    let _numCells:           USize val
    let _cells:              Array[Cell]
    let _rand:               Rand
    let neighborCoordinates: Array[(ISize, ISize)] = [(-1, -1); (0, -1); (1, -1); (-1, 0); (1, 0); (-1, 1); (0, 1); (1, 1)]

    new create(sideLength': USize) =>
        _sideLength = recover val sideLength' end
        _numCells   = _sideLength * _sideLength
        _cells      = Array[Cell](_numCells)
        _rand       = Rand

    fun getSideLength(): USize val =>
        _sideLength

    fun ref loadRandomPositions() =>
        for i in Range(0, _numCells) do 
            _cells.push(Cell(i, _rand.next() % 2))
        end

    fun loadNeighbors() =>
        for cellIndex in Range(0, _numCells) do
            for (x, y) in neighborCoordinates.values() do
                let neighbor: USize = calculateNeighbor(x, y, cellIndex, _sideLength)

                try _cells(cellIndex)?.setNeighbor(_cells(neighbor)?) end
            end
        end

    fun updateCellStatuses() =>
        for cell in _cells.values() do
            cell.freezeNeighbors()
        end

        for cell in _cells.values() do
            cell.updateStatus()
        end

    fun runGameOfLife(timeSteps: USize) =>
        for i in Range(0, timeSteps) do 
            updateCellStatuses()
        end

    fun calculateNeighbor(xCoordinate: ISize, yCoordinate: ISize, cellIndex: USize, sideLength: USize): USize =>
        let x:  ISize = (cellIndex % sideLength).isize()
        let y:  ISize = (cellIndex / sideLength).isize()

        let nx: ISize = (x + xCoordinate + sideLength.isize()) % sideLength.isize()
        let ny: ISize = (y + yCoordinate + sideLength.isize()) % sideLength.isize()

        (nx + (ny * sideLength.isize())).usize()

    fun returnNeighborSum(cellIndex: USize): USize =>
        var neighborSum: USize = 0

        for (x, y) in neighborCoordinates.values() do
            let neighbor: USize = calculateNeighbor(x, y, cellIndex, _sideLength)
            
            neighborSum         = neighborSum + neighbor
        end

        neighborSum