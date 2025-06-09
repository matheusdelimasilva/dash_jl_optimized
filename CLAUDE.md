# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Testing
- `julia --project test/runtests.jl` - Run all tests
- `julia --project -e "using Pkg; Pkg.test()"` - Alternative test runner

### Package Management
- `julia --project -e "using Pkg; Pkg.instantiate()"` - Install dependencies
- `julia --project -e "using Pkg; Pkg.build()"` - Build package

### Resource Generation
- `julia --project gen_resources/generate.jl` - Generate Dash components from Python sources (requires Python dependencies)

### Linting (CI checks)
- `markdownlint '**/*.md' --ignore-path=.gitignore` - Lint markdown files (requires Node.js)
- `git grep -n ' $'` - Check for trailing whitespace
- `git grep -nP '\t'` - Check for tab characters

## Architecture Overview

### Core Structure
- **DashApp** (`src/app/dashapp.jl`): Main application struct containing layout, callbacks, configuration, and dev tools
- **Components** (`src/Components.jl`): Auto-generated component wrappers for HTML/DCC/DataTable components 
- **Callbacks** (`src/app/callbacks.jl`): Reactive callback system with Input/Output/State pattern
- **HTTP Server** (`src/server.jl`, `src/HttpHelpers/`): HTTP.jl-based server with routing and request handling
- **Asset Management** (`src/handler/processors/`): Static file serving, hot reload, and resource bundling

### Component System
Components are auto-generated from Python Dash sources using `gen_resources/generate.jl`. The generation process:
1. Downloads component metadata from Python packages
2. Generates Julia component functions with snake_case naming (e.g., `html_div`, `dcc_graph`)
3. Components support both positional children and keyword arguments
4. Special `do` syntax for nested component hierarchies

### Callback Architecture
- Callbacks link component properties via `Input`, `Output`, and `State` objects
- Uses `callback!` function with do-block syntax for handler functions
- Supports pattern-matching callbacks with `ALL`, `MATCH`, `ALLSMALLER` for dynamic UIs
- Callback context provides information about triggered inputs
- Multiple callbacks can target the same output using `allow_duplicate=true` parameter

### Development Tools
Built-in dev tools system (`src/app/devtools.jl`) includes:
- Hot reload for Julia files and assets
- Props validation
- Debug UI components
- Component error boundaries

### Asset Pipeline
- Assets from `assets/` folder are automatically served
- CSS/JS files are automatically included in page head
- Support for external CDN resources vs local serving
- Asset fingerprinting and caching

### Environment Configuration
Environment variables prefixed with `DASH_` control various settings:
- `DASH_DEBUG` - Enable development mode
- `DASH_HOT_RELOAD` - Enable hot reloading
- Asset serving, URL prefixes, and callback behavior

### Test Structure
- Unit tests in `test/` with modular includes in `runtests.jl`
- Integration tests in `test/integration/` mirroring Python Dash test patterns
- Tests are organized by feature (callbacks, assets, components, etc.)