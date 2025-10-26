use "collections"
use "random"
use "time"

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
    let _out:           OutStream
    
    let _partitions:    Array[SimulationSpace]
    let _cellStates:    Array[USize]

    new create(sideLength': USize, timeSteps': USize, numPartitions': USize, out': OutStream) =>
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
        
        _partitions    = Array[SimulationSpace](_numPartitions)
        _cellStates    = Array[USize](_numCells)

    be startSimulation() =>
        splitSimulationSpace()
        loadZeros()

        for partition in _partitions.values() do 
            partition.initStates()
        end

    fun ref splitSimulationSpace() =>
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

    be updateState(index: USize, state: USize) =>
        try _cellStates.update(index, state)? else _out.print("invalid index") end

    // TODO: Have this output to text file for reconstruction in a different language
    be printBoard() =>
        _out.print(" ")

        for i in Range(0, _numCells) do
            let state = try _cellStates(i)? else _out.print("no value here yet") end

            if ((i % (_sideLength)) == (_sideLength - 1)) and (i != 0) then 
                _out.print(state.string())
            else
                _out.write(state.string() + " ")
            end
        end

        _out.print(" ")

    be incrementUpdateCounter() =>
        _updateCounter = _updateCounter + 1

        if(_updateCounter == _numCells) then 
            resetUpdateCounter()    
        end

    fun ref finish() => 
        _simEnd = true

    fun ref incrementEpoch() =>
        _epoch = _epoch + 1

    fun ref resetCellCounter() =>
        _cellCounter = 0
        
    fun ref resetUpdateCounter() =>
        _updateCounter = 0

    be incrementCellCounter() =>
        _cellCounter = _cellCounter + 1

        if((_cellCounter == _numCells) and (_simEnd == false)) then 
            incrementEpoch()
            resetCellCounter()
            //_sim.updateCellStates()

            printBoard()

            if(_epoch == _timeSteps) then
                finish()
            end
        end
    
        
        
        