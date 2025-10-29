use "files"

actor Main
    new create(env: Env) =>
        let simSideLength:  USize      = try env.args(1)?.usize()? else 64             end
        let timeSteps:      USize      = try env.args(2)?.usize()? else 30             end
        let numPartitions:  USize      = try env.args(3)?.usize()? else 4              end
        let runNumber:      USize      = try env.args(4)?.usize()? else 0              end
        let simulationType: String     = try env.args(5)?          else "game_of_life" end

        let out:            OutStream  = env.out

        try
            let dir: FilePath = FilePath.create(FileAuth(env.root), "output")
            dir.mkdir()

            let simFileName: FilePath = FilePath.from(dir, "simulation_output_" 
                                                        + simulationType 
                                                        + "_" 
                                                        + runNumber.string() 
                                                        + ".txt")?

            let file = recover iso
                match CreateFile(simFileName)
                | let f: File => f
                else
                    error
                end
            end

            let coordinator: Coordinator = Coordinator(simSideLength, timeSteps, numPartitions, out, consume file)
            
            coordinator.initSimulation()
        else
            env.err.print("Cannot create output file")
        end