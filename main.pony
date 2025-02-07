actor Main
    let _out: OutStream

    new create(env: Env) =>
        _out = env.out

        let simSideLength        = try env.args(1)?.usize()? else 5      end
        let timeSteps            = try env.args(2)?.usize()? else 3      end
        // Default to value approach
        if simSideLength < 3 then _out.print("Simulation side length must be at least 3... Defaulting to 5\n") end
        let adjustedSideLength   = if simSideLength < 3 then 5 else simSideLength end
        let sim: SimulationSpace = SimulationSpace(adjustedSideLength, _out)
        

        // Exit Approach 
        /*
        if simSideLength < 3 then 
            _out.print("Simulation side length must be at least 3.\n")
            return    
            
        end
        */


        sim.>loadBlinkerFive().>loadNeighbors().>runGameOfLife(timeSteps)