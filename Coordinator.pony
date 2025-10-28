use "collections"
use "random"
use "time"
use "files"

actor Coordinator
    let _sideLength:    USize
    let _timeSteps:     USize
    let _numPartitions: USize
    let _numCells:      USize
    var _cellCounter:   USize
    var _updateCounter: USize
    var _epoch:         USize
    var _simEnd:        Bool

    let _rand:          Rand
    let _file:          File
    let _out:           OutStream
    
    let _partitions:    Array[SimulationSpace]
    let _cellStates:    Array[USize]

    new create(sideLength': USize, timeSteps': USize, numPartitions': USize, out': OutStream, file': File iso) =>
        _sideLength    = sideLength'
        _timeSteps     = timeSteps'
        _out           = out'
        _numPartitions = numPartitions'
        _numCells      = _sideLength * _sideLength

        _cellCounter   = 0
        _epoch         = 0
        _updateCounter = 0
        _simEnd        = false
        _rand          = Rand.from_u64(Time.nanos())
        _file          = consume file'
        
        _partitions    = Array[SimulationSpace](_numPartitions)
        _cellStates    = Array[USize](_numCells)     

    be initSimulation() =>
        partitionSimulationSpace()
        loadZeros()

        for partition in _partitions.values() do 
            partition.initStates()
        end

    fun ref partitionSimulationSpace() =>
        let sideLengthPerPartition: USize = ((_sideLength.f64() * _sideLength.f64()) / (_numPartitions.f64())).sqrt().usize()
        let leftToRightCell:        USize = sideLengthPerPartition
        let topToBottomCell:        USize = sideLengthPerPartition * _sideLength
        var startIndex:             USize = 0
        var leftToRightIndex:       USize = 0
        var topToBottomIndex:       USize = 0

        for i in Range(0, _numPartitions.f64().sqrt().usize()) do
            for j in Range(0, _numPartitions.f64().sqrt().usize()) do
                let indices: Array[USize] iso = Array[USize](sideLengthPerPartition * sideLengthPerPartition)

                for k in Range(0, sideLengthPerPartition) do
                    var index: USize val = startIndex

                    for l in Range(0, sideLengthPerPartition) do 
                        indices.push(index)
                        index = index + 1
                    end

                    startIndex = startIndex + _sideLength
                end
                
                _partitions.push(SimulationSpace(sideLengthPerPartition, _numCells, _out, this, consume indices))

                leftToRightIndex = leftToRightIndex + leftToRightCell
                startIndex       = leftToRightIndex

            end

            topToBottomIndex = topToBottomIndex + topToBottomCell
            leftToRightIndex = topToBottomIndex
            startIndex       = topToBottomIndex
        end

    fun ref loadZeros() =>
        for index in Range(0, _numCells) do
            _cellStates.push(0)
        end

    be loadInitial(index: USize, state: USize) =>
        try _cellStates.update(index, state)? else _out.print("invalid index") end

        _updateCounter = _updateCounter + 1

        if(_updateCounter == _numCells) then 
            resetUpdateCounter()
            printBoard(0)
            
            for sim in _partitions.values() do
                let copyCellStates: Array[USize] iso = recover Array[USize] end

                for value in _cellStates.values() do 
                    copyCellStates.push(value)
                end

                sim.simStep(consume copyCellStates, _sideLength)
            end
        end

    be partitionCalculateCellStateCounter() =>
        _updateCounter = _updateCounter + 1

        if(_updateCounter == _numCells) then 
            resetUpdateCounter()

            for sim in _partitions.values() do 
                sim.updateCoordinatorCellStates()
            end
        end

    be updateAndIncrementCounter(index: USize, state: USize) =>
        try _cellStates.update(index, state)? else _out.print("invalid index") end

        _cellCounter = _cellCounter + 1

        if((_cellCounter == _numCells) and (_simEnd == false)) then 
            incrementEpoch()
            resetCellCounter()
            printBoard(_epoch)

            for sim in _partitions.values() do
                let copyCellStates: Array[USize] iso = recover Array[USize] end

                for value in _cellStates.values() do 
                    copyCellStates.push(value)
                end

                sim.simStep(consume copyCellStates, _sideLength)
            end

            if(_epoch == _timeSteps) then
                finish()
            end
        end

    fun ref finish() => 
        _simEnd = true

    fun ref incrementEpoch() =>
        _epoch = _epoch + 1

    fun ref resetCellCounter() =>
        _cellCounter = 0
        
    fun ref resetUpdateCounter() =>
        _updateCounter = 0

    fun ref printBoard(epoch: USize) =>
        _file.print("epoch" 
                + "_" 
                + epoch.string() 
                + ":")

        for i in Range(0, _numCells) do
            let state = try _cellStates(i)? else _out.print("no value here yet") end

            if ((i % (_sideLength)) == (_sideLength - 1)) and (i != 0) then 
                _file.print(state.string())
            else
                _file.write(state.string() + " ")
            end
        end

        _file.print(" ")
    
        
        
        