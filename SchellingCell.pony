use "collections"

class SchellingCell
    var _position:   USize
    var _status:     USize
    var _threshhold: USize
    var _satisfied:  Bool
    let _out:        OutStream

    new create(position': USize, status': USize, threshhold': USize, out': OutStream) =>
        _position   = position'
        _status     = status'
        _threshhold = threshhold'
        _satisfied  = true
        _out        = out'

    fun ref updateStatus(neighborStatuses: Array[USize] iso, sim: SimulationSpace) =>
        let statuses:         Array[USize]  = consume neighborStatuses
        var numDiffNeighbors: USize         = 0

        for status in statuses.values() do
            if status != _status then
                numDiffNeighbors = numDiffNeighbors + 1
            end
        end

        if (_status == 1) and ((_status == 2) and (numDiffNeighbors > _threshhold)) then 
            _satisfied = false
        else
            _satisfied = true
        end

        let sendablePosition:       USize = recover val _position    end
        let sendableStatus:         USize = recover val _status      end
        let sendableSatisfaction:   Bool  = recover val _satisfied   end

        sim.localSatisfactionCalculated(sendableSatisfaction, sendablePosition, sendableStatus)