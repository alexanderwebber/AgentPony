use "promises"

actor Cell
    var position: USize
    var status:   U64 val

    new create(position': USize, initalStatus: U64 val) =>
        position = position'
        status   = initalStatus

    be getPosition(p: Promise[USize]) =>
        p(position)

    be getStatus(p: Promise[U64]) =>
        p(status)
    