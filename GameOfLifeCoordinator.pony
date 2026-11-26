use "collections"
use "random"
use "time"
use "files"
use "runtime_info"
use "./utils"

actor GameOfLifeCoordinator is (CountingHandler & EpochHandler)
    let _sideLength:    USize
    let _timeSteps:     USize
    let _numPartitions: USize
    let _numCells:      USize
    var _cellCounter:   USize
    var _counter:       USize
    var _pCounter:      USize
    var _epoch:         USize
    let _outputToFile:  Bool

    let _rand:          Rand
    let _file:          File
    let _env:           Env
    
    let _partitions:    Array[(USize, GameOfLifeSpace)]
    let _cellStates:    Array[Array[USize]]

    new create(sideLength': USize, timeSteps': USize, numPartitions': USize, outputToFile': Bool, env': Env, file': File iso) =>
        _sideLength    = sideLength'
        _timeSteps     = timeSteps'
        _numPartitions = numPartitions'
        _numCells      = _sideLength * _sideLength

        _cellCounter   = 0
        _epoch         = 0
        _counter       = 0
        _pCounter      = 0
        _outputToFile  = outputToFile'
        _rand          = Rand.from_u64(Time.nanos())
        _file          = consume file'
        _env           = env'
        
        _partitions    = Array[(USize, GameOfLifeSpace)](_numPartitions)
        _cellStates    = Array[Array[USize]](_timeSteps)

    be startSimulation() =>
        partitionSimulationSpace()
        joinNeighboringPartitions()
        loadZeros()

    be cellStatesUpdated(currentEpoch: USize, cellPosStates: Array[(USize, USize)] val) =>        
        for posState in cellPosStates.values() do 
            try _cellStates(currentEpoch)?.update(posState._1, posState._2)? end
        end

        if currentEpoch == _timeSteps then 
            incrementCounter()
        end

        if _counter == _numPartitions then 
            if _outputToFile then 
                printBoard()
            end
        end

    be initBarrier() =>
        _pCounter = _pCounter + 1

        if _pCounter == (_numPartitions * 8) then
            _pCounter = 0

            for partition in _partitions.values() do 
                partition._2.initCells()
            end
        end

    fun ref loadZeros() =>
        for timeStep in Range(0, _timeSteps) do
            let epochArray: Array[USize] = Array[USize](_numCells)

            for index in Range(0, _numCells) do
                epochArray.push(0)
            end
            _cellStates.push(epochArray)
        end

    fun ref partitionSimulationSpace() =>
        let sideLengthPerPartition: USize = Partitioning.sideLengthPerPartition(_sideLength, _numPartitions)
        let partitionsPerSide:      USize = Partitioning.partitionsPerSide(_numPartitions)

        for simPartitionIndex in Range(0, partitionsPerSide * partitionsPerSide) do
            let cellIndices: Array[USize] val          = Partitioning.cellIndices(simPartitionIndex, _sideLength, _numPartitions)
            let indices:     Array[(USize, USize)] iso = Array[(USize, USize)](cellIndices.size())

            for index in cellIndices.values() do
                let randStatus = _rand.int_unbiased(2)
                if(randStatus == 1) then 
                    indices.push((index, 1))
                else
                    indices.push((index, 0))
                end
            end

            _partitions.push((simPartitionIndex, GameOfLifeSpace(sideLengthPerPartition, _sideLength, _numCells, simPartitionIndex, _timeSteps, _env.out, this, consume indices)))
        end

    fun ref joinNeighboringPartitions() =>
        for partition in _partitions.values() do 
            let index: USize = partition._1

            for (x, y) in NeighborFunctions.getNeighborCoordinates().values() do
                let neighbor: USize = NeighborFunctions.calculateNeighbor(x, y, index, Partitioning.partitionsPerSide(_numPartitions))

                for neighborPartition in _partitions.values() do
                    if neighbor == neighborPartition._1 then 
                        partition._2.addPartition(neighborPartition._2)
                    end
                end
            end
        end

    fun ref printBoard() =>
        for timeStep in Range(0, _cellStates.size()) do
            try PrintBoard(_file, timeStep, _sideLength, _cellStates(timeStep)?) end
        end

    fun     counter():                USize => _counter
    fun     epoch():                  USize => _epoch
    fun ref updateEpoch(v: USize):    USize => _epoch   = v
    fun ref updateCounter(v: USize):  USize => _counter = v
