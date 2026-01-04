# 🍳 cook.nvim

**cook.nvim** is a modular and extensible Neovim plugin that lets you effortlessly compile or run the current file based on its filetype — inside a floating terminal.

### default runner based on file extension

![default-cook-demo](https://github.com/user-attachments/assets/9564866f-8345-4b3f-9a5d-73b5de85676d)

### custom project recipes

![recipes-cook-demo](https://github.com/user-attachments/assets/cb05b37e-b741-4928-883c-26a8780f05f8)

### `:Coop` auto paste the clipboard, helpful for Competetive Programming

![coop-cook-demo](https://github.com/user-attachments/assets/fe9dc656-0c1c-4206-84a0-7767f20ef92f)

Supports:

-  Python
-  Rust
-  C/C++
-  JavaScript / TypeScript
-  Go

##  Features

-  Runs code from the current buffer based on its extension
-  Opens a floating terminal inside Neovim
-  Easily extendable for **any language** with powerful placeholder system
-  Named placeholders: `{file}`, `{name}`, `{dir}`, `{exe}`, etc.
-  Define per-project tasks with `recipes.lua` (also supports placeholders!)
-  Smart filetype-to-runner resolution
-  `:Coop` mode for Competitive Programming
-  Backward compatible with legacy `%s` syntax
-  Tasks starting with `!` run as native Vim commands — useful for plugins like `cmake-tools.nvim`
-  Minimal setup, pure Lua

##  Installation

### Using **lazy.nvim**:

```lua
{
  "07CalC/cook.nvim",
  config = function()
    require("cook").setup()
  end,
  cmd = "Cook",
}
```

### Using **packer.nvim**:

```lua
use {
  "07CalC/cook.nvim",
  config = function()
    require("cook").setup()
  end
}
```

##  Usage

```vim
:help cook
```

### Default

In any buffer, simply run:

```vim
:Cook
```

It will:

1. Detect the filetype by extension.
2. Build the appropriate shell command.
3. Open a floating terminal and run it.

### Custom recipes

If your project has a `recipes.lua` in its root, you can:

```vim
:Cook dev
:Cook build
```

#### Project Recipes (recipes.lua)

Define custom tasks at the project root (detected via .git or recipes.lua) using a recipes.lua file.

**Recipes now support placeholders too!**

```lua
--- recipes.lua
return {
  recipes = {
    -- Simple recipes without placeholders
    dev = "cargo watch -x run",
    build = "cargo build --release",
    test = "cargo test",
    fmt = "cargo fmt",
    
    -- Recipes with placeholders (file-specific)
    compile = "gcc {file} -o {exe} -Wall",
    run = "{exe}",
    debug = "gcc -g {file} -o {exe} && gdb {exe}",
    
    -- Advanced: combine file-specific and project-wide commands
    build_and_run = "mkdir -p build && gcc {file} -o build/{name} && build/{name}",
    
    -- Vim command integration
    cmake_build = "!CMakeBuild", -- runs as a Vim command
  }
}
```

**Using placeholders in recipes:**
- When you run `:Cook compile` from `main.c`, it executes: `gcc /path/to/main.c -o /path/to/main -Wall`
- Placeholders are substituted based on the current file in the buffer
- This lets you create file-specific recipes that work across your entire project!
- See `recipes.lua.example` in the repo for more examples

 Note:

- Commands starting with `!` are executed using `vim.cmd()`, letting you run Vim-native or plugin-provided commands.
- Use keymap `<ESC><ESC>` to leave terminal mode.
- Use command `:Cookt` or keymap `<leader><leader>t` to toggle terminal.

### CP Mode with `:Coop`

Competitive programming guys, this is for you.
Just copy the input (from a problem description) to clipboard, then run:

```vim
:Coop
```

It will:

1. Detect your filetype.
2. Create a temp file with clipboard contents.
3. Pipe the input to your program (< input.in).
4. Show the output in a terminal buffer.

#### No need to manually paste or prepare files!

##Supported Languages & Commands

You can configure your own runners, but here are the defaults:

```lua
runners = {
  py = "python3 {file}",
  c = "gcc {file} -o {exe} && {exe}",
  cpp = "g++ {file} -o {exe} && {exe}",
  rs = "cargo run",
  js = "bun {file}",
  ts = "bun {file}",
  go = "go run {file}",
}
```

### Placeholder System

**cook.nvim** now supports a powerful placeholder system that lets you customize runners for any language!

#### Available Placeholders:

| Placeholder | Description | Example (for `/home/user/project/main.c`) |
|-------------|-------------|-------------------------------------------|
| `{file}` | Full file path | `/home/user/project/main.c` |
| `{filename}` | Filename with extension | `main.c` |
| `{name}` | Filename without extension | `main` |
| `{dir}` | Directory path | `/home/user/project` |
| `{ext}` | File extension | `c` |
| `{exe}` | Executable path (dir + name) | `/home/user/project/main` |

#### Custom Runner Examples:

```lua
require("cook").setup({
  runners = {
    -- Simple runners
    py = "python3 {file}",
    sh = "bash {file}",
    lua = "lua {file}",
    
    -- Compiled languages
    c = "gcc {file} -o {exe} -Wall && {exe}",
    cpp = "g++ {file} -o {exe} -std=c++17 && {exe}",
    rust = "rustc {file} -o {exe} && {exe}",
    
    -- Advanced examples
    java = "javac {file} && java -cp {dir} {name}",
    go = "go build -o {exe} {file} && {exe}",
    asm = "nasm -f elf64 {file} -o {name}.o && ld {name}.o -o {exe} && {exe}",
    tex = "cd {dir} && pdflatex {filename}",
    
    -- TypeScript with custom output
    ts = "tsc {file} --outDir {dir}/dist && node {dir}/dist/{name}.js",
    
    -- C with debugging
    c = "gcc -g -Wall {file} -o {exe} && gdb {exe}",
  },
})
```

#### Backward Compatibility

The old `%s` syntax is still fully supported:

```lua
runners = {
  py = "python3 %s",              -- Single %s → replaced with {file}
  c = "gcc %s -o %s && %s",       -- Triple %s → replaced with {file}, {exe}, {exe}
}
```

Both syntaxes can coexist in the same configuration!

## Terminal Layout Options
By default, `cook.nvim` opens a floating terminal, but you can change this behavior to suit your workflow.

### Available Layouts:
- `float` → centered floating terminal (default)
- `bottom` → splits and runs in bottom window
- `vertical` → opens terminal in a vertical split

### 🔧 Configuration Example

```lua
require("cook").setup({
  terminal = {
    layout = "float",   -- or "bottom", "vertical"
    width = 0.8,        -- used for floating and vertical layout
    height = 0.3,       -- used for floating and bottom layout
    border = "rounded", -- border style for floating terminal
  },
})
```

## Advanced Examples

### Multi-Language Project Setup

```lua
require("cook").setup({
  runners = {
    -- Web Development
    js = "node {file}",
    ts = "ts-node {file}",
    jsx = "bun {file}",
    tsx = "bun {file}",
    
    -- Systems Programming
    c = "gcc {file} -o {exe} -Wall -Wextra && {exe}",
    cpp = "g++ {file} -o {exe} -std=c++20 -Wall && {exe}",
    rs = "rustc {file} && {exe}",
    go = "go run {file}",
    zig = "zig run {file}",
    
    -- Scripting Languages
    py = "python3 {file}",
    rb = "ruby {file}",
    lua = "lua {file}",
    sh = "bash {file}",
    pl = "perl {file}",
    
    -- JVM Languages
    java = "javac {file} && java -cp {dir} {name}",
    kt = "kotlinc {file} -include-runtime -d {name}.jar && java -jar {name}.jar",
    scala = "scala {file}",
    
    -- Other
    r = "Rscript {file}",
    jl = "julia {file}",
    php = "php {file}",
    swift = "swift {file}",
  },
})
```

### Project with Custom Build System

```lua
-- recipes.lua in your project root
return {
  recipes = {
    -- Development
    dev = "npm run dev",
    watch = "npm run watch",
    
    -- Building
    build = "npm run build",
    build_prod = "npm run build:prod",
    
    -- Testing with current file
    test = "npm test -- {filename}",
    test_watch = "npm test -- --watch {filename}",
    
    -- File-specific compilation (useful for C/C++ projects)
    compile_debug = "gcc -g -Wall {file} -o {exe}",
    compile_release = "gcc -O3 {file} -o {exe}",
    valgrind = "gcc -g {file} -o {exe} && valgrind {exe}",
    
    -- Multiple files
    compile_all = "gcc src/*.c -o bin/program",
    
    -- Integration with other tools
    format = "clang-format -i {file}",
    lint = "eslint {file}",
    cmake = "!CMakeBuild",
  }
}
```

## File Structure

```text
lua/
└── cook/
    ├── init.lua       -- Entry point
    ├── config.lua     -- Plugin config and default runners
    ├── filetype.lua   -- Filetype-based runner resolution
    ├── executor.lua   -- Terminal execution
    ├── commands.lua   -- Maps user commands (Cook, Coop)
    └── recipes.lua    -- Project-local task loader
```

## Contributing

PRs are welcome! You can:

- Add support for more languages
- Improve command detection
- Add UI options (like vertical split)
