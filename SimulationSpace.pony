use "collections"
use "random"
use "promises"
use "pony_test"
use "./utils"
use "./test"
 
actor SimulationSpace 
    let _sideLength:   USize val
    let _numCells:     USize val
    let _timeSteps:    USize val
    let _cells:        Array[Cell]
    var _cellStates:   Array[U64]
    var _statesOutput: Array[U64]
    let _rand:         Rand
    let _out:          OutStream

    new create(sideLength': USize, out': OutStream, timeSteps': USize) =>
        _sideLength   = recover val sideLength' end
        _numCells     = _sideLength * _sideLength
        _timeSteps    = timeSteps'
        _cells        = Array[Cell](_numCells)
        _cellStates   = Array[U64](_numCells)
        _statesOutput = Array[U64](_timeSteps)
        _rand         = Rand
        _out          = out'

    be loadRandomPositions() =>
        for i in Range(0, _numCells) do 
            _cells.push(Cell(i, _rand.next() % 2, _out))
        end

        _out.print("\nStarting simulation: \n")

    be loadBlinkerFive() =>
        for i in Range(0, _numCells) do 
            if (i == 7) or (i == 12) or (i == 17) then 
                _cells.push(Cell(i, 1, _out))
                _cellStates.push(1)
            else
                _cells.push(Cell(i, 0, _out))
                _cellStates.push(0)
            end
        end

        _out.print("\nStarting simulation: \n")
        printBoard()

    be runGameOfLife() =>
        for i in Range(0, _timeSteps) do
            updateCellStatuses()
            try updateCells()? end
        end
        
    // probably need to make this one file, behaviors are hard to synchronize
    fun updateCellStatuses() =>
        for cell in _cells.values() do 
            let p = Promise[U64]
            cell.sendStatusPosition(this, p)
        end

    fun updateCells()? =>
        for cellIndex in Range(0, _cells.size()) do
            let cellNeighborStatuses: Array[U64] iso = Array[U64](8)

            for (x, y) in NeighborFunctions.getNeighborCoordinates().values() do
                let neighbor:       USize = NeighborFunctions.calculateNeighbor(x, y, cellIndex, _sideLength)
                let neighborStatus: U64   = _cellStates(neighbor)?

                cellNeighborStatuses.push(neighborStatus)
            end

            _cells(cellIndex)?.updateStatus(consume cellNeighborStatuses)
            
        end

    be receiveStatusPosition(status: U64, position: USize) =>
        try _cellStates.update(position, status)? else _out.print("no cell at this index") end
        
    fun printBoard() =>
        for i in Range(0, _cellStates.size()) do
            let state = try _cellStates(i)? else _out.print("no value here yet") end

            if ((i % (_sideLength)) == (_sideLength - 1)) and (i != 0) then 
                _out.print(state.string())
            else
                _out.write(state.string() + " ")
            end
        end

        _out.print(" ")

    be testNeighborIndices(topLeftSum: USize, middleSum: USize, h: TestHelper) =>
        h.assert_eq[USize](topLeftSum, NeighborFunctions.returnNeighborSum(0,  _sideLength))
        h.assert_eq[USize](middleSum,  NeighborFunctions.returnNeighborSum(12, _sideLength))

    be testEndStateBlinkerFive(evenOdd: U8, h: TestHelper) =>
            let correctStates:  Array[U64] = Array[U64](_numCells)
            let cellOnlyStates: Array[U64] = Array[U64](_numCells)
            
            for i in Range(0, _numCells) do 
                try cellOnlyStates(i)? = _cellStates(i)? end
            end

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

            h.assert_array_eq[U64](correctStates, cellOnlyStates)