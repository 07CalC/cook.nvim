-- this module loads recipes from a lua file in the root of the project
-- it expects a table with a key "recipes" containing the project specific tasks
-- example:
-- recipes = {
--    my_task = "echo hello world"
--    build = "gcc {file} -o {exe}"
-- }
local M = {}

M.load_recipes = function()
	-- find the root of the project by looking for recipes.lua or .git
	local root = vim.fs.root(0, { "recipes.lua", ".git" })
	if not root then
		return nil
	end

	-- construct the path to recipes.lua
	local path = root .. "/recipes.lua"
	if vim.fn.filereadable(path) == 0 then
		return nil
	end

	local ok, data = pcall(dofile, path)
	if not ok or type(data) ~= "table" then
		return nil
	end

	-- return the recipes table if it exists, otherwise return nil
	return data.recipes or nil
end

-- resolves a recipe command by substituting placeholders for new version
-- @param recipe_cmd string: The recipe command with placeholders
-- @param filepath string: The current file path (optional, uses current buffer if nil)
-- @return string: The resolved command with substituted placeholders
M.resolve_recipe = function(recipe_cmd, filepath)
	if type(recipe_cmd) ~= "string" then
		return recipe_cmd
	end

	-- get current file path if not provided
	if not filepath or filepath == "" then
		filepath = vim.api.nvim_buf_get_name(0)
	end

	-- if no valid filepath, return command as it is (might be a command without placeholders)
	if not filepath or filepath == "" or filepath:match("^%[.+%]$") then
		return recipe_cmd
	end

	-- use the same placeholder substitution logic from filetype module
	local filetype = require("cook.filetype")
	local resolved_cmd = filetype.substitute_placeholders(recipe_cmd, filepath)

	return resolved_cmd or recipe_cmd
end

return M
