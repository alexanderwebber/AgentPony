actor Main

    let _out: OutStream

    new create(env: Env) =>
        _out = env.out

        let simSideLength        = try env.args(2)?.usize()? else 5 end
        let sim: SimulationSpace = SimulationSpace(simSideLength, _out)
        sim.loadRandomPositions()


        _out.print("Side length of simulation space is: " + sim.getSideLength().string())
        _out.print("There are " + (simSideLength * simSideLength).string() + " cells.")