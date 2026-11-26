use "collections"

primitive Partitioning
    fun partitionsPerSide(numPartitions: USize): USize =>
        numPartitions.f64().sqrt().usize()

    fun sideLengthPerPartition(sideLength: USize, numPartitions: USize): USize =>
        ((sideLength.f64() * sideLength.f64()) / (numPartitions.f64())).sqrt().usize()

    fun cellIndices(partition: USize, sideLength: USize, numPartitions: USize): Array[USize] iso^ =>
        let partitionSideLength: USize = sideLengthPerPartition(sideLength, numPartitions)
        let partitionRow:        USize = partition / partitionsPerSide(numPartitions)
        let partitionColumn:     USize = partition % partitionsPerSide(numPartitions)
        let topLeftIndex:        USize = (partitionRow * partitionSideLength * sideLength) + (partitionColumn * partitionSideLength)

        let indices: Array[USize] iso = Array[USize](partitionSideLength * partitionSideLength)

        for row in Range(0, partitionSideLength) do
            let rowStartIndex: USize = topLeftIndex + (row * sideLength)

            for column in Range(0, partitionSideLength) do
                indices.push(rowStartIndex + column)
            end
        end

        consume indices
