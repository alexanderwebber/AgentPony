use "pony_test"

actor Main is TestList
    new create(env: Env) =>
        PonyTest(env, this)

    new make() =>
        None

    fun tag tests(test: PonyTest) =>
        test(_TestLoadNeighbors)
    
class iso _TestLoadNeighbors is UnitTest
    fun name(): String => "loadNeighbors"

    fun apply(h: TestHelper) =>
        h.assert_eq[U32](4, 2 + 2)