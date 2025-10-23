use "collections"

actor Coordinator
    let _sideLength:    USize
    let _timeSteps:     USize
    let _numPartitions: USize
    let _out:           OutStream
    let _partitions:    Array[Partition]
    // let _cellStates:    Array[Cell]

    new create(sideLength': USize, timeSteps': USize, numPartitions': USize, out': OutStream) =>
        _sideLength    = sideLength'
        _timeSteps     = timeSteps'
        _out           = out'
        _numPartitions = numPartitions'
        
        _partitions    = Array[Partition](_numPartitions)

    be startSimulation() =>
        splitSimulationSpace()

        // for partition in _partitions.values() do 
        //     partition.startSimulation()
        // end
        
    fun ref splitSimulationSpace() =>
        let sideLengthPerPartition: USize = ((_sideLength.f64() * _sideLength.f64()) / (_numPartitions.f64())).sqrt().usize()
        let rowDiff:                USize = sideLengthPerPartition
        let colDiff:                USize = sideLengthPerPartition * _sideLength
        var startIndex:             USize = 0
        var nextRowIndex:           USize = 0

        for i in Range(0, _numPartitions.f64().sqrt().usize()) do
            startIndex = nextRowIndex

            for j in Range(0, _numPartitions.f64().sqrt().usize()) do
                var index:   USize val        = startIndex
                let indices: Array[USize] iso = Array[USize](sideLengthPerPartition * sideLengthPerPartition)

                for k in Range(0, sideLengthPerPartition) do
                    for l in Range(0, sideLengthPerPartition) do 
                        indices.push(index)
                        index = index + 1
                    end

                    index = startIndex + _sideLength
                end

                for test in Range(0, indices.size()) do 
                    try _out.print(indices(test)?.string()) end
                end

                _out.print("-----")
                
                _partitions.push(Partition(sideLengthPerPartition, _timeSteps, this, _out, consume indices))

                startIndex = startIndex + rowDiff

            end

            nextRowIndex = nextRowIndex + colDiff 

        end


        

        
        
        