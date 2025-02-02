use "collections"
use "../../AgentPony"
use "../utils"
use "pony_test"

primitive TestsPrimitive
    fun testNeighborIndices(topLeftSum: USize, middleSum: USize, h: TestHelper, sideLength: USize) =>
        h.assert_eq[USize](topLeftSum, NeighborFunctions.returnNeighborSum(0,  sideLength))
        h.assert_eq[USize](middleSum,  NeighborFunctions.returnNeighborSum(12, sideLength))

    fun testEndStateBlinkerFive(evenOdd: U8, h: TestHelper, cellStates: Array[(U64, USize)], numCells: USize) =>
            let correctStates:  Array[U64] = Array[U64](numCells)
            let cellOnlyStates: Array[U64] = Array[U64](numCells)
            
            for i in Range(0, numCells) do 
                try cellOnlyStates(i)? = cellStates(i)?._1 end
            end

            if (evenOdd % 2) == 0 then 
                for i in Range(0, numCells) do 
                    if (i == 7) or (i == 12) or (i == 17) then 
                        correctStates.push(1)
                    else
                        correctStates.push(0)
                    end
                end

            else
                for i in Range(0, numCells) do 
                    if (i == 11) or (i == 12) or (i == 13) then 
                        correctStates.push(1)
                    else
                        correctStates.push(0)
                    end
                end
            end

            h.assert_array_eq[U64](correctStates, cellOnlyStates)