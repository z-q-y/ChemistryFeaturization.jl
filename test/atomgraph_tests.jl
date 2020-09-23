using Test
using LightGraphs
using JLD2
include("../src/pmg_graphs.jl")
include("../src/atomgraph.jl")

@testset "AtomGraph" begin
    # build a silly little triangle graph
    g = SimpleWeightedGraph{Int32}(Float32.([0 1 1; 1 0 1; 1 1 0]))

    # add an element list that doesn't make sense
    @test_throws AssertionError AtomGraph(g, ["C"])

    # okay, now do it right, start with no features
    ag = AtomGraph(g, ["C", "C", "C"])

    # check LightGraphs fcns
    @test eltype(ag)==Int32
    @test edgetype(ag)==SimpleWeightedEdge{Int32,Float32}
    @test ne(ag)==3
    @test nv(ag)==3
    @test !is_directed(ag)
    # not sure the best way to test the ones that return iterators, e.g. edges
    @test outneighbors(ag,1)==inneighbors(ag,1)==[2,3]
    @test has_vertex(ag,1)
    @test !has_vertex(ag,4)
    @test has_edge(ag,1,2)

    # add some features
    bad_fmat = Float32.([1 2; 3 4])
    good_fmat = Float32.([1 2 3; 4 5 6])
    featurization = [AtomFeat(:feat, true, 2, false, ['a','b'])]
    @test_throws AssertionError add_features!(ag, bad_fmat, featurization)
    add_features!(ag, good_fmat, featurization)
    @test ag.features==good_fmat

    # tests for other signatures of add_features! where feature vectors are built automatically
    ag = AtomGraph(g, ["C", "C", "C"])
    ag2 = deepcopy(ag)
    ag3 = deepcopy(ag)
    feature_names = [:Block, :X]
    vecs, featurization = make_feature_vectors(feature_names, nbins=[4,3])

    add_features!(ag, vecs, featurization)
    add_features!(ag2, featurization)
    add_features!(ag3, feature_names, Int32.([4,3]))

    @test ag.features==ag2.features==ag3.features==Float32.(hcat([vecs["C"] for i in 1:3]...))
end

@testset "graph-building" begin
    ag = build_graph(joinpath(@__DIR__, "./test_data/mp-195.cif"))
    wm_true = [0.0 1.0 1.0 1.0; 1.0 0.0 1.0 1.0; 1.0 1.0 0.0 1.0; 1.0 1.0 1.0 0.0]
    @test weights(ag) == wm_true
    @test ag.elements == ["Ho", "Pt", "Pt", "Pt"]
    ag = build_graph(joinpath(@__DIR__, "./test_data/mp-195.cif"); use_voronoi=false)
    @test weights(ag) == wm_true
    @test ag.elements == ["Ho", "Pt", "Pt", "Pt"]
end

#TODO: redo with JSON versions, make sure to test order of features in featurization
@testset "save/load" begin
    
end

"""
@testset "save/load" begin
    g = SimpleWeightedGraph{Int32}(Float32.([0 1 1; 1 0 1; 1 1 0]))
    fmat = Float32.([1 2 3; 4 5 6])
    featurization = [AtomFeat(:feat, true, 2, false, ['a','b'])]
    ag = AtomGraph(g, ["C", "C", "C"], fmat, featurization)
    @save "./test_data/testgraph.jld2" ag
    ag = nothing
    @load "./test_data/testgraph.jld2" ag
    @test ag.features==fmat
    @test ag.elements==["C", "C", "C"]
    @test ag.lapl==Float32.([1 -0.5 -0.5; -0.5 1 -0.5; -0.5 -0.5 1])
end
"""