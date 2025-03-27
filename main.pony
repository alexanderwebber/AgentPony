actor Main
    let _out: OutStream

    new create(env: Env) =>
        _out = env.out

        let simSideLength        = try env.args(1)?.usize()? else 5      end
        let timeSteps            = try env.args(2)?.usize()? else 5      end
        
        if simSideLength < 3 then 
            _out.print("Simulation side length must be at least 3. Defaulting to 5\n")
            simSideLength = 3


        
        let sim: SimulationSpace = SimulationSpace(simSideLength, _out)

        sim.>loadRandomPositions().>runGameOfLife()