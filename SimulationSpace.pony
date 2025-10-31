use "collections"
use "random"
use "time"
use "promises"
use "pony_test"
use "./utils"
use "./test"
 
actor SimulationSpace
    let _sideLength:       USize val
    let _globalSideLength: USize val
    let _numCells:         USize val
    let _totalCells:       USize val
    var _counter:          USize
    var _inactiveCounter:  USize


    let _coordinator:      Coordinator
    let _rand:             Rand
    let _out:              OutStream

    let _cells:            Array[(USize, Cell, USize, Array[USize])]
    let _inactiveCells:    Array[USize]
    let _indices:          Array[USize val]
    let _cellPosState:     Array[(USize, USize)]

    new create(sideLength': USize, globalSideLength': USize, totalCells': USize, out': OutStream, coordinator': Coordinator, indices': Array[USize val] iso) =>
        _sideLength       = recover val sideLength' end
        _globalSideLength = globalSideLength'
        _indices          = consume indices'
        _numCells         = _sideLength * _sideLength
        _totalCells       = totalCells'
        _counter          = 0
        _inactiveCounter  = 0

        _cells            = Array[(USize, Cell, USize, Array[USize])](_numCells)
        _inactiveCells    = Array[USize](_numCells)
        _cellPosState     = Array[(USize, USize)](_numCells)

        _rand             = Rand.from_u64(Time.nanos())
        _out              = out'

        _coordinator      = coordinator'
        
    be initStates() =>
        for index in _indices.values() do
            let randStatus                          = _rand.int_unbiased(2)
            let cellNeighborPositions: Array[USize] = Array[USize](8)

            for (x, y) in NeighborFunctions.getNeighborCoordinates().values() do
                let neighbor: USize = NeighborFunctions.calculateNeighbor(x, y, index, _globalSideLength)
                
                cellNeighborPositions.push(neighbor)
            end

            if(randStatus == 1) then 
                _cells.push((index, Cell(index, 1, _out), 1, cellNeighborPositions))
                _cellPosState.push((index, 1))
            else
                _cells.push((index, Cell(index, 0, _out), 0, cellNeighborPositions))
                _cellPosState.push((index, 0))
            end
        end

        let tempCopyCellStates: Array[(USize, USize)] iso = Array[(USize, USize)](_numCells)

        for value in _cellPosState.values() do 
            tempCopyCellStates.push(value)
        end

        _coordinator.cellStatesUpdated(consume tempCopyCellStates)

    be simStep(globalCellStates: Array[USize] val) =>
        _cellPosState.clear()
        _inactiveCells.clear()

        for cell in _cells.values() do
            let cellNeighborStatuses: Array[USize] iso = Array[USize](8)

            for neighbor in cell._4.values() do
                try
                    let neighborStatus: USize = globalCellStates(neighbor)? 
                
                    cellNeighborStatuses.push(neighborStatus)
                end
            end

            cell._2.updateStatus(consume cellNeighborStatuses, this)
        end


    be localCellStatesCalculated(changed: Bool, index: USize, state: USize) =>
        _cellPosState.push((index, state))

        _counter = _counter + 1

        if(_counter == _numCells) then 
            let tempCopyCellStates: Array[(USize, USize)] iso = Array[(USize, USize)](_numCells)

            for value in _cellPosState.values() do 
                tempCopyCellStates.push(value)
            end

            _counter = 0
            _coordinator.cellStatesUpdated(consume tempCopyCellStates)
        end


