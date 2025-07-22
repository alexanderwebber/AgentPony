actor Coordinator
    let _sideLength: USize
    let _timeSteps:  USize
    let _out:        OutStream
    let _partition:  Partition

    new create(sideLength': USize, timeSteps': USize, out': OutStream) =>
        _sideLength = sideLength'
        _timeSteps  = timeSteps'
        _out        = out'

        _partition  = Partition(_sideLength, _timeSteps, this, _out)

    be startSimulation() =>
        _partition.startSimulation()