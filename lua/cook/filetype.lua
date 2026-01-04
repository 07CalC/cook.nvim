-- this module extracts the file extension from a given filepath and resolves it to a runner command
-- based on the configuration options defined in cook.config

local config = require("cook.config")
local M = {}

-- This function resolves a given filepath to a command based on its file extension.
-- @param filepath string: The path to the file to be resolved.
-- example:
-- M.resolve("/home/calc/Documents/masti/test.c")
function M.resolve(filepath)
	if type(filepath) ~= "string" then
		vim.notify("Cook error: invalid filepath", vim.log.levels.ERROR)
		return nil
	end

	local ext = filepath:match("^.+%.([%w]+)$")
	if not ext then
		vim.notify("Could not determine extension for: " .. filepath, vim.log.levels.WARN)
		return nil
	end

	-- check if the extension is supported
	local runner = config.options.runners[ext]
	if type(runner) ~= "string" then
		vim.notify("No valid recipie for ." .. ext, vim.log.levels.WARN)
		return nil
	end

	if not runner:match("%s") then
		vim.notify("Recipie for ." .. ext .. " must contain '%s'", vim.log.levels.ERROR)
		return nil
	end

	-- If the extension is C or C++, we need to compile the file first
	-- The compiled executable will be placed in the same directory as the source file
	if ext == "c" or ext == "cpp" then
		local folder = vim.fn.fnamemodify(filepath, ":h")
		local name = vim.fn.fnamemodify(filepath, ":t:r")
		local exe = folder .. "/" .. name
		return string.format(runner, filepath, exe, exe)
	end

	return string.format(runner, filepath)
end

return M
