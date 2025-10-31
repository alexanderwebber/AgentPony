use "promises"
use "collections"

class Cell
    var _position: USize
    var _status:   USize
    var _previous: USize
    var _changed:  Bool
    let _out:      OutStream

    new create(position': USize, status': USize, out': OutStream) =>
        _position  = position'
        _status    = status'
        _previous  = 100
        _changed   = true
        _out       = out'

    fun sendStateAndPosition(sim: SimulationSpace) =>
        let sendableStatus:   USize = recover val _status   end
        let sendablePosition: USize = recover val _position end

        sim.cellPositionStateReceived(sendablePosition, sendableStatus)

    fun ref updateStatus(neighborStatuses: Array[USize] iso, sim: SimulationSpace) =>
        let statuses:         Array[USize]  = consume neighborStatuses
        var numLiveNeighbors: USize         = 0

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

        if(_previous == _status) then 
            _changed = false    
        else
            _changed = true
        end

        _previous = _status

        let sendablePosition: USize = recover val _position end

        sim.localCellStatesCalculated(_changed, sendablePosition)