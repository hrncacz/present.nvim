local M = {}

M.setup = function()
	--nothing
end

local function OpenCenteredFloat(config, enter)
	if enter == nil then
		enter = false
	end
	-- Create a new scratch buffer
	local buf = vim.api.nvim_create_buf(false, true)


	-- Open floating window
	local win = vim.api.nvim_open_win(buf, enter or false, config)

	return { buf = buf, win = win }
end

---@class present.Slide
---@field title string: The title of the slide
---@field body string[]: The body of slide
---
---@class present.Slides
---@field slides present.Slide[]: The slides of the file


--- Takes some lines and parses them
---@param lines string[]: The lines in buffer
---@return present.Slides
local parse_slides = function(lines)
	local slides = { slides = {} }
	local current_slide = { title = "", body = {} }
	local separator = "^#"
	for _, line in ipairs(lines) do
		if line:find(separator) then
			if #current_slide.title > 0 then
				table.insert(slides.slides, current_slide)
			end

			current_slide = {
				title = line,
				body = {}
			}
		else
			table.insert(current_slide.body, line)
		end
	end
	table.insert(slides.slides, current_slide)

	return slides
end

local create_window_configuration = function()
	local width = vim.o.columns
	local height = vim.o.lines
	local header_height = 1 + 2                                       -- 1 + border
	local footer_height = 1                                           -- 1 no border
	local body_height = height - header_height - footer_height - 2 - 2 -- 2 for border

	return {
		background = {
			relative = "editor",
			width = width,
			height = height,
			style = "minimal",
			col = 0,
			row = 0,
			zindex = 1
		},
		header = {
			relative = "editor",
			width = width,
			height = 1,
			style = "minimal",
			border = "rounded",
			col = 0,
			row = 0,
			zindex = 2
		},
		body = {
			relative = "editor",
			width = width - 8,
			height = body_height,
			style = "minimal",
			border = { " ", " ", " ", " ", " ", " ", " ", " ", },
			col = 8,
			row = 5,
		},
		footer = {
			relative = "editor",
			width = width,
			height = 1,
			style = "minimal",
			-- border = "rounded",
			col = 0,
			row = height - 1,
			zindex = 2
		}
	}
end

local state = {
	parsed = {},
	current_slide = 1,
	floats = {},
	title = "Kundus"
}

local foreach_float = function(cb)
	for name, float in pairs(state.floats) do
		cb(name, float)
	end
end



M.start_presentation = function(opts)
	opts = opts or {}
	opts.bufnr = opts.bufnr or 0
	-- n	
	local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
	state.parsed = parse_slides(lines)
	state.current_slide = 1
	state.title = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(opts.bufnr), ":t")

	local windows = create_window_configuration()
	state.floats.background = OpenCenteredFloat(windows.background)
	state.floats.header = OpenCenteredFloat(windows.header)
	state.floats.footer = OpenCenteredFloat(windows.footer)
	state.floats.body = OpenCenteredFloat(windows.body, true)

	foreach_float(function(_, float)
		vim.bo[float.buf].filetype = "markdown"
	end)


	local set_slide_content = function(idx)
		local width = vim.o.columns
		local slide = state.parsed.slides[idx]
		local padding = string.rep(" ", (width - #slide) / 2)
		local title = padding .. slide.title
		vim.api.nvim_buf_set_lines(state.floats.header.buf, 0, -1, false, { title })
		vim.api.nvim_buf_set_lines(state.floats.body.buf, 0, -1, false, slide.body)

		local footer = string.format(" %d / %d | %s ", state.current_slide, #state.parsed.slides, state.title)
		vim.api.nvim_buf_set_lines(state.floats.footer.buf, 0, -1, false, { footer })
	end

	vim.keymap.set("n", "n", function()
			state.current_slide = math.min(state.current_slide + 1, #state.parsed.slides)
			set_slide_content(state.current_slide)
		end,
		{ buffer = state.floats.body.buf })

	vim.keymap.set("n", "p", function()
			state.current_slide = math.max(state.current_slide - 1, 1)
			set_slide_content(state.current_slide)
		end,
		{ buffer = state.floats.body.buf })

	vim.keymap.set("n", "q", function()
			vim.api.nvim_win_close(state.floats.body.win, true)
		end,
		{ buffer = state.floats.body.buf })
	set_slide_content(state.current_slide)

	local restore = {
		cmdheight = {
			original = vim.o.cmdheight,
			present = 0
		}
	}

	--Set the options we want druring the presentation
	for option, config in pairs(restore) do
		vim.opt[option] = config.present
	end

	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = state.floats.body.buf,
		callback = function()
			-- Reset the values to default
			for option, config in pairs(restore) do
				vim.opt[option] = config.original
			end
			foreach_float(function(_, float)
				pcall(vim.api.nvim_win_close, float.win, true)
			end)
		end
	})

	vim.api.nvim_create_autocmd("VimResized", {
		group = vim.api.nvim_create_augroup("present-resized", {}),
		callback = function()
			if not vim.api.nvim_win_is_valid(state.floats.body.win) or state.floats.body.win == nil then
				return
			end
			local updated = create_window_configuration()
			foreach_float(function(name, _)
				vim.api.nvim_win_set_config(state.floats[name].win, updated[name])
			end)
			-- Recalculate slide contents
			set_slide_content(state.current_slide)
		end
	})
end

-- M.start_presentation { bufnr = 47 }

-- vim.print(parse_slides {
-- 	"# Hello",
-- 	"another line",
-- 	"# Hola",
-- 	"buenas tardes"
-- })
--
--
-- # Hello,
-- another line,
-- # Hola,
-- buenas tardes
-- # Soy Martin
-- y soy de Republica Checa.
-- Tengo hijo y hija
-- # Mi hijo llama Martin
-- # Mi hija llama Miriam
--
M._parse_slides = parse_slides

return M
