-- this module defines commands for the plugin

local recipes = require("cook.recipes")
local executor = require("cook.executor")
local filetype = require("cook.filetype")

local M = {}

-- this allows users to run tasks defined in recipes.lua or execute commands based on the current file
-- @param args table: Arguments passed to the command
-- args only required if a user defined per-project task is to be executed
-- example:
-- M.cook({args = "my_task"})
function M.cook(args)
	local recipes_list = recipes.load_recipes()
	local raw = vim.api.nvim_buf_get_name(0)
	if not raw or raw == "" or raw:match("^%[.+%]$") and not recipes_list then
		vim.notify("Cannot cook unsaved or unnamed buffer.", vim.log.levels.ERROR)
		return
	end

	if args.args and args.args ~= "" and recipes_list then
		local task = recipes_list[args.args]
		if not task then
			vim.notify("Recipe '" .. args.args .. "' not found.", vim.log.levels.ERROR)
			return
		end
		-- resolve recipe with placeholder substitution
		local resolved_task = recipes.resolve_recipe(task, raw)
		executor.run(resolved_task)
		return
	end

	if recipes_list then
		local recipe_items = {}

		for key, cmd in pairs(recipes_list) do
			table.insert(recipe_items, {
				label = string.format("%-10s → %s", key, cmd),
				cmd = cmd,
			})
		end

		table.sort(recipe_items, function(a, b)
			return a.label < b.label
		end)

		vim.ui.select(recipe_items, {
			prompt = "Cook recipe:",
			format_item = function(item)
				return item.label
			end,
		}, function(choice)
			if choice then
				-- Resolve recipe with placeholder substitution
				local resolved_cmd = recipes.resolve_recipe(choice.cmd, raw)
				executor.run(resolved_cmd)
			else
				vim.notify("No recipe selected.", vim.log.levels.INFO)
			end
		end)

		return
	end

	local cmd = filetype.resolve(raw)
	if not cmd then
		return
	end

	executor.run(cmd)
end

-- this allows users to run the current file with clipboard as input, helpful for CP
function M.Coop()
	local raw = vim.api.nvim_buf_get_name(0)

	if not raw or raw == "" or raw:match("^%[.+%]$") then
		vim.notify("Cannot cook unsaved or unnamed buffer.", vim.log.levels.ERROR)
		return
	end
	local exec_cmd = filetype.resolve(raw)
	if not exec_cmd then
		return
	end
	local input = vim.fn.getreg("+")
	if not input or input == "" then
		vim.notify("No input provided in the clipboard", vim.log.levels.ERROR)
		return
	end
	local tmp_file = vim.fn.tempname() .. ".in"
	local file = io.open(tmp_file, "w")
	if not file then
		vim.notify("Could not create temporary file for input", vim.log.levels.ERROR)
		return
	end
	file:write(input)
	file:close()
	local cmd = exec_cmd .. " < " .. tmp_file
	executor.run(cmd)
end

return M
