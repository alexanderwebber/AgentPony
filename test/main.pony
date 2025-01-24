use "pony_test"
use "../../AgentPony"

actor Main is TestList
    new create(env: Env) =>
        PonyTest(env, this)

    new make() =>
        None

    fun tag tests(test: PonyTest) =>
        test(_TestLoadNeighbors)
    
class iso _TestLoadNeighbors is UnitTest
    fun name(): String => "calculate the neighbor sum"

    fun apply(h: TestHelper) =>
        let sim5: SimulationSpace = SimulationSpace(5)
        h.assert_eq[USize](90, sim5.returnNeighborSum(0))
        h.assert_eq[USize](96, sim5.returnNeighborSum(12))

        let sim3: SimulationSpace = SimulationSpace(3)
        h.assert_eq[USize](36, sim3.returnNeighborSum(0))
        h.assert_eq[USize](32, sim3.returnNeighborSum(4))
