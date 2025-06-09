import HTTP, JSON3
using Test
using Dash

@testset "Multiple callbacks to same output" begin
    app = dash()
    app.layout = html_div() do
        dcc_input(id = "input1", value="value1", type = "text"),
        dcc_input(id = "input2", value="value2", type = "text"),
        html_div(id = "output")
    end

    # First callback
    callback!(app, Output("output", "children"), Input("input1", "value")) do value
        return "From input1: $value"
    end

    # Second callback to same output - requires allow_duplicate=true
    callback!(app, Output("output", "children"), Input("input2", "value"), allow_duplicate=true) do value
        return "From input2: $value"
    end

    # Test that both callbacks are registered
    @test length(app.callbacks) == 1
    @test haskey(app.callbacks, Symbol("output.children"))
    @test length(app.callbacks[Symbol("output.children")]) == 2

    # Test that both callbacks work correctly
    @test app.callbacks[Symbol("output.children")][1].func("test1") == "From input1: test1"
    @test app.callbacks[Symbol("output.children")][2].func("test2") == "From input2: test2"

    # Test that dependencies are properly generated
    handler = make_handler(app)
    request = HTTP.Request("GET", "/_dash-dependencies")
    resp = Dash.HttpHelpers.handle(handler, request)
    deps = JSON3.read(String(resp.body))
    
    @test length(deps) == 2
    
    # Both callbacks should have the same output but different inputs
    @test all(d -> d.output == "output.children", deps)
    @test deps[1].inputs[1].id == "input1"
    @test deps[1].inputs[1].property == "value"
    @test deps[2].inputs[1].id == "input2"
    @test deps[2].inputs[1].property == "value"

    # Test actual callback execution
    # When input1 changes, the first callback should be triggered
    test_json1 = JSON3.write((
        output = "output.children",
        changedPropIds = ["input1.value"],
        inputs = [(id = "input1", property = "value", value = "test_value1")]
    ))
    request1 = HTTP.Request("POST", "/_dash-update-component", [], Vector{UInt8}(test_json1))
    response1 = Dash.HttpHelpers.handle(handler, request1)
    @test response1.status == 200
    resp_obj1 = JSON3.read(String(response1.body))
    @test resp_obj1.response.output.children == "From input1: test_value1"

    # When input2 changes, the second callback should be triggered
    test_json2 = JSON3.write((
        output = "output.children",
        changedPropIds = ["input2.value"],
        inputs = [(id = "input2", property = "value", value = "test_value2")]
    ))
    request2 = HTTP.Request("POST", "/_dash-update-component", [], Vector{UInt8}(test_json2))
    response2 = Dash.HttpHelpers.handle(handler, request2)
    @test response2.status == 200
    resp_obj2 = JSON3.read(String(response2.body))
    @test resp_obj2.response.output.children == "From input2: test_value2"
end

@testset "Multiple callbacks with NoUpdate" begin
    app = dash()
    app.layout = html_div() do
        dcc_input(id = "input1", value="value1", type = "text"),
        dcc_input(id = "input2", value="value2", type = "text"),
        html_div(id = "output")
    end

    # First callback returns NoUpdate
    callback!(app, Output("output", "children"), Input("input1", "value")) do value
        return no_update()
    end

    # Second callback returns a value
    callback!(app, Output("output", "children"), Input("input2", "value"), allow_duplicate=true) do value
        return "From input2: $value"
    end

    @test length(app.callbacks[Symbol("output.children")]) == 2

    handler = make_handler(app)
    
    # Test that when the first callback returns NoUpdate, the second still processes
    test_json = JSON3.write((
        output = "output.children",
        changedPropIds = ["input2.value"],
        inputs = [(id = "input2", property = "value", value = "test_value")]
    ))
    request = HTTP.Request("POST", "/_dash-update-component", [], Vector{UInt8}(test_json))
    response = Dash.HttpHelpers.handle(handler, request)
    @test response.status == 200
    resp_obj = JSON3.read(String(response.body))
    @test resp_obj.response.output.children == "From input2: test_value"
end

@testset "Multiple callbacks all return NoUpdate" begin
    app = dash()
    app.layout = html_div() do
        dcc_input(id = "input1", value="value1", type = "text"),
        dcc_input(id = "input2", value="value2", type = "text"),
        html_div(id = "output")
    end

    # Both callbacks return NoUpdate
    callback!(app, Output("output", "children"), Input("input1", "value")) do value
        return no_update()
    end

    callback!(app, Output("output", "children"), Input("input2", "value"), allow_duplicate=true) do value
        return no_update()
    end

    handler = make_handler(app)
    
    # Test that when all callbacks return NoUpdate, we get a 204 response
    test_json = JSON3.write((
        output = "output.children",
        changedPropIds = ["input1.value"],
        inputs = [(id = "input1", property = "value", value = "test_value")]
    ))
    request = HTTP.Request("POST", "/_dash-update-component", [], Vector{UInt8}(test_json))
    response = Dash.HttpHelpers.handle(handler, request)
    @test response.status == 204  # No content due to all NoUpdate
end