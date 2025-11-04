use "collections"
use "random"
use "time"
use "promises"
use "pony_test"
use "./utils"
use "./test"

actor SimulationSpace is (CountingHandler & EpochHandler)
    let _sideLength:            USize val
    let _globalSideLength:      USize val
    let _numCells:              USize val
    let _totalCells:            USize val
    let _position:              USize val
    let _timeSteps:             USize val
    var _counter:               USize
    var _epoch:                 USize
    var _partitionCounter:      USize

    let _coordinator:           Coordinator
    let _rand:                  Rand
    let _out:                   OutStream

    let _cells:                 Array[(USize, Cell, USize, Array[USize])]
    let _neighboringPartitions: Array[SimulationSpace]
    let _indices:               Array[(USize val, USize val)]
    let _cellPosState:          Array[(USize, USize)]
    let _nextCellPosState:      Array[(USize, USize)]

    new create(sideLength': USize, globalSideLength': USize, totalCells': USize, position': USize, timeSteps': USize, out': OutStream, coordinator': Coordinator, indices': Array[(USize val, USize val)] iso) =>
        _sideLength            = recover val sideLength' end
        _globalSideLength      = globalSideLength'
        _indices               = consume indices'
        _numCells              = _sideLength * _sideLength
        _totalCells            = totalCells'
        _position              = position'
        _timeSteps             = timeSteps'
        _counter               = 0
        _epoch                 = 0
        _partitionCounter      = 0

        _cells                 = Array[(USize, Cell, USize, Array[USize])](_totalCells)
        _cellPosState          = Array[(USize, USize)](_numCells)
        _nextCellPosState      = Array[(USize, USize)](_numCells)
        _neighboringPartitions = Array[SimulationSpace]

        _rand                  = Rand.from_u64(Time.nanos())
        _out                   = out'

        _coordinator           = coordinator'
    
    be initCells() =>
        assignCellNeighbors()

        let sendablePositionsStates: Array[(USize, USize)] val = createSendableCopy()
        let sendableEpoch:           USize val                 = recover val _epoch end

        sendNeighbors()
        _coordinator.cellStatesUpdated(sendableEpoch, sendablePositionsStates)

    be simStep() =>
        for cell in _cells.values() do
            let cellNeighborStatuses: Array[USize] iso = Array[USize](8)

            for neighbor in cell._4.values() do
                for posState in _cellPosState.values() do 
                    if posState._1 == neighbor then
                        cellNeighborStatuses.push(posState._2)
                    end
                end
            end

            cell._2.updateStatus(consume cellNeighborStatuses, this)
        end

    be localCellStatesCalculated(changed: Bool, index: USize, state: USize) =>
        _nextCellPosState.push((index, state))

        incrementCounter()

        if(_counter == _numCells) then
            _cellPosState.clear()
            for value in _nextCellPosState.values() do 
                _cellPosState.push(value)
            end

            let sendablePositionsStates: Array[(USize, USize)] val = createSendableCopy()
            let sendableEpoch:           USize val                 = recover val _epoch end

            if(_epoch == _timeSteps) then 
                _coordinator.cellStatesUpdated(sendableEpoch, sendablePositionsStates)
            else
                _coordinator.cellStatesUpdated(sendableEpoch, sendablePositionsStates)
                sendNeighbors()
                incrementEpoch()
                _nextCellPosState.clear()
            end

            resetCounter()

        end

    be sendNeighbors() =>
        let sendablePositionsStates: Array[(USize, USize)] val = createSendableCopy()

        for partition in _neighboringPartitions.values() do 
            partition.collectNeighborCellPositionsStates(_epoch, sendablePositionsStates)
        end

    be collectNeighborCellPositionsStates(epoch': USize, ghostCells: Array[(USize, USize)] val) =>
        if epoch' != _epoch then 
            this.collectNeighborCellPositionsStates(epoch', ghostCells)
        else
            _partitionCounter = _partitionCounter + 1
            
            for cell in ghostCells.values() do
                if(_cellPosState.contains(cell) == false) then
                    _cellPosState.push(cell)
                end
            end
        end
        

        if _partitionCounter == _neighboringPartitions.size() then 
            _partitionCounter = 0

            simStep()
        end

    be addPartition(partition: SimulationSpace) => 
        _neighboringPartitions.push(partition)

        _coordinator.initBarrier()

    fun ref assignCellNeighbors() =>
        for index in _indices.values() do
            let randStatus                          = _rand.int_unbiased(2)
            let cellNeighborPositions: Array[USize] = Array[USize](8)

            for (x, y) in NeighborFunctions.getNeighborCoordinates().values() do
                let neighbor: USize = NeighborFunctions.calculateNeighbor(x, y, index._1, _globalSideLength)
                
                cellNeighborPositions.push(neighbor)
            end

            _cells.push((index._1, Cell(index._1, index._2, _out), 1, cellNeighborPositions))
            _cellPosState.push((index._1, index._2))
        end

    fun createSendableCopy(): Array[(USize, USize)] val =>
        let tempCopyCellStates: Array[(USize, USize)] iso = Array[(USize, USize)](_numCells)

        for value in _cellPosState.values() do 
            tempCopyCellStates.push(value)
        end

        let sendablePositionsStates: Array[(USize, USize)] val = consume tempCopyCellStates
        sendablePositionsStates


    fun     counter():               USize => _counter
    fun     epoch():                 USize => _epoch
    fun ref updateEpoch(v: USize):   USize => _epoch   = v
    fun ref updateCounter(v: USize): USize => _counter = v

    

    // be initSchelling() =>
    //     for index in _indices.values() do
    //         let randStatus                          = _rand.int_unbiased(3)
    //         let cellNeighborPositions: Array[USize] = Array[USize](8)

    //         for (x, y) in NeighborFunctions.getNeighborCoordinates().values() do
    //             let neighbor: USize = NeighborFunctions.calculateNeighbor(x, y, index, _globalSideLength)
                
    //             cellNeighborPositions.push(neighbor)
    //         end

    //         match randStatus
    //         | 0 =>
    //             _cells.push((index, SchellingCell(index, 0, 3, _out), 0, cellNeighborPositions))
    //             _cellPosState.push((index, 0))
    //         | 1 =>
    //             _cells.push((index, SchellingCell(index, 1, 3, _out), 1, cellNeighborPositions))
    //             _cellPosState.push((index, 1))
    //         else
    //             _cells.push((index, SchellingCell(index, 2, 3, _out), 2, cellNeighborPositions))
    //             _cellPosState.push((index, 2))
    //         end
    //     end

    //     let tempCopyCellStates: Array[(USize, USize)] iso = Array[(USize, USize)](_numCells)

    //     for value in _cellPosState.values() do 
    //         tempCopyCellStates.push(value)
    //     end

    //     _coordinator.cellStatesUpdated(consume tempCopyCellStates)

    // be localSatisfactionCalculated(satisfaction: Bool, index: USize, state: USize) =>
    //     _cellPosState.push((index, state))

    //     incrementCounter()

    //     if(_counter == _numCells) then 
    //         let tempCopyCellStates: Array[(USize, USize)] iso = Array[(USize, USize)](_numCells)

    //         for value in _cellPosState.values() do 
    //             tempCopyCellStates.push(value)
    //         end

    //         resetCounter()
    //         _coordinator.cellStatesUpdated(consume tempCopyCellStates)
    //     end