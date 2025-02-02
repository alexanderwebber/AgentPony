use "../../AgentPony"
use "collections"

primitive NeighborFunctions
    fun printBoard(cellStates: Array[(U64, USize)], out: OutStream, sideLength: USize) =>
        for i in Range(0, cellStates.size()) do
            let state = try cellStates(i)?._1 else out.print("no value here yet") end

            if ((i % (sideLength)) == (sideLength - 1)) and (i != 0) then 
                out.print(state.string())
            else
                out.write(state.string() + " ")
            end
        end

        out.print(" ")

    fun calculateNeighbor(xCoordinate: ISize, yCoordinate: ISize, cellIndex: USize, sideLength: USize): USize =>
        let x:  ISize = (cellIndex % sideLength).isize()
        let y:  ISize = (cellIndex / sideLength).isize()

        let nx: ISize = (x + xCoordinate + sideLength.isize()) % sideLength.isize()
        let ny: ISize = (y + yCoordinate + sideLength.isize()) % sideLength.isize()

        (nx + (ny * sideLength.isize())).usize()

    fun returnNeighborSum(cellIndex: USize, sideLength: USize): USize =>
        let neighborCoordinates: Array[(ISize, ISize)] = [(-1, -1); (0, -1); (1, -1); (-1, 0); (1, 0); (-1, 1); (0, 1); (1, 1)]
        var neighborSum: USize = 0

        for (x, y) in neighborCoordinates.values() do
            let neighbor: USize = calculateNeighbor(x, y, cellIndex, sideLength)
            neighborSum         = neighborSum + neighbor
        end

        neighborSum

    fun getNeighborCoordinates(): Array[(ISize, ISize)] =>
        [(-1, -1); (0, -1); (1, -1); (-1, 0); (1, 0); (-1, 1); (0, 1); (1, 1)]