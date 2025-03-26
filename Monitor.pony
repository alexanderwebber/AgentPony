actor Monitor
    var cellCounter: USize
    var epoch:       USize
    var totalEpochs: USize val
    var totalCells:  USize val

    var _simEnd:     Bool

    let _sim:        SimulationSpace
    let _out:        OutStream
    

    new create(totalCells': USize, totalEpochs': USize, sim': SimulationSpace, out': OutStream) =>
        totalCells  = totalCells'
        totalEpochs = totalEpochs'
        epoch       = 0
        cellCounter = 0

        _simEnd     = false

        _sim        = sim'
        _out        = out'

    be incrementCellCounter() =>
        cellCounter = cellCounter + 1

        if((cellCounter == totalCells) and (_simEnd == false)) then 
            _sim.updateCellStates()
            _sim.printBoard()
            
            incrementEpoch()
            resetCellCounter()

            _sim.updateCells()

            if(epoch == totalEpochs) then
                finish()
                _out.print("completed")
            end
        end

    be start() =>
        _sim.updateCells()

    be finish() => 
        _simEnd = true

    fun ref incrementEpoch() =>
        epoch = epoch + 1

    fun ref resetCellCounter() =>
        cellCounter = 0
        
