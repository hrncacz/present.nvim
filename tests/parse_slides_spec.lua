local parse = require "present"._parse_slides
describe("present.parse_slides", function()
	it("should parse an empty file", function()
		assert.are.same({
			slides = {
				{
					title = "",
					body = {}
				}
			}
		}, parse {})
	end)
	it("should parse a file with one slide", function()
		assert.are.same({
			slides = {
				{
					title = "#This is the first slide",
					body = { "this is the body" }
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
					body = { "This is the first slide", "this is the body" }
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
					body = { "this is the first body" }
				},
				{
					title = "#This is the second slide",
					body = { "this is the second body" }
				}
			}
		}, parse {
			"#This is the first slide",
			"this is the first body",
			"#This is the second slide",
			"this is the second body"
		})
	end)
end)
