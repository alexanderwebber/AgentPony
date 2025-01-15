use "promises"

actor Cell
    var _position: USize
    var _status:   U64 val

    new create(position': USize, initalStatus: U64 val) =>
        _position = position'
        _status   = initalStatus

    be getPosition(p: Promise[USize]) =>
        p(_position)

    be getStatus(p: Promise[U64]) =>
        p(_status)
    