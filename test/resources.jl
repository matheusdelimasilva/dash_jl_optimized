using Test
using Dash: Resource, ResourcePkg, ResourcesRegistry,
    AppResource, AppRelativeResource, AppExternalResource, AppCustomResource, AppAssetResource, ApplicationResources,
    isdynamic, register_package!

@testset "lazy + dynamic" begin
    test_resource = Resource(
        relative_package_path = "test.js",
        dynamic = true
    )
    @test test_resource.async == :lazy
    @test isdynamic(test_resource, true)
    @test isdynamic(test_resource, false)

    test_resource = Resource(
        relative_package_path = "test.js",
        dynamic = false
    )
    @test test_resource.async == :none
    @test !isdynamic(test_resource, true)
    @test !isdynamic(test_resource, false)

    @test_throws ArgumentError test_resource = Resource(
        relative_package_path = "test.js",
        dynamic = false,
        async = :false
    )

    test_resource = Resource(
        relative_package_path = "test.js",
        async = :lazy
    )

    @test test_resource.async == :lazy
    @test isdynamic(test_resource, true)
    @test isdynamic(test_resource, false)

    test_resource = Resource(
        relative_package_path = "test.js",
        async = :eager
    )

    @test test_resource.async == :eager
    @test !isdynamic(test_resource, true)
    @test isdynamic(test_resource, false)
end


@testset "application resources base registry" begin
    test_registry = ResourcesRegistry(
        dash_dependency = (
            dev = ResourcePkg(
                "dash_renderer",
                "path",
                [
                    Resource(
                        relative_package_path = ["path1.dev.js", "path2.dev.js"],
                        external_url = ["external_path1.dev.js", "external_path2.dev.js"]
                    )
                ]
            ),
            prod = ResourcePkg(
                "dash_renderer",
                "path",
                [
                    Resource(
                        relative_package_path = ["path1.prod.js", "path2.prod.js"],
                        external_url = ["external_path1.prod.js", "external_path2.prod.js"]
                    )
                ]
            )
        ),
        dash_renderer = ResourcePkg(
            "dash_renderer",
            "path",
            [
                Resource(
                    relative_package_path = "dash-renderer/dash_renderer.min.js",
                    dev_package_path = "dash-renderer/dash_renderer.dev.js",
                    external_url = "https://dash_renderer.min.js"
                )
            ]
        )
    )

    test_app = dash(include_assets_files = false)

    app_resources = ApplicationResources(test_app, test_registry)
    @test length(app_resources.css) == 0
    @test length(app_resources.js) == 3
    @test app_resources.js[1] isa AppRelativeResource
    @test app_resources.js[1].namespace == "dash_renderer"
    @test app_resources.js[1].relative_path == "path1.prod.js"

    @test app_resources.js[2] isa AppRelativeResource
    @test app_resources.js[2].namespace == "dash_renderer"
    @test app_resources.js[2].relative_path == "path2.prod.js"

    @test app_resources.js[end] isa AppRelativeResource
    @test app_resources.js[end].namespace == "dash_renderer"
    @test app_resources.js[end].relative_path == "dash-renderer/dash_renderer.min.js"

    @test haskey(app_resources.files, "dash_renderer")
    @test app_resources.files["dash_renderer"].base_path == "path"
    @test "path1.prod.js" in app_resources.files["dash_renderer"].files
    @test "path2.prod.js" in app_resources.files["dash_renderer"].files
    @test "dash-renderer/dash_renderer.min.js" in app_resources.files["dash_renderer"].files

    test_app = dash(include_assets_files = false)
    enable_dev_tools!(test_app, debug = false, dev_tools_serve_dev_bundles = true)

    app_resources = ApplicationResources(test_app, test_registry)
    @test length(app_resources.css) == 0
    @test length(app_resources.js) == 3

    @test app_resources.js[1] isa AppRelativeResource
    @test app_resources.js[1].namespace == "dash_renderer"
    @test app_resources.js[1].relative_path == "path1.prod.js"

    @test app_resources.js[2] isa AppRelativeResource
    @test app_resources.js[2].namespace == "dash_renderer"
    @test app_resources.js[2].relative_path == "path2.prod.js"

    @test app_resources.js[end] isa AppRelativeResource
    @test app_resources.js[end].namespace == "dash_renderer"
    @test app_resources.js[end].relative_path == "dash-renderer/dash_renderer.dev.js"

    @test haskey(app_resources.files, "dash_renderer")
    @test app_resources.files["dash_renderer"].base_path == "path"
    @test "path1.prod.js" in app_resources.files["dash_renderer"].files
    @test "path2.prod.js" in app_resources.files["dash_renderer"].files
    @test "dash-renderer/dash_renderer.dev.js" in app_resources.files["dash_renderer"].files

    test_app = dash(include_assets_files = false)
    enable_dev_tools!(test_app, debug = false, dev_tools_props_check = true, dev_tools_serve_dev_bundles = true)

    app_resources = ApplicationResources(test_app, test_registry)
    @test length(app_resources.css) == 0
    @test length(app_resources.js) == 3

    @test app_resources.js[1] isa AppRelativeResource
    @test app_resources.js[1].namespace == "dash_renderer"
    @test app_resources.js[1].relative_path == "path1.dev.js"

    @test app_resources.js[2] isa AppRelativeResource
    @test app_resources.js[2].namespace == "dash_renderer"
    @test app_resources.js[2].relative_path == "path2.dev.js"

    @test app_resources.js[end] isa AppRelativeResource
    @test app_resources.js[end].namespace == "dash_renderer"
    @test app_resources.js[end].relative_path == "dash-renderer/dash_renderer.dev.js"

    @test haskey(app_resources.files, "dash_renderer")
    @test app_resources.files["dash_renderer"].base_path == "path"
    @test "path1.dev.js" in app_resources.files["dash_renderer"].files
    @test "path2.dev.js" in app_resources.files["dash_renderer"].files
    @test "dash-renderer/dash_renderer.dev.js" in app_resources.files["dash_renderer"].files

    test_app = dash(serve_locally = false, include_assets_files = false)

    app_resources = ApplicationResources(test_app, test_registry)
    @test length(app_resources.css) == 0
    @test length(app_resources.js) == 3

    @test app_resources.js[1] isa AppExternalResource
    @test app_resources.js[1].url == "external_path1.prod.js"

    @test app_resources.js[2] isa AppExternalResource
    @test app_resources.js[2].url == "external_path2.prod.js"

    @test app_resources.js[end] isa AppExternalResource
    @test app_resources.js[end].url == "https://dash_renderer.min.js"

    @test isempty(app_resources.files)
