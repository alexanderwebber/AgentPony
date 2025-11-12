use "collections"

class Cell
    var _position:        USize
    var _status:          USize
    var _previous:        USize
    var _changed:         Bool
    var _inactiveCounter: USize
    var _inactive:        Bool
    let _out:             OutStream

    new create(position': USize, status': USize, out': OutStream) =>
        _position        = position'
        _status          = status'
        _previous        = 100
        _changed         = true
        _inactiveCounter = 0
        _inactive        = false
        _out             = out'

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

        if _changed then
            _inactiveCounter = 0
            _inactive        = false
        else
            _inactiveCounter = _inactiveCounter + 1
            
            if _inactiveCounter >= 3 then
                _inactive = false
            end
        end

        if (_inactive) and (_inactiveCounter > 3) then
            _previous = _status
        else
            let sendablePosition: USize = recover val _position end
            let sendableStatus:   USize = recover val _status   end
            let sendableChanged:  Bool  = recover val _changed  end
            let sendableInactive: Bool  = recover val _inactive end

            sim.localCellStatesCalculated(sendableChanged, sendablePosition, sendableStatus, sendableInactive)
            
            _previous = _status
        end

    fun ref setStatus(status': USize) =>
        _status = status'

    fun getPosition(): USize =>
        let sendablePosition: USize = recover val _position end
        sendablePosition
        
