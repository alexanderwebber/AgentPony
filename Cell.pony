use "promises"

actor Cell
    var position: USize
    var status:   U8

    new create(position': USize, initalStatus: U8) =>
        position = position'
        status   = initalStatus

    be getPosition(p: Promise[USize]) =>
        p(position)

    be getStatus(p: Promise[U8]) =>
        p(status)
    