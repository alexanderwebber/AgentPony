use "collections"
use "random"
use "time"
use "files"
use "runtime_info"
use "./utils"

actor Coordinator is Initialization
    let _sideLength:         USize
    let _timeSteps:          USize
    let _numPartitions:      USize
    let _numCells:           USize
    let _simulationType:     String
    var _cellCounter:        USize
    var _counter:            USize
    var _epoch:              USize
    var _simEnd:             Bool
    let _outputToFile:       Bool
    var _partitionsReady: USize

    let _rand:               Rand
    let _file:               File
    let _env:                Env
    
    let _partitions:         Array[SimulationSpace]
    let _cellStates:         Array[(USize, Bool)]
    let _gofCellStates:      Array[USize]
    let _emptyCells:         Array[(USize, USize)]

    let _activityReports:    Array[USize]
    let _activeCellIndices:  Array[Array[USize]]
    var _rebalanceCounter:   USize
    let _rebalanceInterval:  USize
    let _imbalanceThreshold: F64

    new create(sideLength': USize, timeSteps': USize, numPartitions': USize, 
               simulationType': String, outputToFile': Bool, env': Env, file': File iso) =>
        _sideLength         = sideLength'
        _timeSteps          = timeSteps'
        _numPartitions      = numPartitions'
        _numCells           = _sideLength * _sideLength
        _simulationType     = simulationType'

        _cellCounter        = 0
        _epoch              = 0
        _counter            = 0
        _partitionsReady    = 0
        _simEnd             = false
        _outputToFile       = outputToFile'
        _rand               = Rand.from_u64(Time.nanos())
        _file               = consume file'
        _env                = env'
        
        _partitions         = Array[SimulationSpace](_numPartitions)
        _cellStates         = Array[(USize, Bool)](_numCells)
        _gofCellStates      = Array[USize](_numCells)
        _emptyCells         = Array[(USize, USize)](_numCells)

        _activityReports    = Array[USize](_numPartitions)
        _activeCellIndices  = Array[Array[USize]](_numPartitions) 
        _rebalanceCounter   = 0
        _rebalanceInterval  = 20 
        _imbalanceThreshold = 0.3

    be startSimulation() =>
        partitionSimulationSpace(this)
        
        if _simulationType == "gameoflife" then
            loadZerosGoF()
        else
            loadZeros()
        end

        for partition in _partitions.values() do 
            partition.initStates()
        end

    be gameOfLifeUpdate(cellStates': Array[(USize, USize)] iso) =>
        let cellStatesUpdate: Array[(USize, USize)] = consume cellStates'
        
        for (idx, state) in cellStatesUpdate.pairs() do
            try _gofCellStates.update(cellStatesUpdate(idx)?._1, cellStatesUpdate(idx)?._2)? end
        end

        incrementCounter()

        if((_counter == _numPartitions) and (_simEnd == false)) then
            incrementEpoch()
            resetCounter()

            if(_outputToFile) then printBoardGoF() end

            if(_epoch == _timeSteps) then finish() end

            let tempCopyCellStates: Array[USize] val = recover val createSendableCopyGoF() end

            for sim in _partitions.values() do
                let sendableEpoch = recover val _epoch end
                sim.simStep(tempCopyCellStates, sendableEpoch)
            end
        end

    be schellingUpdate(cellPosStates': Array[(USize, USize, Bool)] iso, emptyLocations': Array[(USize, USize)] iso) =>
        let cellPosStates: Array[(USize, USize, Bool)] = consume cellPosStates'
        let emptyCells:    Array[(USize, USize)]       = consume emptyLocations'
        
        for posState in cellPosStates.values() do 
            try _cellStates.update(posState._1, (posState._2, posState._3))? end
        end

        for empty in emptyCells.values() do 
            _emptyCells.push(empty)
        end

        incrementCounter()

        if((_counter == _numPartitions) and (_simEnd == false)) then
            incrementEpoch()
            resetCounter()
            swapUnsatisfied(_cellStates, _emptyCells)
            _emptyCells.clear()

            if(_outputToFile) then printBoard() end

            if(_epoch == _timeSteps) then finish() end

            let tempCopyCellStates: Array[USize] val = recover val createSendableCopy() end

            for sim in _partitions.values() do
                let sendableEpoch = recover val _epoch end
                sim.simStep(tempCopyCellStates, sendableEpoch)
            end
        end

    fun ref swapUnsatisfied(cellStates': Array[(USize, Bool)], emptyCells': Array[(USize, USize)]) =>
        for i in Range(0, cellStates'.size()) do
            try
                if cellStates'(i)?._2 == false then 
                    let randPosition = _rand.int_unbiased(emptyCells'.size().u64())
                    let swapIndex = emptyCells'(randPosition.usize())?._1

                    cellStates'.update(swapIndex, (cellStates'(i)?._1, true))?
                    cellStates'.update(i, (0, true))?

                    _emptyCells.delete(randPosition.usize())?
                end
            end
        end

    fun createSendableCopy(): Array[USize] iso^ =>
        let tempCopyCellStates: Array[USize] iso = Array[USize](_numCells)

        for value in _cellStates.values() do 
            tempCopyCellStates.push(value._1)
        end

        tempCopyCellStates

    fun createSendableCopyGoF(): Array[USize] iso^ =>
        let tempCopyCellStates: Array[USize] iso = Array[USize](_numCells)

        for value in _gofCellStates.values() do 
            tempCopyCellStates.push(value)
        end

        tempCopyCellStates

    fun ref printBoardGoF() =>
        file().print("epoch_" + _epoch.string() + ":")
        
        for i in Range(0, _numCells) do
            try
                let state = _gofCellStates(i)?
                
                if ((i % _sideLength) == (_sideLength - 1)) and (i != 0) then 
                    file().print(state.string())
                else
                    file().write(state.string() + " ")
                end
            end
        end
        
        file().print(" ")

    fun     epoch():                  USize                  => _epoch
    fun     numCells():               USize                  => _numCells
    fun     sideLength():             USize                  => _sideLength
    fun     numPartitions():          USize                  => _numPartitions
    fun     counter():                USize                  => _counter
    fun     simulationType():         String                 => _simulationType
    fun     outputToFile():           Bool                   => _outputToFile
    fun     env():                    Env                    => _env
    fun ref file():                   File                   => _file
    fun ref cellStates():             Array[(USize, Bool)]   => _cellStates
    fun ref gofCellStates():          Array[USize]           => _gofCellStates
    fun ref partitions():             Array[SimulationSpace] => _partitions
    fun ref finish()                                         => _simEnd  = true
    fun ref updateEpoch(v: USize):    USize                  => _epoch   = v
    fun ref updateCounter(v: USize):  USize                  => _counter = v