use "pony_test"
use "../../AgentPony"

actor Main is TestList
    new create(env: Env) =>
        PonyTest(env, this)

    new make() =>
        None

    fun tag tests(test: PonyTest) =>
        test(_TestLoadNeighbors)
        test(_TestEndBlinker)
    
class iso _TestLoadNeighbors is UnitTest
    fun name(): String => "calculate the neighbor sum"

    fun apply(h: TestHelper) =>
        let sim5: SimulationSpace = SimulationSpace(5)
        sim5.testNeighborIndices(90, 96, h)

        let sim3: SimulationSpace = SimulationSpace(3)
        sim3.testNeighborIndices(36, 32, h)

class iso _TestEndBlinker is UnitTest
    fun name(): String => "test end state for blinker start seed"

    fun apply(h: TestHelper) =>
        let simEven: SimulationSpace = SimulationSpace(5)
        simEven.>loadBlinkerFive().>loadNeighbors().>runGameOfLife(2).>gatherCellStatus().>testEndStateBlinkerFive(2, h)

        let simOdd: SimulationSpace = SimulationSpace(5)
        simOdd.>loadBlinkerFive().>loadNeighbors().>runGameOfLife(3).>gatherCellStatus().>testEndStateBlinkerFive(3, h)
