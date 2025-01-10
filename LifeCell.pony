use "promises"

actor LifeCell
    var position: USize

    new create(position': USize) =>
        position = position'

    be getPosition(p: Promise[USize]) =>
        p(position)
    