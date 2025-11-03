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

    let _coordinator:      Coordinator
    let _rand:             Rand
    let _out:              OutStream

    let _cells:            Array[(USize, SchellingCell, USize, Array[USize])]
    let _emptyCells:       Array[(USize, USize)]
    let _indices:          Array[USize val]
    let _cellPosState:     Array[(USize, USize, Bool)]

    new create(sideLength': USize, globalSideLength': USize, totalCells': USize, out': OutStream, coordinator': Coordinator, indices': Array[USize val] iso) =>
        _sideLength       = recover val sideLength' end
        _globalSideLength = globalSideLength'
        _indices          = consume indices'
        _numCells         = _sideLength * _sideLength
        _totalCells       = totalCells'
        _counter          = 0

        _cells            = Array[(USize, SchellingCell, USize, Array[USize])](_numCells)
        _cellPosState     = Array[(USize, USize, Bool)](_numCells)
        _emptyCells       = Array[(USize, USize)](_numCells)

        _rand             = Rand.from_u64(Time.nanos())
        _out              = out'

        _coordinator      = coordinator'
        
    be initStates() =>
        for index in _indices.values() do
            let randStatus                          = _rand.int_unbiased(3)
            let cellNeighborPositions: Array[USize] = Array[USize](8)

            for (x, y) in NeighborFunctions.getNeighborCoordinates().values() do
                let neighbor: USize = NeighborFunctions.calculateNeighbor(x, y, index, _globalSideLength)
                
                cellNeighborPositions.push(neighbor)
            end

            match randStatus
            | 0 =>
                _cells.push((index, SchellingCell(index, 0, 3, _out), 0, cellNeighborPositions))
                _cellPosState.push((index, 0, true))
            | 1 =>
                _cells.push((index, SchellingCell(index, 1, 3, _out), 1, cellNeighborPositions))
                _cellPosState.push((index, 1, true))
            else
                _cells.push((index, SchellingCell(index, 2, 3, _out), 2, cellNeighborPositions))
                _cellPosState.push((index, 2, true))
            end
        end

        let tempCopyCellStates:  Array[(USize, USize, Bool)] iso = createSendableCopy()
        let tempEmptyCellStates: Array[(USize, USize)]       iso = createSendableEmpty()

        _coordinator.schellingUpdate(consume tempCopyCellStates, consume tempEmptyCellStates)

    be simStep(globalCellStates: Array[USize] val) =>
        _cellPosState.clear()
        _emptyCells.clear()
        changeLocalStates(globalCellStates)

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


    be localSatisfactionCalculated(index: USize, state: USize, satisfaction: Bool) =>
        _cellPosState.push((index, state, satisfaction))

        if state == 0 then _emptyCells.push((index, state)) end

        _counter = _counter + 1

        if(_counter == _numCells) then 
            let tempCopyCellStates:  Array[(USize, USize, Bool)] iso = createSendableCopy()
            let tempEmptyCellStates: Array[(USize, USize)]       iso = createSendableEmpty()

            _coordinator.schellingUpdate(consume tempCopyCellStates, consume tempEmptyCellStates)
            _counter = 0
            
        end

    // be localCellStatesCalculated(changed: Bool, index: USize, state: USize) =>
    //     _cellPosState.push((index, state))

    //     _counter = _counter + 1

    //     if(_counter == _numCells) then 
    //         let tempCopyCellStates: Array[(USize, USize)] iso = createSendableCopy()

    //         _counter = 0
    //         _coordinator.cellStatesUpdated(consume tempCopyCellStates)
    //     end

    fun createSendableCopy(): Array[(USize, USize, Bool)] iso^ =>
        let tempCopyCellStates: Array[(USize, USize, Bool)] iso = Array[(USize, USize, Bool)](_numCells)

        for value in _cellPosState.values() do 
            tempCopyCellStates.push(value)
        end

        tempCopyCellStates

    fun createSendableEmpty(): Array[(USize, USize)] iso^ =>
        let tempCopyCellStates: Array[(USize, USize)] iso = Array[(USize, USize)](_numCells)

        for value in _emptyCells.values() do 
            tempCopyCellStates.push(value)
        end

        tempCopyCellStates

    fun ref changeLocalStates(globalCellStates: Array[USize] val) =>
        for cell in _cells.values() do
            try 
                let position = cell._2.getPosition()
                let status   = globalCellStates(position)?

                cell._2.setStatus(status)
            end
            
        end
