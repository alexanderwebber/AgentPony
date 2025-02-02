use "collections"
use "random"
use "promises"
use "pony_test"
use "./utils"
use "./test"
 
actor SimulationSpace 
    let _sideLength:         USize val
    let _numCells:           USize val
    let _cells:              Array[Cell]
    var _cellStates:         Array[(U64, USize)]
    let _rand:               Rand
    let _out:                OutStream

    new create(sideLength': USize, out': OutStream) =>
        _sideLength       = recover val sideLength' end
        _numCells         = _sideLength * _sideLength
        _cells            = Array[Cell](_numCells)
        _cellStates       = Array[(U64, USize)](_numCells)
        _rand             = Rand
        _out              = out'

    be loadRandomPositions() =>
        for i in Range(0, _numCells) do 
            _cells.push(Cell(i, _rand.next() % 2, _out))
        end

    be loadBlinkerFive() =>
        for i in Range(0, _numCells) do 
            if (i == 7) or (i == 12) or (i == 17) then 
                _cells.push(Cell(i, 1, _out))
            else
                _cells.push(Cell(i, 0, _out))
            end
        end

    be loadNeighbors() =>
        for cellIndex in Range(0, _numCells) do
            for (x, y) in NeighborFunctions.getNeighborCoordinates().values() do
                let neighbor: USize = NeighborFunctions.calculateNeighbor(x, y, cellIndex, _sideLength)

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

    be runGameOfLife(timeSteps: USize) =>
        for i in Range(0, timeSteps) do
            gatherCellStatusesAndExecute()
        end

    fun gatherCellStatusesAndExecute() =>
        let cellStatePromises: Array[Promise[(U64, USize)]] = Array[Promise[(U64, USize)]](_numCells)

        for cell in _cells.values() do
            let p = Promise[(U64, USize)]
            cell.getStatusAndPosition(p)
            cellStatePromises.push(p)
        end

        Promises[(U64, USize)].join(cellStatePromises.values())
        .next[None](recover this~copyStateAndPrint() end)

    be copyStateAndPrint(states: Array[(U64, USize)] val) =>
        for i in Range(0, _numCells) do 
            try 
                _cellStates.update(i, states(i)?)?
            else 
                try 
                    _cellStates.push(states(i)?)
            end
        end

        _cellStates = SortTuple(_cellStates)
        NeighborFunctions.printBoard(_cellStates, _out, _sideLength)

    fun testNeighborIndices(topLeftSum: USize, middleSum: USize, h: TestHelper) =>
        TestsPrimitive.testNeighborIndices(topLeftSum, middleSum, h, _sideLength)

    fun testEndStateBlinkerFive(evenOdd: U8, h: TestHelper) =>
        TestsPrimitive.testEndStateBlinkerFive(evenOdd, h, _cellStates, _numCells)