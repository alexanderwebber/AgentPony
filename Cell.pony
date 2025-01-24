use "promises"
use "collections"

actor Cell
    var _position:        USize
    var _status:          U64 val
    let _neighbors:       Array[Cell] = Array[Cell](8)
    let _frozenNeighbors: Array[Cell] = Array[Cell](8)

    new create(position': USize, initalStatus: U64 val) =>
        _position = position'
        _status   = initalStatus

    be getStatus(p: Promise[U64]) =>
        p(_status)

    be setNeighbor(neighbor: Cell) =>
        _neighbors.push(neighbor)

    be freezeNeighbors() =>
        for i in Range(0, _neighbors.size()) do 
            try _frozenNeighbors.update(i, _neighbors(i)?)? end
        end

    be updateStatus() =>
        let neighborStatusPromises: Array[Promise[U64]] = Array[Promise[U64]](8)

        for neighbor in _frozenNeighbors.values() do 
            let p = Promise[U64]
            neighbor.getStatus(p)
            neighborStatusPromises.push(p)
        end

        Promises[U64].join(neighborStatusPromises.values())
        .next[None](recover this~receiveNeighborStatuses() end)

    be receiveNeighborStatuses(neighborStatuses: Array[U64] val) =>
        var numLiveNeighbors: U64 = 0

        for status in neighborStatuses.values() do
            if status == 1 then
                numLiveNeighbors = numLiveNeighbors + 1
            end
        end

        if (_status == 1) and ((numLiveNeighbors == 2) or (numLiveNeighbors == 3)) then 
            _status = 1
        elseif (_status == 0) and (numLiveNeighbors == 3) then
            _status = 1
        else
            _status = 0    
        end
