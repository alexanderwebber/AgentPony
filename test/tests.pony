use "pony_test"
use "../../AgentPony"

actor Main is TestList
    let _out: OutStream

    new create(env: Env) =>
        _out = env.out
        PonyTest(env, this)

    new make() =>
        None

    fun tag tests(test: PonyTest) =>
        test(_TestLoadNeighbors)
        test(_TestEndBlinker)
    
class iso _TestLoadNeighbors is UnitTest
    fun name(): String => "calculate the neighbor sum"

    fun apply(h: TestHelper) =>
        let sim5: SimulationSpace = SimulationSpace(5, _out)
        sim5.testNeighborIndices(90, 96, h)

        let sim3: SimulationSpace = SimulationSpace(3, _out)
        sim3.testNeighborIndices(36, 32, h)

class iso _TestEndBlinker is UnitTest
    fun name(): String => "test end state for blinker start seed"

    fun apply(h: TestHelper) =>
        let simEven: SimulationSpace = SimulationSpace(5, out)
        simEven.>loadBlinkerFive().>loadNeighbors().>runGameOfLife(74).>gatherCellStatus().>testEndStateBlinkerFive(74, h)

        let simOdd: SimulationSpace = SimulationSpace(5, out)
        simOdd.>loadBlinkerFive().>loadNeighbors().>runGameOfLife(53).>gatherCellStatus().>testEndStateBlinkerFive(53, h)
