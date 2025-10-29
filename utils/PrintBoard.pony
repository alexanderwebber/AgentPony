use "files"
use "collections"

trait PrintBoard
    fun     epoch():      USize
    fun     numCells():   USize
    fun     sideLength(): USize
    fun ref file():       File
    fun ref cellStates(): Array[USize]

    fun ref printBoard() =>
            file().print("epoch" 
                    + "_" 
                    + epoch().string() 
                    + ":")

            for i in Range(0, numCells()) do
                let state = try cellStates()(i)? end

                if ((i % (sideLength())) == (sideLength() - 1)) and (i != 0) then 
                    file().print(state.string())
                else
                    file().write(state.string() + " ")
                end
            end

            file().print(" ")
    