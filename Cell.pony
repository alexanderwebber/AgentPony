use "promises"
use "collections"

actor Cell
    var _position:        USize
    var _status:          U64
    let _out:             OutStream
    let _neighbors:       Array[Cell] = Array[Cell](8)
    let _frozenNeighbors: Array[U64]  = Array[U64](8)

    new create(position': USize, status': U64, out': OutStream) =>
        _position = position'
        _status   = status'
        _out      = out'

    be getStatus(p: Promise[U64]) =>
        p(_status)

    be setNeighbor(neighbor: Cell, p: Promise[USize]) =>
        _neighbors.push(neighbor)
        p(_position)

    be sendStatus(sim: SimulationSpace) =>
        let sendableStatus: U64 = recover val _status end
        sim.receiveStatus(sendableStatus)

    be freezeNeighbors(pr: Promise[U64]) =>
        let neighborStatusPromises: Array[Promise[U64]] = Array[Promise[U64]](8)

        for neighbor in _neighbors.values() do 
            let p = Promise[U64]
            neighbor.getStatus(p)
            neighborStatusPromises.push(p)
        end

        Promises[U64].join(neighborStatusPromises.values())
        .next[None](recover this~updateFrozenStatuses(where p = pr) end)

    be updateFrozenStatuses(frozenNeighborStatuses: Array[U64] val, p: Promise[U64]) =>
        for i in Range(0, frozenNeighborStatuses.size()) do 
            try 
                _frozenNeighbors.update(i, frozenNeighborStatuses(i)?)?
            else
                try
                    _frozenNeighbors.push(frozenNeighborStatuses(i)?)
                end
            end     
        end

        p(_status)

    be updateStatus(p: Promise[(U64, USize)]) =>
        var numLiveNeighbors: U64 = 0

        for status in _frozenNeighbors.values() do
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

        p((_status, _position))