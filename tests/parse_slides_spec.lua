local parse = require "present"._parse_slides
describe("present.parse_slides", function()
	it("should parse an empty file", function()
		assert.are.same({
			slides = {
				{
					title = "",
					body = {},
				}
			}
		}, parse {})
	end)
	it("should parse a file with one slide", function()
		assert.are.same({
			slides = {
				{
					title = "#This is the first slide",
					body = { "this is the body" },
					blocks = {}
				}
			}
		}, parse {
			"#This is the first slide",
			"this is the body"
		})
	end)
	it("should parse a file with no headers", function()
		assert.are.same({
			slides = {
				{
					title = "",
					body = { "This is the first slide", "this is the body" },
				}
			}
		}, parse {
			"This is the first slide",
			"this is the body"
		})
	end)
	it("should parse a file with two headers", function()
		assert.are.same({
			slides = {
				{
					title = "#This is the first slide",
					body = { "this is the first body" },
					blocks = {}
				},
				{
					title = "#This is the second slide",
					body = { "this is the second body" },
					blocks = {}
				}
			}
		}, parse {
			"#This is the first slide",
			"this is the first body",
			"#This is the second slide",
			"this is the second body"
		})
	end)
	it("should parse a file with one slide and block", function()
		local result = parse {
			"#This is the first slide",
			"this is the body",
			"```lua",
			"print('hi')",
			"```"
		}

		assert.are.same(1, #result.slides)

		local slide = result.slides[1]

		assert.are.same("#This is the first slide", slide.title)
		assert.are.same({ "this is the body",
			"```lua",
			"print('hi')",
			"```" }, slide.body)

		local block = vim.trim [[
```lua
print('hi')
```]]
		assert.are.same(block, slide.blocks[1])
	end)
end)
