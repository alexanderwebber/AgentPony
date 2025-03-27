actor Main
    let _out: OutStream

    new create(env: Env) =>
        _out = env.out

        let simSideLength        = try env.args(1)?.usize()? else 5      end
        let timeSteps            = try env.args(2)?.usize()? else 5      end

        let sim: SimulationSpace = SimulationSpace(simSideLength, _out, timeSteps)

        sim.>loadRandomPositions().>runGameOfLife()