end

@testset "application resources dynamic" begin
    test_registry = ResourcesRegistry(
        dash_dependency = (
            dev = ResourcePkg(
                "dash_renderer",
                "path",
                [
                    Resource(
                        relative_package_path = "path1.dev.js",
                        external_url = "external_path1.dev.js"
                    )
                ]
            ),
            prod = ResourcePkg(
                "dash_renderer",
                "path",
                [
                    Resource(
                        relative_package_path = "path1.prod.js",
                        external_url = "external_path1.prod.js"
                    )
                ]
            )
        ),
        dash_renderer = ResourcePkg(
            "dash_renderer",
            "path",
            [
                Resource(
                    relative_package_path = "dash-renderer/dash_renderer.min.js",
                    external_url = "https://dash_renderer.min.js"
                ),
                Resource(
                    relative_package_path = "dash-renderer/dash_renderer.dyn.js",
                    external_url = "https://dash_renderer.dyn.js",
                    dynamic = true
                ),
                Resource(
                    relative_package_path = "dash-renderer/dash_renderer.eag.js",
                    external_url = "https://dash_renderer.eag.js",
                    async = :eager
                )

            ]
        )
    )

    test_app = dash(include_assets_files = false)

    app_resources = ApplicationResources(test_app, test_registry)
    @test length(app_resources.css) == 0
    @test length(app_resources.js) == 2
    @test app_resources.js[2].relative_path == "dash-renderer/dash_renderer.min.js"

    @test haskey(app_resources.files, "dash_renderer")
    @test app_resources.files["dash_renderer"].base_path == "path"
    @test "path1.prod.js" in app_resources.files["dash_renderer"].files
    @test "dash-renderer/dash_renderer.min.js" in app_resources.files["dash_renderer"].files
    @test "dash-renderer/dash_renderer.dyn.js" in app_resources.files["dash_renderer"].files
    @test "dash-renderer/dash_renderer.eag.js" in app_resources.files["dash_renderer"].files

    test_app = dash(eager_loading = true, include_assets_files = false)

    app_resources = ApplicationResources(test_app, test_registry)
    @test length(app_resources.css) == 0
    @test length(app_resources.js) == 3
    @test app_resources.js[2].relative_path == "dash-renderer/dash_renderer.min.js"
    @test app_resources.js[3].relative_path == "dash-renderer/dash_renderer.eag.js"
