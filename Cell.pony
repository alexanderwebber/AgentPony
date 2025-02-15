use "promises"
use "collections"

actor Cell
    var _position:        USize
    var _status:          U64
    let _out:             OutStream

    new create(position': USize, status': U64, out': OutStream) =>
        _position = position'
        _status   = status'
        _out      = out'

    be sendStatusPosition(sim: SimulationSpace, p: Promise[U64]) =>
        let sendableStatus:   U64   = recover val _status   end
        let sendablePosition: USize = recover val _position end

        sim.receiveStatusPosition(sendableStatus, sendablePosition)

        p(_status)

    be updateStatus(neighborStatuses: Array[U64] iso) =>
        let statuses: Array[U64] box = consume neighborStatuses
        var numLiveNeighbors: U64 = 0

        for status in statuses.values() do
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