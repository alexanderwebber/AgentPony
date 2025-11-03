use "collections"
use "random"
use "time"
use "files"
use "runtime_info"
use "./utils"

actor Coordinator is Initialization
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
    
    let _partitions:    Array[(USize, SimulationSpace)]
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
        
        _partitions    = Array[(USize, SimulationSpace)](_numPartitions)
        _cellStates    = Array[Array[USize]](_timeSteps)

    be startSimulation() =>
        partitionSimulationSpace(this)
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
        

    fun     epoch():                  USize                           => _epoch
    fun     numCells():               USize                           => _numCells
    fun     sideLength():             USize                           => _sideLength
    fun     numPartitions():          USize                           => _numPartitions
    fun     counter():                USize                           => _counter
    fun     timeSteps():              USize                           => _timeSteps
    fun     outputToFile():           Bool                            => _outputToFile
    fun ref rand():                   U64                             => _rand.int_unbiased(2)
    fun     out():                    OutStream                       => _env.out
    fun ref file():                   File                            => _file
    fun ref cellStates():             Array[Array[USize]]             => _cellStates
    fun ref partitions():             Array[(USize, SimulationSpace)] => _partitions
    fun ref updateEpoch(v: USize):    USize                           => _epoch   = v
    fun ref updateCounter(v: USize):  USize                           => _counter = v
        
        
        