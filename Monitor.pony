actor Monitor
    var cellCounter:   USize
    var epoch:         USize
    var totalEpochs:   USize val
    var totalCells:    USize val
    var updateCounter: USize

    var _simEnd:       Bool
    let _sim:          SimulationSpace
    let _out:          OutStream
    
    // TODO: Signal coordinator epoch finished
    new create(totalCells': USize, totalEpochs': USize, sim': SimulationSpace, out': OutStream) =>
        totalCells    = totalCells'
        totalEpochs   = totalEpochs'
        epoch         = 0
        cellCounter   = 0
        updateCounter = 0

        _simEnd       = false
  
        _sim          = sim'
        _out          = out'

    be incrementCellCounter() =>
        cellCounter = cellCounter + 1

        if((cellCounter == totalCells) and (_simEnd == false)) then 
            incrementEpoch()
            resetCellCounter()
            _sim.updateCellStates()

            if(epoch == totalEpochs) then
                finish()
            end
        end

    be incrementUpdateCounter() =>
        updateCounter = updateCounter + 1

        if(updateCounter == totalCells) then 
            updateState()
            resetUpdateCounter()    
        end

    be updateState() =>
        _sim.printBoard()
        _sim.updateCells()

    be start() =>
        _sim.updateCells()

    fun ref finish() => 
        _simEnd = true

    fun ref incrementEpoch() =>
        epoch = epoch + 1

    fun ref resetCellCounter() =>
        cellCounter = 0
        
    fun ref resetUpdateCounter() =>
        updateCounter = 0
