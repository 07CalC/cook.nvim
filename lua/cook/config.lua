-- this module configures the Cook plugin
-- it allows users to set custom runners and UI options

local M = {}

-- default configuration options for the Cook plugin
-- these can be overridden by the user in their setup function
local defaults = {
	terminal = {
		width = 0.8,
		height = 0.8,
		border = "rounded",
		layout = "float", -- or "bottom" (for bottom split), "vertical" (for vertical split)
	},
	runners = {
		-- new named placeholder syntax (recommended):
		-- {file}     - full file path
		-- {filename} - filename with extension
		-- {name}     - filename without extension
		-- {dir}      - directory path
		-- {ext}      - file extension
		-- {exe}      - full executable path (dir + name)

		py = "python3 {file}",
		c = "gcc {file} -o {exe} && {exe}",
		cpp = "g++ {file} -o {exe} && {exe}",
		rs = "cargo run",
		js = "bun {file}",
		ts = "bun {file}",
		go = "go run {file}",

		-- legacy %s syntax still supported
		-- py = "python3 %s",              -- single %s becomes {file}
		-- c = "gcc %s -o %s && %s",       -- triple %s becomes {file}, {exe}, {exe}

		-- advanced examples:
		-- java = "javac {file} && java -cp {dir} {name}",
		-- asm = "nasm -f elf64 {file} -o {name}.o && ld {name}.o -o {exe} && {exe}",
		-- tex = "cd {dir} && pdflatex {filename}",
	},
}

-- initialize the options table with defaults
M.options = vim.deepcopy(defaults)

-- setup function to initialize the plugin with user configuration
function M.setup(user_config)
	M.options = vim.tbl_deep_extend("force", M.options, user_config or {})
end

return M
