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
    let _simulationType:   String
    var _counter:          USize

    let _coordinator:      Coordinator
    let _rand:             Rand
    let _out:              OutStream

    let _cells:            Array[(USize, SchellingCell, USize, Array[USize])]
    let _gofCells:         Array[(USize, Cell, USize, Array[USize])]
    let _emptyCells:       Array[(USize, USize)]
    let _inactiveCells:    Array[USize]
    let _indices:          Array[USize val]
    let _cellPosState:     Array[(USize, USize, Bool)]
    let _gofCellStates:    Array[(USize, USize)]

    new create(sideLength': USize, globalSideLength': USize, totalCells': USize, 
               simulationType': String, out': OutStream, coordinator': Coordinator, 
               indices': Array[USize val] iso) =>
        _sideLength       = recover val sideLength' end
        _globalSideLength = globalSideLength'
        _indices          = consume indices'
        _numCells         = _sideLength * _sideLength
        _totalCells       = totalCells'
        _simulationType   = simulationType'
        _counter          = 0

        _cells            = Array[(USize, SchellingCell, USize, Array[USize])](_numCells)
        _gofCells         = Array[(USize, Cell, USize, Array[USize])](_numCells)
        _cellPosState     = Array[(USize, USize, Bool)](_numCells)
        _gofCellStates    = Array[(USize, USize)](_numCells)
        _emptyCells       = Array[(USize, USize)](_numCells)
        _inactiveCells    = Array[USize](_numCells)

        _rand             = Rand.from_u64(Time.nanos())
        _out              = out'
        _coordinator      = coordinator'
        
    be initStates() =>
        if _simulationType == "gameoflife" then
            initGameOfLife()
        else
            initSchelling()
        end

        be initGameOfLife() =>
        for index in _indices.values() do
            let randStatus: USize = _rand.int_unbiased(2).usize()
            let cellNeighborPositions: Array[USize] = Array[USize](8)

            for (x, y) in NeighborFunctions.getNeighborCoordinates().values() do
                let neighbor: USize = NeighborFunctions.calculateNeighbor(x, y, index, _globalSideLength)
                cellNeighborPositions.push(neighbor)
            end

            _gofCells.push((index, Cell(index, randStatus, _out), randStatus, cellNeighborPositions))
            _gofCellStates.push((index, randStatus))
        end

        let tempCopyCellStates: Array[(USize, USize)] iso = createSendableCopyGoF()
        _coordinator.gameOfLifeUpdate(consume tempCopyCellStates)

    be initSchelling() =>
        for index in _indices.values() do
            let randStatus                          = _rand.int_unbiased(3)
            let cellNeighborPositions: Array[USize] = Array[USize](8)
            let threshhold:            USize        = 2

            for (x, y) in NeighborFunctions.getNeighborCoordinates().values() do
                let neighbor: USize = NeighborFunctions.calculateNeighbor(x, y, index, _globalSideLength)
                cellNeighborPositions.push(neighbor)
            end

            match randStatus
            | 0 =>
                _cells.push((index, SchellingCell(index, 0, threshhold, _out), 0, cellNeighborPositions))
                _cellPosState.push((index, 0, true))
            | 1 =>
                _cells.push((index, SchellingCell(index, 1, threshhold, _out), 1, cellNeighborPositions))
                _cellPosState.push((index, 1, true))
            else
                _cells.push((index, SchellingCell(index, 2, threshhold, _out), 2, cellNeighborPositions))
                _cellPosState.push((index, 2, true))
            end
        end

        let tempCopyCellStates:  Array[(USize, USize, Bool)] iso = createSendableCopy()
        let tempEmptyCellStates: Array[(USize, USize)]       iso = createSendableEmpty()

        _coordinator.schellingUpdate(consume tempCopyCellStates, consume tempEmptyCellStates)

    be simStep(globalCellStates: Array[USize] val) =>
        if _simulationType == "gameoflife" then
            simStepGameOfLife(globalCellStates)
        else
            simStepSchelling(globalCellStates)
        end

    be simStepGameOfLife(globalCellStates: Array[USize] val) =>
        for cell in _gofCells.values() do
            let cellNeighborStatuses: Array[USize] iso = Array[USize](8)

            for neighbor in cell._4.values() do
                try
                    let neighborStatus: USize = globalCellStates(neighbor)? 
                    cellNeighborStatuses.push(neighborStatus)
                end
            end

            cell._2.updateStatus(consume cellNeighborStatuses, this)
        end

    be simStepSchelling(globalCellStates: Array[USize] val) =>
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

    be localCellStatesCalculated(changed: Bool, position: USize, status: USize, inactive: Bool) =>
        let wasInactive = _inactiveCells.contains(position)
    
        if inactive and (not wasInactive) then
            _inactiveCells.push(position)
        elseif (not inactive) and wasInactive then
            try
                let deleteIndex = _inactiveCells.find(position)?
                _inactiveCells.delete(deleteIndex)?
            end
            _gofCellStates.push((position, status))
            _counter = _counter + 1
        elseif not inactive then
            _gofCellStates.push((position, status))
            _counter = _counter + 1
        end

        if _counter == (_numCells - _inactiveCells.size()) then
            let tempCopyCellStates: Array[(USize, USize)] iso = createSendableCopyGoF()
            _coordinator.gameOfLifeUpdate(consume tempCopyCellStates)
            _counter = 0
            _gofCellStates.clear()
        end

    be localSatisfactionCalculated(index: USize, state: USize, satisfaction: Bool, inactive: Bool) =>
        if state == 0 then _emptyCells.push((index, state)) end

        let wasInactive = _inactiveCells.contains(index)
    
        if inactive and (not wasInactive) then
            _inactiveCells.push(index)
        elseif (not inactive) and wasInactive then
            try
                let deleteIndex = _inactiveCells.find(index)?
                _inactiveCells.delete(deleteIndex)?
            end
            _cellPosState.push((index, state, satisfaction))
            _counter = _counter + 1
        elseif not inactive then
            _cellPosState.push((index, state, satisfaction))
            _counter = _counter + 1
        end

        if _counter == (_numCells - _inactiveCells.size()) then 
            let tempCopyCellStates:  Array[(USize, USize, Bool)] iso = createSendableCopy()
            let tempEmptyCellStates: Array[(USize, USize)]       iso = createSendableEmpty()

            _coordinator.schellingUpdate(consume tempCopyCellStates, consume tempEmptyCellStates)
            _counter = 0
            _emptyCells.clear()
            _cellPosState.clear()
        end

    fun createSendableCopy(): Array[(USize, USize, Bool)] iso^ =>
        let tempCopyCellStates: Array[(USize, USize, Bool)] iso = Array[(USize, USize, Bool)](_numCells)

        for value in _cellPosState.values() do 
            tempCopyCellStates.push(value)
        end

        tempCopyCellStates

    fun createSendableCopyGoF(): Array[(USize, USize)] iso^ =>
        let tempCopyCellStates: Array[(USize, USize)] iso = Array[(USize, USize)](_numCells)

        for value in _gofCellStates.values() do 
            tempCopyCellStates.push(value)
        end

        tempCopyCellStates

    fun createSendableEmpty(): Array[(USize, USize)] iso^ =>
        let tempCopyCellStates: Array[(USize, USize)] iso = Array[(USize, USize)](_numCells)

        for value in _emptyCells.values() do 
            tempCopyCellStates.push(value)
        end

        tempCopyCellStates

    be reportActivity(partitionId: USize, coordinator: Coordinator) =>
        let activeCount: USize = _numCells - _inactiveCells.size()
        
        let activeCellIndices: Array[USize] iso = Array[USize]
        for index in _indices.values() do
            if not _inactiveCells.contains(index) then
                activeCellIndices.push(index)
            end
        end
        
        coordinator.receiveActivityReport(partitionId, activeCount, consume activeCellIndices)

    fun ref changeLocalStates(globalCellStates: Array[USize] val) =>
        for cell in _cells.values() do
            try 
                let position = cell._2.getPosition()
                let status   = globalCellStates(position)?

                cell._2.setStatus(status)
            end
        end

    be initStatesWithCurrentState(globalState: Array[USize] val) =>
        if _simulationType == "gameoflife" then
            for index in _indices.values() do
                let currentStatus: USize = try globalState(index)? else 0 end
                let cellNeighborPositions: Array[USize] = Array[USize](8)

                for (x, y) in NeighborFunctions.getNeighborCoordinates().values() do
                    let neighbor: USize = NeighborFunctions.calculateNeighbor(x, y, index, _globalSideLength)
                    cellNeighborPositions.push(neighbor)
                end

                _gofCells.push((index, Cell(index, currentStatus, _out), currentStatus, cellNeighborPositions))
                _gofCellStates.push((index, currentStatus))
            end

            _coordinator.partitionReady()
        else
            initSchelling()
        end