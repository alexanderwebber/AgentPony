actor Main

    let _out: OutStream

    new create(env: Env) =>
        _out = env.out

        let numCells             = try env.args(1)?.usize()? else 25 end
        let simSideLength        = try env.args(2)?.usize()? else 50 end

        let sim: SimulationSpace = SimulationSpace(simSideLength, numCells, _out)

        try sim.loadRandomPositions()? else _out.print("Error loading cells.") end

        _out.print("There are " + numCells.string() + " agents.")
        _out.print("Side length of simulation space is: " + sim.getSideLength().string())
        _out.print("Printing cell statuses: ")
        try sim.printCells()? else _out.print("Error printing cell statuses.") end