local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Result = require(ReplicatedStorage.Lib.Result)

return function()
	describe("Result", function()
		it("creates an Ok result", function()
			local result = Result.ok(10)

			expect(result:isOk()).to.equal(true)
			expect(result:isErr()).to.equal(false)
		end)

		it("creates an Err result", function()
			local result = Result.err("error")

			expect(result:isOk()).to.equal(false)
			expect(result:isErr()).to.equal(true)
		end)

		it("unwraps Ok values", function()
			local result = Result.ok("hello")

			expect(result:unwrap()).to.equal("hello")
		end)

		it("throws when unwrapping Err", function()
			local result = Result.err("boom")

			expect(function()
				result:unwrap()
			end).to.throw()
		end)

		it("unwrapOr returns the value for Ok", function()
			local result = Result.ok(123)

			expect(result:unwrapOr(999)).to.equal(123)
		end)

		it("unwrapOr returns the default for Err", function()
			local result = Result.err("oops")

			expect(result:unwrapOr(999)).to.equal(999)
		end)

		it("unwrapOrElse returns the value for Ok", function()
			local result = Result.ok(5)

			expect(result:unwrapOrElse(function()
				return 99
			end)).to.equal(5)
		end)

		it("unwrapOrElse computes a default for Err", function()
			local result = Result.err("abc")

			local value = result:unwrapOrElse(function(err)
				return #err
			end)

			expect(value).to.equal(3)
		end)

		it("expect returns the value for Ok", function()
			local result = Result.ok(42)

			expect(result:expect("failed")).to.equal(42)
		end)

		it("expect throws for Err", function()
			local result = Result.err("boom")

			expect(function()
				result:expect("Custom error")
			end).to.throw()
		end)

		it("maps Ok values", function()
			local result = Result.ok(10):map(function(value)
				return value * 2
			end)

			expect(result:unwrap()).to.equal(20)
		end)

		it("does not map Err values", function()
			local result = Result.err("boom"):map(function()
				return 0
			end)

			expect(result:isErr()).to.equal(true)
		end)

		it("maps Err values", function()
			local result = Result.err("boom"):mapErr(function(err)
				return err .. "!"
			end)

			expect(result:unwrapOr("default")).to.equal("default")
		end)

		it("does not mapErr Ok values", function()
			local result = Result.ok(7):mapErr(function()
				return "error"
			end)

			expect(result:unwrap()).to.equal(7)
		end)

		it("chains Ok values with andThen", function()
			local result = Result.ok(10):andThen(function(value)
				return Result.ok(value + 5)
			end)

			expect(result:unwrap()).to.equal(15)
		end)

		it("does not call andThen on Err", function()
			local called = false

			local result = Result.err("boom"):andThen(function()
				called = true
				return Result.ok(0)
			end)

			expect(called).to.equal(false)
			expect(result:isErr()).to.equal(true)
		end)

		it("matches Ok", function()
			local value = Result.ok(5):match(function(v)
				return v * 2
			end, function()
				return 0
			end)

			expect(value).to.equal(10)
		end)

		it("matches Err", function()
			local value = Result.err("boom"):match(function()
				return 0
			end, function(err)
				return err
			end)

			expect(value).to.equal("boom")
		end)
	end)
end
