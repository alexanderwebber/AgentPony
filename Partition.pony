actor Partition
    let _simulationSpace: SimulationSpace
    let _coordinator:     Coordinator
    let _out:             OutStream
    let _indices:         Array[USize val] iso

    // TODO: receive cells and ghost cells
    new create(sideLength: USize, timeSteps: USize, coordinator': Coordinator, out': OutStream, indices': Array[USize val] iso) =>
        _out             = out'
        _coordinator     = coordinator'
        _indices         = consume indices'
        _simulationSpace = SimulationSpace(sideLength, timeSteps, this, _out)

    be startSimulation() =>
        _simulationSpace.>loadRandomPositions().>runGameOfLife()