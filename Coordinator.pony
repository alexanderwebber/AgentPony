use "collections"

actor Coordinator
    let _sideLength:    USize
    let _timeSteps:     USize
    let _numPartitions: USize
    let _out:           OutStream
    let _partitions:    Array[Partition]

    new create(sideLength': USize, timeSteps': USize, numPartitions': USize, out': OutStream) =>
        _sideLength    = sideLength'
        _timeSteps     = timeSteps'
        _out           = out'
        _numPartitions = numPartitions'
        
        _partitions    = Array[Partition](_numPartitions)

    be startSimulation() =>
        splitSimulationSpace()

        for partition in _partitions.values() do 
            partition.startSimulation()
        end
        

    fun ref splitSimulationSpace() =>
        
        let sideLengthPerPartition: USize = (_sideLength * _sideLength) / (_numPartitions * _numPartitions)

        // TODO: need to send cell indices and ghost cells
        for i in Range(0, _numPartitions) do
            _partitions.push(Partition(sideLengthPerPartition, _timeSteps, this, _out))
        end


        
        