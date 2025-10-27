actor Main
    let _out: OutStream

    new create(env: Env) =>
        _out = env.out

        let simSideLength            = try env.args(1)?.usize()? else 8 end
        let timeSteps                = try env.args(2)?.usize()? else 1 end
        let numPartitions            = try env.args(3)?.usize()? else 16 end

        let coordinator: Coordinator = Coordinator(simSideLength, timeSteps, numPartitions, _out)

        coordinator.initSimulation()