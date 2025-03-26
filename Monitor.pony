actor Monitor
    var cellCounter: USize
    var epoch:       USize
    var totalEpochs: USize val
    var totalCells:  USize val

    var _epochEnd:   Bool
    var _simEnd:     Bool

    let _sim:        SimulationSpace
    let _out:        OutStream
    

    new create(totalCells': USize, totalEpochs': USize, sim': SimulationSpace, out': OutStream) =>
        totalCells  = totalCells'
        totalEpochs = totalEpochs'
        epoch       = 0
        cellCounter = 0

        _epochEnd   = false
        _simEnd     = false

        _sim        = sim'
        _out        = out'

        be incrementCellCounter() =>
            cellCounter = cellCounter + 1

            if(cellCounter == totalCells) then 
                incrementEpoch()
                resetCellCounter()

                _sim.updateCells()

                if(epoch == totalEpochs) then 
                    _out.print("completed")
                end
            end

        be start() =>
            _sim.updateCells()

        be finish() =>
            _sim.

        fun ref incrementEpoch() =>
            epoch = epoch + 1

        fun ref resetCellCounter() =>
            cellCounter = 0
        
