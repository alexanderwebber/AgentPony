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

    let _cells:       Array[(USize, Cell)]
    let _indices:     Array[USize val]
    let _initStates:  Array[USize val]

    new create(sideLength': USize, totalCells': USize, out': OutStream, coordinator': Coordinator, indices': Array[USize val] iso) =>
        _sideLength  = recover val sideLength' end
        _indices     = consume indices'
        _numCells    = _sideLength * _sideLength
        _totalCells  = totalCells'

        _cells       = Array[(USize, Cell)](_numCells)
        _initStates  = Array[USize](_numCells)

        _rand        = Rand.from_u64(Time.nanos())
        _out         = out'

        _coordinator = coordinator'
        
    be initStates() =>
        for index in _indices.values() do
            let randStatus = _rand.int_unbiased(2)

            if(randStatus == 1) then 
                _cells.push((index, Cell(index, 1, _out)))
                _coordinator.loadInitial(index, 1)
            else
                _cells.push((index, Cell(index, 0, _out)))
                _coordinator.loadInitial(index, 0)
            end
        end

    be simStep(globalCellStates: Array[USize] val, globalSideLength: USize) =>
        for cell in _cells.values() do
            let cellNeighborStatuses: Array[USize] iso = Array[USize](8)

            for (x, y) in NeighborFunctions.getNeighborCoordinates().values() do
                let neighbor: USize = NeighborFunctions.calculateNeighbor(x, y, cell._1, globalSideLength)

                try 
                    let neighborStatus: USize = globalCellStates(neighbor)? 
                
                    cellNeighborStatuses.push(neighborStatus)
                end
            end

            cell._2.updateStatus(consume cellNeighborStatuses, _coordinator)
            
        end

    be updateCoordinatorCellStates() =>
        for cell in _cells.values() do 
            cell._2.sendStateAndPosition(_coordinator)
        end