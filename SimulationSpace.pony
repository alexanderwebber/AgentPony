use "collections"
use "random"
use "promises"
use "pony_test"
use "./utils"
 
actor SimulationSpace 
    let _sideLength:         USize val
    let _numCells:           USize val
    let _cells:              Array[Cell]
    var _cellStates:         Array[(U64, USize)]
    let _rand:               Rand
    let _out:                OutStream
    let neighborCoordinates: Array[(ISize, ISize)] = [(-1, -1); (0, -1); (1, -1); (-1, 0); (1, 0); (-1, 1); (0, 1); (1, 1)]

    new create(sideLength': USize, out': OutStream) =>
        _sideLength       = recover val sideLength' end
        _numCells         = _sideLength * _sideLength
        _cells            = Array[Cell](_numCells)
        _cellStates       = Array[(U64, USize)](_numCells)
        _rand             = Rand
        _out              = out'

    be loadRandomPositions() =>
        for i in Range(0, _numCells) do 
            _cells.push(Cell(i, _rand.next() % 2, _out))
        end

    be loadBlinkerFive() =>
        for i in Range(0, _numCells) do 
            if (i == 7) or (i == 12) or (i == 17) then 
                _cells.push(Cell(i, 1, _out))
            else
                _cells.push(Cell(i, 0, _out))
            end
        end

    be loadNeighbors() =>
        for cellIndex in Range(0, _numCells) do
            for (x, y) in neighborCoordinates.values() do
                let neighbor: USize = calculateNeighbor(x, y, cellIndex, _sideLength)

                try _cells(cellIndex)?.setNeighbor(_cells(neighbor)?) end
            end
        end

    be updateCellStatuses() =>
        for cell in _cells.values() do
            cell.freezeNeighbors()
        end

        for cell in _cells.values() do
            cell.updateStatus()
        end

    be runGameOfLife(timeSteps: USize) =>
        for i in Range(0, timeSteps) do
            this.>gatherCellStatuses().>updateCellStatuses()
        end

    fun gatherCellStatuses() =>
        let cellStatePromises: Array[Promise[(U64, USize)]] = Array[Promise[(U64, USize)]](_numCells)

        for cell in _cells.values() do
            let p = Promise[(U64, USize)]
            cell.getStatusAndPosition(p)
            cellStatePromises.push(p)
        end

        Promises[(U64, USize)].join(cellStatePromises.values())
        .next[None](recover this~copyState() end)

    be copyState(states: Array[(U64, USize)] val) =>
        
        for i in Range(0, _numCells) do 
            try 
                _cellStates.update(i, states(i)?)?
            else 
                try 
                    _cellStates.push(states(i)?)
                else 
                    _out.print("can't access cell state at index " + i.string()) 
                end 
            end
        end

        _cellStates = SortTuple(_cellStates)
        printBoard()

    fun printBoard() =>
        for i in Range(0, _cellStates.size()) do
            let state = try _cellStates(i)?._1 else _out.print("no value here yet") end

            if ((i % (_sideLength)) == (_sideLength - 1)) and (i != 0) then 
                _out.print(state.string())
            else
                _out.write(state.string() + " ")
            end

            // _out.print("\x1B[H\x1B[2J")
        end
        
        _out.print(" ")

    // be testEndStateBlinkerFive(evenOdd: U8, h: TestHelper) =>
    //     let correctStates: Array[U64] = Array[U64](_numCells)

    //     if (evenOdd % 2) == 0 then 
    //         for i in Range(0, _numCells) do 
    //             if (i == 7) or (i == 12) or (i == 17) then 
    //                 correctStates.push(1)
    //             else
    //                 correctStates.push(0)
    //             end
    //         end

    //     else
    //         for i in Range(0, _numCells) do 
    //             if (i == 11) or (i == 12) or (i == 13) then 
    //                 correctStates.push(1)
    //             else
    //                 correctStates.push(0)
    //             end
    //         end
    //     end

    //     h.assert_array_eq[U64](correctStates, _cellStates)

    fun calculateNeighbor(xCoordinate: ISize, yCoordinate: ISize, cellIndex: USize, sideLength: USize): USize =>
        let x:  ISize = (cellIndex % sideLength).isize()
        let y:  ISize = (cellIndex / sideLength).isize()

        let nx: ISize = (x + xCoordinate + sideLength.isize()) % sideLength.isize()
        let ny: ISize = (y + yCoordinate + sideLength.isize()) % sideLength.isize()

        (nx + (ny * sideLength.isize())).usize()

    fun returnNeighborSum(cellIndex: USize): USize =>
        var neighborSum: USize = 0

        for (x, y) in neighborCoordinates.values() do
            let neighbor: USize = calculateNeighbor(x, y, cellIndex, _sideLength)
            neighborSum         = neighborSum + neighbor
        end

        neighborSum

    be testNeighborIndices(topLeftSum: USize, middleSum: USize, h: TestHelper) =>
        h.assert_eq[USize](topLeftSum, returnNeighborSum(0))
        h.assert_eq[USize](middleSum, returnNeighborSum(12))