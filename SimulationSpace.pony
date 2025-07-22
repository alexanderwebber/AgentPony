use "collections"
use "random"
use "time"
use "promises"
use "pony_test"
use "./utils"
use "./test"
 
actor SimulationSpace 
    let _sideLength:         USize   val
    let _numCells:           USize   val
    let _timeSteps:          USize   val
    let _monitor:            Monitor
    let _partition:          Partition

    let _cells:              Array[Cell]
    var _cellStates:         Array[U64]
     
    let _rand:               Rand
    let _out:                OutStream

    new create(sideLength': USize, timeSteps': USize, partition': Partition, out': OutStream) =>
        _sideLength = recover val sideLength' end
        _numCells   = _sideLength * _sideLength
        _timeSteps  = timeSteps'

        _cells      = Array[Cell](_numCells)
        _cellStates = Array[U64](_numCells)

        _rand       = Rand.from_u64(Time.nanos())
        _out        = out'

        _monitor    = Monitor(_numCells, _timeSteps, this, _out)
        _partition  = partition'

    be loadRandomPositions() =>

        for i in Range(0, _numCells) do
            let randStatus = _rand.int_unbiased(2)

            if(randStatus == 1) then 
                _cells.push(Cell(i, 1, _out))
                _cellStates.push(1)
            else
                _cells.push(Cell(i, 0, _out))
                _cellStates.push(0)
            end
        end

        _out.print("\nStarting simulation: \n")
        printBoard()

    be loadBlinker() =>
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
        _monitor.start()

    be updateCells() =>
        for cellIndex in Range(0, _cells.size()) do
            let cellNeighborStatuses: Array[U64] iso = Array[U64](8)

            for (x, y) in NeighborFunctions.getNeighborCoordinates().values() do
                let neighbor: USize = NeighborFunctions.calculateNeighbor(x, y, cellIndex, _sideLength)
                try 
                    let neighborStatus: U64 = _cellStates(neighbor)? 
                
                    cellNeighborStatuses.push(neighborStatus)
                end
            end

            try _cells(cellIndex)?.updateStatus(consume cellNeighborStatuses, _monitor) end
            
        end

    be updateCellStates() =>
        for cell in _cells.values() do 
            cell.sendStatusPosition(this)
        end

    be receiveStatusPosition(status: U64, position: USize) =>
        try _cellStates.update(position, status)? else _out.print("no cell at this index") end
        _monitor.incrementUpdateCounter()

    be printBoard() =>
        for i in Range(0, _cellStates.size()) do
            let state = try _cellStates(i)? else _out.print("no value here yet") end

            if ((i % (_sideLength)) == (_sideLength - 1)) and (i != 0) then 
                _out.print(state.string())
            else
                _out.write(state.string() + " ")
            end
        end

        _out.print(" ")