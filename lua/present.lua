local M = {}

M.setup = function()
	--nothing
end

local function OpenCenteredFloat(opts)
	opts = opts or {}
	-- Defaults
	percent_width = opts.percent_width or 0.8
	percent_height = opts.percent_height or 0.8

	local columns = vim.o.columns
	local lines = vim.o.lines

	-- Calculate size
	local width = math.floor(columns * percent_width)
	local height = math.floor(lines * percent_height)

	-- Calculate position
	local col = columns - width - 5
	local row = math.floor((lines - height) / 2 - 1) -- subtract 1 to account for cmd height

	-- Create a new scratch buffer
	local buf = vim.api.nvim_create_buf(false, true)


	-- Open floating window
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded"
	})

	return { buf = buf, win = win }
end

---@class present.Slides
---@field slides string[]: The slides of the file


--- Takes some lines and parses them
---@param lines string[]: The lines in buffer
---@return present.Slides
local parse_slides = function(lines)
	local slides = { slides = {} }
	local current_slide = {}
	local separator = "^#"
	for _, line in ipairs(lines) do
		if line:find(separator) then
			if #current_slide > 0 then
				table.insert(slides.slides, current_slide)
			end
			current_slide = {}
		end
		table.insert(current_slide, line)
	end
	table.insert(slides.slides, current_slide)

	return slides
end

M.start_presentation = function(opts)
	opts = opts or {}
	opts.bufnr = opts.bufnr or 0
	-- n	
	local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
	local parsed = parse_slides(lines)
	local float = OpenCenteredFloat()
	local current_slide = 1
	vim.keymap.set("n", "n", function()
			current_slide = math.min(current_slide + 1, #parsed.slides)
			vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, parsed.slides[current_slide])
		end,
		{ buffer = float.buf })
	vim.keymap.set("n", "p", function()
			current_slide = math.max(current_slide - 1, 1)
			vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, parsed.slides[current_slide])
		end,
		{ buffer = float.buf })
	vim.keymap.set("n", "q", function()
			vim.api.nvim_win_close(float.win, true)
		end,
		{ buffer = float.buf })
	vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, parsed.slides[1])
end

M.start_presentation { bufnr = 11 }

-- vim.print(parse_slides {
-- 	"# Hello",
-- 	"another line",
-- 	"# Hola",
-- 	"buenas tardes"
-- })

return M
