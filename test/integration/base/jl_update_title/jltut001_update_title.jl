using Dash

app = dash()
app.layout = html_div(children = "Hello world!", id = "hello-div")
run_server(app)
