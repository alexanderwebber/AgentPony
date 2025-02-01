primitive SortTuple
    fun apply(a: Array[(U64, USize)], out: OutStream): Array[(U64, USize)]^ =>
        for i in a.values() do 
            out.print(i._2.string())
        end
        
        try _quickSortTuple(a, 0, a.size().isize() - 1)? end

        for i in a.values() do 
            out.print(i._2.string())
        end
        a

        

    fun _quickSortTuple(a: Array[(U64, USize)], low: ISize, high: ISize) ? =>
        if high <= low then return end

        if a(low.usize())?._2 > a(high.usize())?._2 then _swap(a, low, high)? end

        (var p, var q) = (a(low.usize())?._2, a(high.usize())?._2)
        (var l, var g) = (low + 1, high - 1)
         var k         = l

        while k <= g do
            if a(k.usize())?._2 < p then 
                _swap(a, k, l)?   
                l = l + 1

            elseif a(k.usize())?._2  >= q then 
                while (a(g.usize())?._2 > q) and (k < g) do g = g - 1 end

                _swap(a, k, g)?
                g = g - 1

                if a(k.usize())?._2 < p then
                    _swap(a, k, l)?
                    l = l + 1
                end
            end

            k = k + 1
        end

        (l, g) = (l - 1, g + 1)

        _swap(a, low, l)?
        _swap(a, high, g)?

        _quickSortTuple(a, low, l - 1)?
        _quickSortTuple(a, l + 1, g - 1)?
        _quickSortTuple(a, g + 1, high)?

    fun _swap(a: Array[(U64, USize)], i: ISize, j: ISize) ? =>
        a(j.usize())? = a(i.usize())? = a(j.usize())?