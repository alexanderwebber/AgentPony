actor Main
    let _out: OutStream

    new create(env: Env) =>
        _out = env.out

        let simSideLength        = try env.args(1)?.usize()? else 3      end
        let timeSteps            = try env.args(2)?.usize()? else 1      end
        let sim: SimulationSpace = SimulationSpace(simSideLength, _out)

        sim.>loadBlinkerFive().>loadNeighbors().>runGameOfLife(timeSteps)