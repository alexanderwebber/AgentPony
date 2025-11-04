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
    var _cellCounter:        USize
    var _counter:            USize
    var _epoch:              USize
    var _simEnd:             Bool
    let _outputToFile:       Bool

    let _rand:               Rand
    let _file:               File
    let _env:                Env
    
    let _partitions:         Array[SimulationSpace]
    let _cellStates:         Array[(USize, Bool)]
    let _emptyCells:         Array[(USize, USize)]

    let _activityReports:    Array[USize]
    var _rebalanceCounter:   USize
    let _rebalanceInterval:  USize
    let _imbalanceThreshold: F64

    new create(sideLength': USize, timeSteps': USize, numPartitions': USize, outputToFile': Bool, env': Env, file': File iso) =>
        _sideLength         = sideLength'
        _timeSteps          = timeSteps'
        _numPartitions      = numPartitions'
        _numCells           = _sideLength * _sideLength

        _cellCounter        = 0
        _epoch              = 0
        _counter            = 0
        _simEnd             = false
        _outputToFile       = outputToFile'
        _rand               = Rand.from_u64(Time.nanos())
        _file               = consume file'
        _env                = env'
        
        _partitions         = Array[SimulationSpace](_numPartitions)
        _cellStates         = Array[(USize, Bool)](_numCells)
        _emptyCells         = Array[(USize, USize)](_numCells)

        _activityReports    = Array[USize](_numPartitions)
        _rebalanceCounter   = 0
        _rebalanceInterval  = 20 
        _imbalanceThreshold = 0.3

    be startSimulation() =>
        partitionSimulationSpace(this)
        loadZeros()

        for partition in _partitions.values() do 
            partition.initStates()
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

            if (_epoch % _rebalanceInterval) == 0 then
                checkAndRebalance()
            end

            let tempCopyCellStates: Array[USize] val = recover val createSendableCopy() end

            for sim in _partitions.values() do
                sim.simStep(tempCopyCellStates)
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

    fun ref checkAndRebalance() =>
        _activityReports.clear()
        _rebalanceCounter = 0

        for (idx, partition) in _partitions.pairs() do
            partition.reportActivity(idx, this)
        end

    be receiveActivityReport(partitionId: USize, activeCount: USize) =>
        _activityReports.push(activeCount)
        _rebalanceCounter = _rebalanceCounter + 1
        
        if _rebalanceCounter == _numPartitions then
            analyzeAndRebalance()
        end

    fun ref analyzeAndRebalance() =>
        if _activityReports.size() == 0 then return end
        
        var total: USize = 0
        for count in _activityReports.values() do
            total = total + count
        end
        
        let mean: F64 = total.f64() / _activityReports.size().f64()
        
        var varianceSum: F64 = 0

        for count in _activityReports.values() do
            let diff    = count.f64() - mean
            varianceSum = varianceSum + (diff * diff)
        end
        
        let stdDev = (varianceSum / _activityReports.size().f64()).sqrt()
        let cv     = if mean > 0 then stdDev / mean else F64(0) end
        
        _env.out.print("Epoch " + _epoch.string() + " - Active cells per partition: " + 
                      "mean=" + mean.string() + ", CV=" + cv.string())
        
        if cv > _imbalanceThreshold then
            _env.out.print("  -> Imbalance detected! Rebalancing...")
            performRebalancing()
        end

    fun ref performRebalancing() =>
        let activeCells: Array[USize] = Array[USize]
        
        for (idx, state) in _cellStates.pairs() do
            if state._1 != 0 then
                activeCells.push(idx)
            end
        end
        
        if activeCells.size() == 0 then return end
        
        let cellsPerPartition: USize = activeCells.size() / _numPartitions
        let remainder: USize = activeCells.size() % _numPartitions
        
        _env.out.print("  Redistributing " + activeCells.size().string() + 
                      " active cells across " + _numPartitions.string() + " partitions")
        
        _partitions.clear()
        
        var startIdx: USize = 0
        for p in Range[USize](0, _numPartitions) do
            let extraCell: USize = if p < remainder then USize(1) else USize(0) end
            let endIdx:    USize = startIdx + cellsPerPartition + extraCell
            
            let partitionIndices: Array[USize val] iso = recover iso Array[USize val] end
            
            for i in Range[USize](startIdx, endIdx.min(activeCells.size())) do
                try partitionIndices.push(activeCells(i)?) end
            end
            
            let localSideLength: USize = partitionIndices.size()
            let sim                    = SimulationSpace(localSideLength, _sideLength, _numCells, _env.out, this, consume partitionIndices)
            _partitions.push(sim)
            
            startIdx = endIdx
        end
        
        _env.out.print("  Rebalancing complete. New partition size: ~" + cellsPerPartition.string())
        
        for partition in _partitions.values() do
            partition.initStates()
        end

    fun     epoch():                  USize                  => _epoch
    fun     numCells():               USize                  => _numCells
    fun     sideLength():             USize                  => _sideLength
    fun     numPartitions():          USize                  => _numPartitions
    fun     counter():                USize                  => _counter
    fun     outputToFile():           Bool                   => _outputToFile
    fun     out():                    OutStream              => _env.out
    fun ref file():                   File                   => _file
    fun ref cellStates():             Array[(USize, Bool)]   => _cellStates
    fun ref partitions():             Array[SimulationSpace] => _partitions
    fun ref finish()                                         => _simEnd  = true
    fun ref updateEpoch(v: USize):    USize                  => _epoch   = v
    fun ref updateCounter(v: USize):  USize                  => _counter = v
        
        
        