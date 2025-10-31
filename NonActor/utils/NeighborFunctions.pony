use "../../NonActor"
use "collections"

primitive NeighborFunctions
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