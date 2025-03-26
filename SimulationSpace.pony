use "collections"
use "random"
use "promises"
use "pony_test"
use "./utils"
use "./test"
 
actor SimulationSpace 
    let _sideLength:         USize   val
    let _numCells:           USize   val
    let _timeSteps:          USize   val
    let monitor:             Monitor

    let _cells:              Array[Cell]
    var _cellStates:         Array[U64]
    var _statesOutput:       Array[U64]
     
    let _rand:               Rand
    let _out:                OutStream

    new create(sideLength': USize, out': OutStream, timeSteps': USize) =>
        _sideLength         = recover val sideLength' end
        _numCells           = _sideLength * _sideLength
        _timeSteps          = timeSteps'

        _cells              = Array[Cell](_numCells)
        _cellStates         = Array[U64](_numCells)
        _statesOutput       = Array[U64](_timeSteps)
        
        _rand               = Rand
        _out                = out'
        monitor             = Monitor(_numCells, _timeSteps, this, _out)

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
        monitor.start()

    be updateCells() =>
        for cellIndex in Range(0, _cells.size()) do
            let cellNeighborStatuses: Array[U64] iso = Array[U64](8)

            for (x, y) in NeighborFunctions.getNeighborCoordinates().values() do
                let neighbor:       USize = NeighborFunctions.calculateNeighbor(x, y, cellIndex, _sideLength)
                try 
                    let neighborStatus: U64   = _cellStates(neighbor)? 
                
                    cellNeighborStatuses.push(neighborStatus)
                end

                
            end

            try _cells(cellIndex)?.updateStatus(consume cellNeighborStatuses, monitor) end
            
        end

        printBoard()

    be receiveStatusPosition(status: U64, position: USize) =>
        try _cellStates.update(position, status)? else _out.print("no cell at this index") end
        
    be epochFinishedNotification() =>
        _epochFinished = true
        _out.print("made it to epoch finished")

    be simulationFinishedNotification() =>
        _simulationFinished = true

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