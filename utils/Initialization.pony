use "collections"
use "random"
use "../../AgentPony"

trait Initialization is (PrintBoard & CountingHandler & EpochHandler)
    fun     numCells():      USize
    fun     sideLength():    USize
    fun     counter():       USize
    fun     timeSteps():     USize
    fun     numPartitions(): USize
    fun     outputToFile():  Bool
    fun     out():           OutStream
    fun ref rand():          XorOshiro128Plus
    fun ref cellStates():    Array[Array[USize]]
    fun ref partitions():    Array[(USize, SimulationSpace)]

    fun ref loadZeros() =>
        for timeStep in Range(0, timeSteps()) do
            let epochArray: Array[USize] = Array[USize](numCells())

            for index in Range(0, numCells()) do
                epochArray.push(0)
            end
            cellStates().push(epochArray)
        end

    fun ref partitionSimulationSpace(coordinator: Coordinator ref) =>
        let sideLengthPerPartition: USize = ((sideLength().f64() * sideLength().f64()) / (numPartitions().f64())).sqrt().usize()
        let leftToRightCell:        USize = sideLengthPerPartition
        let topToBottomCell:        USize = sideLengthPerPartition * sideLength()
        var startIndex:             USize = 0
        var leftToRightIndex:       USize = 0
        var topToBottomIndex:       USize = 0
        var simPartitionIndex:      USize = 0

        for i in Range(0, numPartitions().f64().sqrt().usize()) do
            for j in Range(0, numPartitions().f64().sqrt().usize()) do
                let indices: Array[(USize, USize)] iso = Array[(USize, USize)](sideLengthPerPartition * sideLengthPerPartition)

                for k in Range(0, sideLengthPerPartition) do
                    var index: USize val = startIndex

                    for l in Range(0, sideLengthPerPartition) do
                        let randStatus = rand().int_unbiased(2)                       
                        if(randStatus == 1) then 
                            indices.push((index, 1))
                        else
                            indices.push((index, 0))
                        end
                        
                        index = index + 1
                    end

                    startIndex = startIndex + sideLength()
                end
                
                partitions().push((simPartitionIndex, SimulationSpace(sideLengthPerPartition, sideLength(), numCells(), simPartitionIndex, timeSteps(), out(), coordinator, consume indices)))

                simPartitionIndex = simPartitionIndex + 1
                leftToRightIndex  = leftToRightIndex + leftToRightCell
                startIndex        = leftToRightIndex
            end

            topToBottomIndex = topToBottomIndex + topToBottomCell
            leftToRightIndex = topToBottomIndex
            startIndex       = topToBottomIndex
        end

    fun ref joinNeighboringPartitions() =>
        for partition in partitions().values() do 
            let index: USize = partition._1

            for (x, y) in NeighborFunctions.getNeighborCoordinates().values() do
                let neighbor: USize = NeighborFunctions.calculateNeighbor(x, y, index, numPartitions().f64().sqrt().usize())

                for neighborPartition in partitions().values() do
                    if neighbor == neighborPartition._1 then 
                        partition._2.addPartition(neighborPartition._2)
                    end
                end
            end
        end   

    