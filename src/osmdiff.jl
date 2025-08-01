import OpenStreetMapPBF: load_pbf
import Logging: @info

function main()
    f1, f2 = ARGS

    o1 = load_pbf(f1)
    o2 = load_pbf(f2)

    all_nodes = union(keys(o1.nodes), keys(o2.nodes))

    for nid in all_nodes
        if !haskey(o1.nodes, nid)
            @info("Node $nid is present in $f2 but not $f1")
        elseif !haskey(o2.nodes, nid)
            @info("Node $nid is present in $f1 but not $f2")
        else
            n1 = o1.nodes[nid]
            n2 = o2.nodes[nid]
            if !(n1.lat ≈ n2.lat && n1.lon ≈ n2.lon && n1.tags == n2.tags)
                @info "Node $nid is present in both files but is not the same" o1[nid] o2[nid]
            end
        end
    end

    all_ways = union(keys(o1.ways), keys(o2.ways))

    for nid in all_ways
        if !haskey(o1.ways, nid)
            @info("Way $nid is present in $f2 but not $f1")
        elseif !haskey(o2.ways, nid)
            @info("Way $nid is present in $f1 but not $f2")
        else
            w1 = o1.ways[nid]
            w2 = o2.ways[nid]
            if w1.nodes != w2.nodes || w1.tags != w2.tags
                @info "Way $nid is present in both files but is not the same" o1.ways[nid] o2.ways[nid]
            end
        end
    end
end

main()