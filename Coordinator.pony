actor Coordinator
    let _sideLength:    USize
    let _timeSteps:     USize
    let _numPartitions: USize
    let _out:           OutStream
    let _partition:     Partition

    new create(sideLength': USize7, timeSteps': USize, out': OutStream) =>
        _sideLength = sideLength'
        _timeSteps  = timeSteps'
        _out        = out'
        
        _partition  = Partition(_sideLength, _timeSteps, this, _out)

    be startSimulation() =>
        _partition.startSimulation()

    be splitSimulationSpace() =>
        // smallest square that can be divided into our equal squares
        // minimum overall sidelength is equal to the square root of the number of partitions
        
        