use "collections"
use "random"
use "promises"
use "pony_test"
use "./utils"
use "./test"
 
actor SimulationSpace 
    let _sideLength:         USize val
    let _numCells:           USize val
    let _cells:              Array[Cell]
    var _cellStates:         Array[(U64, USize)]
    let _rand:               Rand
    let _out:                OutStream

    new create(sideLength': USize, out': OutStream) =>
        _sideLength = recover val sideLength' end
        _numCells   = _sideLength * _sideLength
        _cells      = Array[Cell](_numCells)
        _cellStates = Array[(U64, USize)](_numCells)
        _rand       = Rand
        _out        = out'

    be loadRandomPositions() =>
        for i in Range(0, _numCells) do 
            _cells.push(Cell(i, _rand.next() % 2, _out))
        end

    be loadBlinkerFive() =>
        for i in Range(0, _numCells) do 
            if (i == 7) or (i == 12) or (i == 17) then 
                _cells.push(Cell(i, 1, _out))
                _cellStates.push((1, i.usize()))
            else
                _cells.push(Cell(i, 0, _out))
                _cellStates.push((0, i.usize()))
            end
        end
        printBoard()

    be loadNeighbors() =>
        for cellIndex in Range(0, _numCells) do
            for (x, y) in NeighborFunctions.getNeighborCoordinates().values() do
                let neighbor: USize = NeighborFunctions.calculateNeighbor(x, y, cellIndex, _sideLength)

                try _cells(cellIndex)?.setNeighbor(_cells(neighbor)?) end
            end
        end

    be runGameOfLife(timeSteps: USize) =>
        for i in Range(0, timeSteps) do
            simulationStep()
        end

    be simulationStep() =>
        let cellStatePromises: Array[Promise[U64]] = Array[Promise[U64]](_numCells)

        for cell in _cells.values() do
            let p = Promise[U64]
            cell.getStatus(p)
            cellStatePromises.push(p)
        end

        Promises[U64].join(cellStatePromises.values())
        .next[None](recover this~freezeCellStatuses() end)

    be freezeCellStatuses(states: Array[U64] val) =>
        let cellFreezePromises: Array[Promise[U64]] = Array[Promise[U64]](_numCells)

        for cell in _cells.values() do
            let p = Promise[(U64)]
            cell.freezeNeighbors(p)
            cellFreezePromises.push(p)
        end

        Promises[U64].join(cellFreezePromises.values())
        .next[None](recover this~updateCellStatuses() end)

    be updateCellStatuses(freezePromises: Array[U64] val) =>
        let cellUpdatePromises: Array[Promise[(U64, USize)]] = Array[Promise[(U64, USize)]](_numCells)

        for cell in _cells.values() do
            let p = Promise[(U64, USize)]
            cell.updateStatus(p)
            cellUpdatePromises.push(p)
        end

        Promises[(U64, USize)].join(cellUpdatePromises.values())
        .next[None](recover this~copyPrint() end)

    be copyPrint(states: Array[(U64, USize)] val) =>
        for i in Range(0, _numCells) do 
            try 
                _cellStates.update(i, states(i)?)?
            else 
                try 
                    _cellStates.push(states(i)?)
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
        end

        _out.print(" ")

    be testNeighborIndices(topLeftSum: USize, middleSum: USize, h: TestHelper) =>
        h.assert_eq[USize](topLeftSum, NeighborFunctions.returnNeighborSum(0,  _sideLength))
        h.assert_eq[USize](middleSum,  NeighborFunctions.returnNeighborSum(12, _sideLength))

    be testEndStateBlinkerFive(evenOdd: U8, h: TestHelper) =>
            let correctStates:  Array[U64] = Array[U64](_numCells)
            let cellOnlyStates: Array[U64] = Array[U64](_numCells)
            
            for i in Range(0, _numCells) do 
                try cellOnlyStates(i)? = _cellStates(i)?._1 end
            end

            if (evenOdd % 2) == 0 then 
                for i in Range(0, _numCells) do 
                    if (i == 7) or (i == 12) or (i == 17) then 
                        correctStates.push(1)
                    else
                        correctStates.push(0)
                    end
                end

            else
                for i in Range(0, _numCells) do 
                    if (i == 11) or (i == 12) or (i == 13) then 
                        correctStates.push(1)
                    else
                        correctStates.push(0)
                    end
                end
            end

            h.assert_array_eq[U64](correctStates, cellOnlyStates)