end

@testset "application resources components" begin
    test_registry = ResourcesRegistry(
        dash_dependency = (
            dev = ResourcePkg(
                "dash_renderer",
                "path",
                [
                    Resource(
                        relative_package_path = "path1.dev.js",
                        external_url = "external_path1.dev.js"
                    )
                ]
            ),
            prod = ResourcePkg(
                "dash_renderer",
                "path",
                [
                    Resource(
                        relative_package_path = "path1.prod.js",
                        external_url = "external_path1.prod.js"
                    )
                ]
            )
        ),
        dash_renderer = ResourcePkg(
            "dash_renderer",
            "path",
            [
                Resource(
                    relative_package_path = "dash-renderer/dash_renderer.min.js",
                    external_url = "https://dash_renderer.min.js"
                ),
            ]
        )
    )

    register_package!(test_registry,
        ResourcePkg(
            "comps",
            "comps_path",
            [
                Resource(
                    relative_package_path = "comp.js"
                ),
                Resource(
                    relative_package_path = "comp.dyn.js",
                    dynamic = true
                ),
                Resource(
                    relative_package_path = "comp.css",
                    type = :css
                )
            ]
        )
    )

    test_app = dash(include_assets_files = false)

    app_resources = ApplicationResources(test_app, test_registry)
    @test length(app_resources.css) == 1
    @test length(app_resources.js) == 3

    @test app_resources.js[1].relative_path == "path1.prod.js"
    @test app_resources.js[2].namespace == "comps"
    @test app_resources.js[2].relative_path == "comp.js"
    @test app_resources.js[end].relative_path == "dash-renderer/dash_renderer.min.js"

    @test haskey(app_resources.files, "comps")
    @test app_resources.files["comps"].base_path == "comps_path"
    @test "comp.js" in app_resources.files["comps"].files
    @test "comp.dyn.js" in app_resources.files["comps"].files
    @test "comp.css" in app_resources.files["comps"].files
end

@testset "application resources external" begin
    test_registry = ResourcesRegistry(
        dash_dependency = (
            dev = ResourcePkg(
                "dash_renderer",
                "path",
                [
                    Resource(
                        relative_package_path = "path1.dev.js",
                        external_url = "external_path1.dev.js"
                    )
                ]
            ),
            prod = ResourcePkg(
                "dash_renderer",
                "path",
                [
                    Resource(
                        relative_package_path = "path1.prod.js",
                        external_url = "external_path1.prod.js"
                    )
                ]
            )
        ),
        dash_renderer = ResourcePkg(
            "dash_renderer",
            "path",
            [
                Resource(
                    relative_package_path = "dash-renderer/dash_renderer.min.js",
                    external_url = "https://dash_renderer.min.js"
                ),
            ]
        )
    )

    external_css = ["test.css", Dict("rel"=>"stylesheet", "href"=>"test.css")]
    external_js = ["test.js", Dict("crossorigin"=>"anonymous", "src"=>"test.js")]
    test_app = dash(external_stylesheets = external_css, include_assets_files = false, external_scripts = external_js)

    app_resources = ApplicationResources(test_app, test_registry)
    @test length(app_resources.css) == 2
    @test length(app_resources.js) == 4

    @test app_resources.js[1].relative_path == "path1.prod.js"
    @test app_resources.js[end].relative_path == "dash-renderer/dash_renderer.min.js"

    @test app_resources.css[1] isa AppExternalResource
    @test app_resources.css[1].url == "test.css"

    @test app_resources.css[2] isa AppCustomResource
    @test app_resources.css[2].params["href"] == "test.css"
    @test app_resources.css[2].params["rel"] == "stylesheet"

    @test app_resources.js[2] isa AppExternalResource
    @test app_resources.js[2].url == "test.js"

    @test app_resources.js[3] isa AppCustomResource
    @test app_resources.js[3].params["src"] == "test.js"
    @test app_resources.js[3].params["crossorigin"] == "anonymous"

