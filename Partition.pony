actor Partition
    let _simulationSpace: SimulationSpace
    let _coordinator:     Coordinator
    let _out:             OutStream

    new create(sideLength: USize, timeSteps: USize, coordinator': Coordinator, out': OutStream) =>
        _out             = out'
        _simulationSpace = SimulationSpace(sideLength, timeSteps, _out)
        _coordinator     = coordinator'
    
    