use "promises"
use "collections"

class Cell
    var _position: USize
    var _status:   USize
    let _out:      OutStream

    new create(position': USize, status': USize, out': OutStream) =>
        _position  = position'
        _status    = status'
        _out       = out'

    fun sendStateAndPosition(sim: SimulationSpace) =>
        let sendableStatus:   USize = recover val _status   end
        let sendablePosition: USize = recover val _position end

        sim.cellPositionStateUpdated(sendablePosition, sendableStatus)

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

        sim.localCellStatesCalculated()