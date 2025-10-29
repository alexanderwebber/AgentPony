use "collections"
use "../../AgentPony"

trait Initialization is (PrintBoard & CountingHandler)
    fun     numCells():      USize
    fun     sideLength():    USize
    fun     counter():       USize
    fun     numPartitions(): USize
    fun     out():           OutStream
    fun ref cellStates():    Array[USize]
    fun ref partitions():    Array[SimulationSpace]

    fun ref loadZeros() =>
        for index in Range(0, numCells()) do
            cellStates().push(0)
        end

    be loadInitialValues(index: USize, state: USize) =>
        try cellStates().update(index, state)? else out().print("invalid index") end

        incrementCounter()

        if(counter() == numCells()) then 
            resetCounter()
            printBoard()
            
            for sim in partitions().values() do
                let copyCellStates: Array[USize] iso = recover Array[USize] end

                for value in cellStates().values() do 
                    copyCellStates.push(value)
                end

                sim.simStep(consume copyCellStates)
            end
        end

    fun ref partitionSimulationSpace(coordinator: Coordinator) =>
        let sideLengthPerPartition: USize = ((sideLength().f64() * sideLength().f64()) / (numPartitions().f64())).sqrt().usize()
        let leftToRightCell:        USize = sideLengthPerPartition
        let topToBottomCell:        USize = sideLengthPerPartition * sideLength()
        var startIndex:             USize = 0
        var leftToRightIndex:       USize = 0
        var topToBottomIndex:       USize = 0

        for i in Range(0, numPartitions().f64().sqrt().usize()) do
            for j in Range(0, numPartitions().f64().sqrt().usize()) do
                let indices: Array[USize] iso = Array[USize](sideLengthPerPartition * sideLengthPerPartition)

                for k in Range(0, sideLengthPerPartition) do
                    var index: USize val = startIndex

                    for l in Range(0, sideLengthPerPartition) do 
                        indices.push(index)
                        index = index + 1
                    end

                    startIndex = startIndex + sideLength()
                end
                
                partitions().push(SimulationSpace(sideLengthPerPartition, sideLength(), numCells(), out(), coordinator, consume indices))

                leftToRightIndex = leftToRightIndex + leftToRightCell
                startIndex       = leftToRightIndex

            end

            topToBottomIndex = topToBottomIndex + topToBottomCell
            leftToRightIndex = topToBottomIndex
            startIndex       = topToBottomIndex
        end