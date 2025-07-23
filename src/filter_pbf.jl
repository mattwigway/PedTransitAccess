using OpenStreetMapPBF, MissingLinks

import MissingLinks: TraversalPermissionSettings, is_traversable
import DataStructures: DefaultDict
import MetaGraphsNext: label_for
import Graphs: neighbors
import LibSpatialIndex: RTree, knn

# some software won't handle negative way IDs, so just put them well above currently numbered OSM ways.
const STARTING_WAY_ID = 1 << 40

function create_pbfs(input, baseout, scenout, links, G)
    # load and filter base PBF
    nodeids = Set{Int64}()
    ways = Way[]

    # no need to parse relations for pedestrians
    settings = TraversalPermissionSettings()
    scan_ways(input) do way
        if is_traversable(settings, way)
            push!(ways, way)
            push!.(Ref(nodeids), way.nodes)
        end
    end

    nodes = Dict{Int64, Node}()

    scan_nodes(input) do node
        if node.id ∈ nodeids
            nodes[node.id] = node
        end
    end

    write_pbf(baseout, values(nodes), ways, [])

    insert_links!(G, ways, nodes, links)

    write_pbf(scenout, values(nodes), ways, [])
end
