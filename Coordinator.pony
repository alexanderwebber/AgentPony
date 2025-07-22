actor Coordinator
    let _sideLength: USize
    let _timeSteps:  USize
    let _out:        OutStream

    new create(sideLength': USize, timeSteps': USize, out': OutStream) =>
        _sideLength = sideLength'
        _timeSteps  = timeSteps'
        _out        = out'

    be setPartitions() =>
        // Add logic to calculate side length for each partition
        let partition  = Partition(_sideLength, _timeSteps, this, _out)