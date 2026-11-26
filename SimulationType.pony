primitive GameOfLife
    fun name(): String => "game_of_life"

primitive Schelling
    fun name(): String => "schellings"

type SimulationType is (GameOfLife | Schelling)

primitive ParseSimulationType
    fun apply(name: String): (SimulationType | None) =>
        if name == GameOfLife.name() then
            GameOfLife
        elseif name == Schelling.name() then
            Schelling
        else
            None
        end
