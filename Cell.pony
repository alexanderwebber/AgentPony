use "promises"

actor Cell
    var _position:  USize
    var _status:    U64 val
    let _out:       OutStream
    let _neighbors: Array[Cell] = Array[Cell](8)

    new create(position': USize, initalStatus: U64 val, out: OutStream) =>
        _position = position'
        _status   = initalStatus
        _out      = out

    be getPosition(p: Promise[USize]) =>
        p(_position)

    be getStatus(p: Promise[U64]) =>
        p(_status)

    be printPosition() =>
        _out.print(_position.string())

    be printStatus() =>
        _out.print(_status.string())

    be setNeighbor(neighbor: Cell) =>
        _neighbors.push(neighbor)
        