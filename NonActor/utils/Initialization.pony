use "collections"
use "../../NonActor"

trait Initialization is (PrintBoard & CountingHandler)
    fun     numCells():      USize
    fun     sideLength():    USize
    fun     counter():       USize
    fun     numPartitions(): USize
    fun     outputToFile():  Bool
    fun     out():           OutStream
    fun ref cellStates():    Array[USize]
    fun ref partitions():    Array[SimulationSpace]

    fun ref loadZeros() =>
        for index in Range(0, numCells()) do
            cellStates().push(0)
        end