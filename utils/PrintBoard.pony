use "files"

primitive PrintBoard
    fun apply(file: File, epoch: USize, sideLength: USize, states: ReadSeq[USize] box) =>
        file.print("epoch"
                + "_"
                + epoch.string()
                + ":")

        var i: USize = 0

        for state in states.values() do
            if ((i % sideLength) == (sideLength - 1)) and (i != 0) then
                file.print(state.string())
            else
                file.write(state.string() + " ")
            end

            i = i + 1
        end

        file.print(" ")
