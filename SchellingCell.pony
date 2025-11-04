use "collections"

class SchellingCell
    var _position:        USize
    var _status:          USize
    var _threshhold:      USize
    var _inactiveCounter: USize
    var _satisfied:       Bool
    var _previous:        Bool
    var _inactive:        Bool
    let _out:             OutStream

    new create(position': USize, status': USize, threshhold': USize, out': OutStream) =>
        _position        = position'
        _status          = status'
        _threshhold      = threshhold'
        _satisfied       = true
        _previous        = false
        _inactive        = false
        _inactiveCounter = 0

        _out        = out'

    fun ref updateStatus(neighborStatuses: Array[USize] iso, sim: SimulationSpace) =>
        let statuses:         Array[USize]  = consume neighborStatuses
        var numDiffNeighbors: USize         = 0

        for status in statuses.values() do
            if (status != _status) and (status != 0) then
                numDiffNeighbors = numDiffNeighbors + 1
            end
        end

        if ((_status == 1) or (_status == 2)) and (numDiffNeighbors > _threshhold) then 
            _satisfied = false
        else
            _satisfied = true
        end        

        if (_previous == _satisfied) and (_satisfied == true) and (_status != 0) then 
            _inactiveCounter = _inactiveCounter + 1

            if _inactiveCounter == 3 then 
                _inactive = true    
            end
        else 
            _inactiveCounter = 0
            _inactive        = false
        end

        if (_inactive) and (_inactiveCounter > 3) then
            _previous = _satisfied

        else
            let sendablePosition:       USize = recover val _position  end
            let sendableStatus:         USize = recover val _status    end
            let sendableSatisfaction:   Bool  = recover val _satisfied end
            let sendableInactive:       Bool  = recover val _inactive  end

            sim.localSatisfactionCalculated(sendablePosition, sendableStatus, sendableSatisfaction, sendableInactive)

            _previous = _satisfied
        end

    fun ref setStatus(status': USize) =>
        _status = status'

    fun getPosition(): USize =>
        let sendablePosition: USize = recover val _position end
        sendablePosition