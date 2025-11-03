use "files"
use "collections"

trait PrintBoard
    fun     epoch():      USize
    fun     numCells():   USize
    fun     sideLength(): USize
    fun ref file():       File
    fun ref cellStates(): Array[Array[USize]]

    fun ref printBoard() =>
        for timeStep in Range(0, cellStates().size()) do
            file().print("epoch" 
                    + "_" 
                    + timeStep.string() 
                    + ":")

            for i in Range(0, numCells()) do
                let state = try cellStates()(timeStep)?(i)? end

                if ((i % (sideLength())) == (sideLength() - 1)) and (i != 0) then 
                    file().print(state.string())
                else
                    file().write(state.string() + " ")
                end
            end

            file().print(" ")
        end
    