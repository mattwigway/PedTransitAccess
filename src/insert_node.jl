# the current highest node ID (Jul 2025) is between 1 << 33 and 1 << 34. 1 << 36 allows OSM to increase by a factor
# of 2^6 before having a collision.
const STARTING_NODE_ID = 1 << 40

"""
Insert a node into a way. Returns the new node ID (which may be an existing node if it is near an existing node).
"""
function insert_node!(way, nodes, point; tol=1)
    way_geom = get_way_geometry(way, nodes, GFT.EPSG(32119))
    dists = node_distances(way_geom)
    geos_geom = MissingLinks.gdal_to_geos(way_geom)
    desired_offset = LibGEOS.project(geos_geom, MissingLinks.gdal_to_geos(point))

    # is there an existing node we can use
    dist_from_desired = abs.(dists .- desired_offset)
    if min(dist_from_desired) ≤ tol
        return way.nodes[argmin(dist_from_desired)]
    else
        # we need to insert a new node. Give it a positive node ID in case negative node IDs
        # not supported by downstream software
        new_nid = STARTING_NODE_ID
        while haskey(nodes, new_nid)
            new_nid += 1
        end

        # figure out where to put it
        before_idx = findfirst(dists .> desired_offset)
        nodes[new_nid] = Node(new_nid, AG.gety(point, 0), AG.getx(point, 0), Dict())
        insert!(way.nodes, before_idx, new_nid)
        return new_nid
    end
end

"""
    node_distances(geom)

Return the Euclidean distance of each node from the start of the geometry
"""
function node_distances(geom::AG.IGeometry{AG.wkbLineString})
    dists = [0.0]
    dist = 0.0
    last_coord = [AG.getx(geom, 0), AG.gety(geom, 0)]
    for i in 1:(AG.ngeom(geom) - 1)
        coord = [AG.getx(geom, i), AG.gety(geom, i)]
        dist += norm2(coord .- last_coord)
        push!(dists)
        last_coord = coord
    end

    @assert dist ≈ AG.geomlength(geom)
    return dists
end

function get_way_geometry(way, nodes, crs)
    coords = Vector{Vector{Float64}}()

    for nid ∈ way.nodes
        node = nodes[nid]
        push!(coords, [node.lon, node.lat])
    end

    geom = AG.createlinestring(coords)

    return AG.reproject(geom, GFT.EPSG(4326), crs, order=:trad)
end

"""
    build_way_idx(ways, nodes)

Create an RTree indexing the ways. The stored value is the position in the ways array, not the way ID.
"""
function build_way_idx(ways, nodes)
    idx = RTree(2)
    for (idx, way) ∈ enumerate(ways)
        env = AG.envelope(get_way_geometry(way, nodes, CRS))
        insert!(idx, [env.MinX, env.MinY], [env.MaxX, env.MaxY])
    end

    return idx
end

geos_to_gdal(pt::LibGEOS.Point) = AG.createpoint([LibGEOS.getGeomX(pt), LibGEOS.getGeomY(pt)])

function find_closest(idx, pt, ways, nodes)
    candidates = knn(idx, pt)
    best_dist = typemax(Float64)
    best_candidate = nothing
    for candidate in candidates
        geom = get_way_geometry(ways[candidate], nodes, CRS)
        dist = AG.distance(geom, pt)
        if dist < best_dist
            best_dist = dist
            best_candidate = candidate
        end
    end

    return ways[best_candidate], best_dist
end


function insert_links!(G, ways, nodes, links)
    # index the ways
    idx = build_way_idx(ways, nodes)

    way_id = STARTING_WAY_ID
    for link ∈ links
        src_geom = MissingLinks.gdal_to_geos(G[label_for(link.fr_edge_src), label_for(G, link.fr_edge_tgt)])
        start = geos_to_gdal(LibGEOS.interpolate(src_geom, link.fr_dist_from_start))
        
        # find the closest way. It is possible this will not be the right way if the link connects at an intersection,
        # but topologically that's okay - it will just connect to the intersection which is connected to the right way.
        start_way, start_way_dist = find_closest(idx, start, ways, nodes)
        @assert start_way_dist .< 1e-6 # should be basically on the way

        # note that we do not update the geometry in the spatial index here, but that's okay; the envelope will not change
        # and the way is modified in place.
        start_node = insert_node!(start_way, nodes, start)

        dst_geom = MissingLinks.gdal_to_geos(G[label_for(link.to_edge_src), label_for(G, link.to_edge_tgt)])
        endd = geos_to_gdal(LibGEOS.interpolate(dst_geom, link.to_dist_from_start))
        end_way, end_way_dist = find_closest(idx, endd, ways, nodes)
        @assert end_way_dist .< 1e-6 # should be basically on the way

        end_node = insert_node!(end_way, nodes, endd)

        push!(ways, Way(way_id, [start_node, end_node], Dict("highway"=>"footway")))
        way_id += 1
    end
end