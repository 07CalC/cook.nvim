-- this module extracts the file extension from a given filepath and resolves it to a runner command
-- based on the configuration options defined in cook.config

local config = require("cook.config")
local M = {}

-- substitutes placeholders in a runner command with actual file path components
-- rupports both new named placeholders {file}, {name}, etc. and legacy %s syntax
-- @param runner string: the runner command template with placeholders
-- @param filepath string: the full path to the file
-- @return string|nil: the command with substituted placeholders, or nil on error
-- @return string|nil: error message if substitution failed
--
-- available placeholders:
--   {file}     - full file path (e.g. /home/calc/projects/something/main.rs)
--   {filename} - filename with extension (e.g. main.rs)
--   {name}     - filename without extension (e.g. main)
--   {dir}      - directory path (e.g. /home/calc/projects/something)
--   {ext}      - file extension (e.g. rs)
--   {exe}      - hull executable path (dir + name) (e.g. /home/calc/projects/something/main)
--
-- legacy %s syntax
--   single %s  - seplaced with {file}
--   triple %s  - seplaced with {file}, {exe}, {exe} for C/Cpp compile and execution
function M.substitute_placeholders(runner, filepath)
	-- extract all file path components
	local components = {
		file = filepath,
		dir = vim.fn.fnamemodify(filepath, ":h"),
		filename = vim.fn.fnamemodify(filepath, ":t"),
		name = vim.fn.fnamemodify(filepath, ":t:r"),
		ext = filepath:match("^.+%.([%w]+)$") or "",
	}
	components.exe = components.dir .. "/" .. components.name

	-- check if using new named placeholder syntax
	if runner:match("{%w+}") then
		-- replace all named placeholders
		local result = runner:gsub("{(%w+)}", function(key)
			if components[key] then
				return components[key]
			else
				-- unknown placeholder - leave as is and warn
				vim.notify(
					string.format("Cook: Unknown placeholder '{%s}' in runner command", key),
					vim.log.levels.WARN
				)
				return "{" .. key .. "}"
			end
		end)
		return result
	elseif runner:match("%%s") then
		-- legacy %s syntax
		local _, count = runner:gsub("%%s", "")

		if count == 1 then
			-- single %s - replace with file path
			return string.format(runner, components.file)
		elseif count == 3 then
			-- triple %s - legacy c/cpp style: file, exe, exe
			return string.format(runner, components.file, components.exe, components.exe)
		else
			-- unsupported number of %s placeholders
			return nil, string.format("Legacy %%s syntax supports 1 or 3 placeholders, found %d", count)
		end
	else
		-- no placeholders found - return as is (e.g., "cargo run")
		return runner
	end
end

-- this function resolves a given filepath to a command based on its file extension.
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

	-- substitute placeholders in the runner command
	local cmd, err = M.substitute_placeholders(runner, filepath)
	if not cmd then
		vim.notify("Cook error: " .. (err or "Failed to substitute placeholders"), vim.log.levels.ERROR)
		return nil
	end

	return cmd
end

return M
