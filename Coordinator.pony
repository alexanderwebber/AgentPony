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
    var _counter: USize
    var _epoch:         USize
    var _simEnd:        Bool
    let _outputToFile:  Bool

    let _rand:          Rand
    let _file:          File
    let _env:           Env
    
    let _partitions:    Array[SimulationSpace]
    let _cellStates:    Array[USize]

    new create(sideLength': USize, timeSteps': USize, numPartitions': USize, outputToFile': Bool, env': Env, file': File iso) =>
        _sideLength    = sideLength'
        _timeSteps     = timeSteps'
        _numPartitions = numPartitions'
        _numCells      = _sideLength * _sideLength

        _cellCounter   = 0
        _epoch         = 0
        _counter       = 0
        _simEnd        = false
        _outputToFile  = outputToFile'
        _rand          = Rand.from_u64(Time.nanos())
        _file          = consume file'
        _env           = env'
        
        _partitions    = Array[SimulationSpace](_numPartitions)
        _cellStates    = Array[USize](_numCells)

    be startSimulation() =>
        partitionSimulationSpace(this)
        loadZeros()

        for partition in _partitions.values() do 
            partition.initStates()
        end

    be cellStateCalculated() =>
        incrementCounter()

        if(_counter == _numCells) then 
            resetCounter()

            for sim in _partitions.values() do 
                sim.updateCellStates()
            end
        end

    be cellStateUpdated(index: USize, state: USize) =>
        try _cellStates.update(index, state)? else _env.out.print("invalid index") end

        incrementCounter()

        if((_counter == _numCells) and (_simEnd == false)) then 
            incrementEpoch()
            resetCounter()

            if(_outputToFile) then printBoard() end

            if(_epoch == _timeSteps) then finish() end

            let tempCopyCellStates: Array[USize] iso = Array[USize](_numCells)

            for value in _cellStates.values() do 
                tempCopyCellStates.push(value)
            end

            let sendableCellStates: Array[USize] val = consume tempCopyCellStates

            for sim in _partitions.values() do
                sim.simStep(sendableCellStates)
            end
        end

    fun     epoch():                  USize                  => _epoch
    fun     numCells():               USize                  => _numCells
    fun     sideLength():             USize                  => _sideLength
    fun     numPartitions():          USize                  => _numPartitions
    fun     counter():                USize                  => _counter
    fun     outputToFile():           Bool                   => _outputToFile
    fun     out():                    OutStream              => _env.out
    fun ref file():                   File                   => _file
    fun ref cellStates():             Array[USize]           => _cellStates
    fun ref partitions():             Array[SimulationSpace] => _partitions
    fun ref finish()                                         => _simEnd  = true
    fun ref updateEpoch(v: USize):    USize                  => _epoch   = v
    fun ref updateCounter(v: USize):  USize                  => _counter = v
        
        
        