end
@testset "application resources assets" begin
    test_registry = ResourcesRegistry(
        dash_dependency = (
            dev = ResourcePkg(
                "dash_renderer",
                "path",
                [
                ]
            ),
            prod = ResourcePkg(
                "dash_renderer",
                "path",
                [
                ]
            )
        ),
        dash_renderer = ResourcePkg(
            "dash_renderer",
            "path",
            [
            ]
        )
    )

    test_app = dash(assets_folder = "assets_include")

    app_resources = ApplicationResources(test_app, test_registry)
    @test length(app_resources.css) == 1
    @test length(app_resources.js) == 4
    @test app_resources.favicon.path == "favicon.ico"
    @test all(app_resources.css) do r
        r isa AppAssetResource
    end
    @test app_resources.css[1].path == "test.css"

    @test all(app_resources.js) do r
        r isa AppAssetResource
    end

    @test any(app_resources.js) do r
        r.path == "test1.js"
    end
    @test any(app_resources.js) do r
        r.path == "test2.js"
    end
    @test any(app_resources.js) do r
        r.path == "sub/sub1.js"
    end
    @test any(app_resources.js) do r
        r.path == "sub/sub2.js"
    end

    test_app = dash(assets_folder = "assets_include", include_assets_files = false)

    app_resources = ApplicationResources(test_app, test_registry)
    @test length(app_resources.css) == 0
    @test length(app_resources.js) == 0
    @test app_resources.favicon ===  nothing

    test_app = dash(assets_folder = "assets_include", serve_locally = false)

    app_resources = ApplicationResources(test_app, test_registry)
    @test length(app_resources.css) == 1
    @test length(app_resources.js) == 4
    @test app_resources.favicon.path == "favicon.ico"
    @test all(app_resources.css) do r
        r isa AppAssetResource
    end
    @test app_resources.css[1].path == "test.css"

    @test all(app_resources.js) do r
        r isa AppAssetResource
    end

    @test any(app_resources.js) do r
        r.path == "test1.js"
    end
    @test any(app_resources.js) do r
        r.path == "test2.js"
    end
    @test any(app_resources.js) do r
        r.path == "sub/sub1.js"
    end
    @test any(app_resources.js) do r
        r.path == "sub/sub2.js"
    end

    test_app = dash(assets_folder = "assets_include", serve_locally = false, assets_external_path = "http://ext/")

    app_resources = ApplicationResources(test_app, test_registry)
    @test length(app_resources.css) == 1
    @test length(app_resources.js) == 4
    @test app_resources.favicon.path == "favicon.ico"

    @test all(app_resources.css) do r
        r isa AppExternalResource
    end

    @test app_resources.css[1].url == "http://ext/test.css"

    @test all(app_resources.js) do r
        r isa AppExternalResource
    end

    @test any(app_resources.js) do r
        r.url == "http://ext/test1.js"
    end
    @test any(app_resources.js) do r
        r.url == "http://ext/test2.js"
    end
    @test any(app_resources.js) do r
        r.url == "http://ext/sub/sub1.js"
    end
    @test any(app_resources.js) do r
        r.url == "http://ext/sub/sub2.js"
    end

    test_app = dash(assets_folder = "assets_include", assets_ignore = ".*1")

    app_resources = ApplicationResources(test_app, test_registry)
    @test length(app_resources.css) == 1
    @test length(app_resources.js) == 2
    @test app_resources.favicon.path == "favicon.ico"
    @test all(app_resources.css) do r
        r isa AppAssetResource
    end
    @test app_resources.css[1].path == "test.css"

    @test all(app_resources.js) do r
        r isa AppAssetResource
    end

    @test !any(app_resources.js) do r
        r.path == "test1.js"
    end
    @test any(app_resources.js) do r
        r.path == "test2.js"
    end
    @test !any(app_resources.js) do r
        r.path == "sub/sub1.js"
    end
    @test any(app_resources.js) do r
        r.path == "sub/sub2.js"
    end
end
