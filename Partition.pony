actor Partition
    let _simulationSpace: SimulationSpace
    let _coordinator:     Coordinator
    let _out:             OutStream

    // TODO: receive cells and ghost cells
    new create(sideLength: USize, timeSteps: USize, coordinator': Coordinator, out': OutStream) =>
        _out             = out'
        _simulationSpace = SimulationSpace(sideLength, timeSteps, this, _out)
        _coordinator     = coordinator'
    
    be startSimulation() =>
        _simulationSpace.>loadRandomPositions().>runGameOfLife()

