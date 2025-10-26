use "collections"
use "random"
use "time"
use "promises"
use "pony_test"
use "./utils"
use "./test"
 
actor SimulationSpace
    let _sideLength:  USize val
    let _numCells:    USize val
    let _totalCells:  USize val

    let _coordinator: Coordinator
    let _rand:        Rand
    let _out:         OutStream

    let _cells:       Array[Cell]
    var _cellStates:  Array[U64]
    let _indices:     Array[USize val]
    let _initStates:  Array[USize val]

    new create(sideLength': USize, totalCells': USize, out': OutStream, coordinator': Coordinator, indices': Array[USize val] iso) =>
        _sideLength  = recover val sideLength' end
        _indices     = consume indices'
        _numCells    = _sideLength * _sideLength
        _totalCells  = totalCells'

        _cells       = Array[Cell](_numCells)
        _cellStates  = Array[U64](_numCells)
        _initStates  = Array[USize](_numCells)

        _rand        = Rand.from_u64(Time.nanos())
        _out         = out'

        _coordinator = coordinator'
        
    be initStates() =>
        for index in _indices.values() do
            let randStatus = _rand.int_unbiased(2)

            if(randStatus == 1) then 
                _cells.push(Cell(index, 1, _out))
                _coordinator.updateState(index, 1)
            else
                _cells.push(Cell(index, 0, _out))
                _coordinator.updateState(index, 0)
            end

            _coordinator.incrementCellCounter()
            
        end

    be simStep(globalCellStates: Array[USize]) =>
        // request updated cell states from Coordinator

        for cellIndex in Range(0, _cells.size()) do
            let cellNeighborStatuses: Array[U64] iso = Array[U64](8)

            for (x, y) in NeighborFunctions.getNeighborCoordinates().values() do
                let neighbor: USize = NeighborFunctions.calculateNeighbor(x, y, cellIndex, _sideLength)

                try 
                    let neighborStatus: U64 = _cellStates(neighbor)? 
                
                    cellNeighborStatuses.push(neighborStatus)
                end
            end

            try _cells(cellIndex)?.updateStatus(consume cellNeighborStatuses, _coordinator) end
            
        end

    be updateCellStates() =>
        for cell in _cells.values() do 
            cell.sendStatusPosition(this)
        end

    be receiveStatusPosition(status: U64, position: USize) =>
        try _cellStates.update(position, status)? else _out.print("no cell at this index") end
        _coordinator.incrementUpdateCounter()