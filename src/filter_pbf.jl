using OpenStreetMapPBF, MissingLinks

import MissingLinks: TraversalPermissionSettings, is_traversable
import DataStructures: DefaultDict
import MetaGraphsNext: label_for
import Graphs: neighbors

# some software won't handle negative way IDs, so just put them well above currently numbered OSM ways.
const STARTING_WAY_ID = 1 << 40

"""
    create_pbfs(input_pbf, baseline_pbf, scenario_pbf, links, graph, traversal_settings)

Create baseline and scenario PBFs by splicing `links` (identified using `graph`) into the
`input_pbf`.

Create PBF files from an input PBF file by:

(1) filtering based on
traversal settings (this is a MissingLinks RuleBasedTraversalSettings object,
or a custom traversal settings object with a method
`is_traversable(traversal_settings, ::OpenStreetMapPBF.Way)`,

(2) writing out the filtered PBF as `baseline_pbf`,

(3) splicing the links into the OSM data,

(4) writing the filtered and spliced PBF as `scenario_pbf`.

Using `input_pbf` or `traversal_settings` that don't match those used to build
`graph` will likely work, but may cause unexpected results if there are locations
that are topologically identical (i.e. ways that cross without intersecting, that
also have a link connected to them - and technically this is a problem even if that
is the case in the original OSM). Future work is to identify start and end ways
using the OSM IDs stored in the graph, rather than topologically.
"""
function create_pbfs(input, baseout, scenout, links, G, traversal_settings = MissingLinks.DEFAULT_TRAVERSAL_SETTINGS)
    # load and filter base PBF
    nodeids = Set{Int64}()
    ways = Way[]

    # no need to parse relations for pedestrians
    scan_ways(input) do way
        if is_traversable(traversal_settings, way)
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

    if !isnothing(baseout)
        write_pbf(baseout, values(nodes), ways, [])
    end

    insert_links!(G, ways, nodes, links)

    write_pbf(scenout, values(nodes), ways, [])
end
