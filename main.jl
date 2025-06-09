app = dash()
app.layout = html_div() do
    dcc_input(id = "input1", value="value1", type = "text"),
    dcc_input(id = "input2", value="value2", type = "text"),
    html_div(id = "output")
end

# First callback
callback!(
    app, 
    Output("output", "children"), 
    Input("input1", "value")) 
    do value
    return "From input1: $value"
end

# Second callback to same output
callback!(app, Output("output", "children"), Input("input2", "value")) do value
    return "From input2: $value"
end

run_server(app, "127.0.0.1", 8050, debug=true)

