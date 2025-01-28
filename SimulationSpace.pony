use "collections"
use "Random"
use "promises"
use "pony_test"
 
actor SimulationSpace 
    let _sideLength:         USize val
    let _numCells:           USize val
    let _cells:              Array[Cell]
    let _endCellsStates:     Array[U64]
    let _rand:               Rand
    let neighborCoordinates: Array[(ISize, ISize)] = [(-1, -1); (0, -1); (1, -1); (-1, 0); (1, 0); (-1, 1); (0, 1); (1, 1)]

    new create(sideLength': USize) =>
        _sideLength       = recover val sideLength' end
        _numCells         = _sideLength * _sideLength
        _cells            = Array[Cell](_numCells)
        _endCellsStates   = Array[U64](_numCells)
        _rand             = Rand

    fun getSideLength(): USize val =>
        _sideLength

    be loadRandomPositions() =>
        for i in Range(0, _numCells) do 
            _cells.push(Cell(i, _rand.next() % 2))
        end

    be loadBlinkerFive() =>
        for i in Range(0, _numCells) do 
            if (i == 7) or (i == 12) or (i == 17) then 
                _cells.push(Cell(i, 1))
                
            else
                _cells.push(Cell(i, 0))
            end
        end

    be loadNeighbors() =>
        for cellIndex in Range(0, _numCells) do
            for (x, y) in neighborCoordinates.values() do
                let neighbor: USize = calculateNeighbor(x, y, cellIndex, _sideLength)

                try _cells(cellIndex)?.setNeighbor(_cells(neighbor)?) end
            end
        end

    be testNeighborIndices(topLeftSum: USize, middleSum: USize, h: TestHelper) =>
        h.assert_eq[USize](topLeftSum, returnNeighborSum(0))
        h.assert_eq[USize](middleSum, returnNeighborSum(12))

    be updateCellStatuses() =>
        for cell in _cells.values() do
            cell.freezeNeighbors()
        end

        for cell in _cells.values() do
            cell.updateStatus()
        end

    be runGameOfLife(timeSteps: USize) =>
        for i in Range(0, timeSteps) do 
            updateCellStatuses()
        end

    be gatherCellStatus() =>
        let cellStatePromises: Array[Promise[U64]] = Array[Promise[U64]](_numCells)

        for cell in _cells.values() do
            let p = Promise[U64]
            cell.getStatus(p)
            cellStatePromises.push(p)
        end

        Promises[U64].join(cellStatePromises.values())
        .next[None](recover this~copyEndState() end)

    be copyEndState(cellStates: Array[U64] val) =>
        for state in cellStates.values() do 
            _endCellsStates.push(state)
        end

    be testEndStateBlinkerFive(evenOdd: U8, h: TestHelper) =>
        let correctStates: Array[U64] = Array[U64](_numCells)

        if (evenOdd % 2) == 0 then 
            for i in Range(0, _numCells) do 
                if (i == 7) or (i == 12) or (i == 17) then 
                    correctStates.push(1)
                else
                    correctStates.push(0)
                end
            end

        else
            for i in Range(0, _numCells) do 
                if (i == 11) or (i == 12) or (i == 13) then 
                    correctStates.push(1)
                else
                    correctStates.push(0)
                end
            end
        end

        h.assert_array_eq[U64](correctStates, _endCellsStates)

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