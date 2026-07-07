local Runtime = require(script.Parent.Runtime)

return function()
	describe("Runtime", function()
		beforeEach(function()
			table.clear(Runtime._stack)
		end)

		it("starts with an empty stack", function()
			expect(Runtime:isRunning()).to.equal(false)
			expect(Runtime:depth()).to.equal(0)
			expect(Runtime:current()).to.equal(nil)
		end)

		it("pushes a frame", function()
			local node = {}

			local frame = Runtime:push(node)

			expect(Runtime:isRunning()).to.equal(true)
			expect(Runtime:depth()).to.equal(1)
			expect(Runtime:current()).to.equal(frame)
			expect(frame.node).to.equal(node)
		end)

		it("pops a frame", function()
			local node = {}

			local frame = Runtime:push(node)
			local popped = Runtime:pop()

			expect(popped).to.equal(frame)
			expect(Runtime:isRunning()).to.equal(false)
			expect(Runtime:current()).to.equal(nil)
		end)

		it("returns nil when popping an empty stack", function()
			expect(Runtime:pop()).to.equal(nil)
		end)

		it("tracks nested frames", function()
			local a = Runtime:push({})
			local b = Runtime:push({})

			expect(b.parent).to.equal(a)
			expect(b.depth).to.equal(2)

			Runtime:pop()
			Runtime:pop()
		end)

		it("increments hook index", function()
			Runtime:push({})

			expect(Runtime:nextHookIndex()).to.equal(1)
			expect(Runtime:nextHookIndex()).to.equal(2)
			expect(Runtime:nextHookIndex()).to.equal(3)

			Runtime:pop()
		end)

		it("markAccess stores accessed keys", function()
			Runtime:push({})

			Runtime:markAccess("Base", "A")
			Runtime:markAccess("Base", "B")

			local frame = Runtime:current()

			expect(frame.accessedKeys.Base.A).to.equal(true)
			expect(frame.accessedKeys.Base.B).to.equal(true)

			Runtime:pop()
		end)

		it("creates hookStorage automatically", function()
			local node = {}

			Runtime:push(node)

			expect(node.hookStorage).never.to.equal(nil)

			Runtime:pop()
		end)

		it("cleanup removes unaccessed storage", function()
			local node = {
				hookStorage = {
					Test = {
						storage = {
							a = {},
							b = {},
						},
					},
				},
			}

			local frame = Runtime:push(node)

			Runtime:markAccess("Test", "a")

			Runtime:cleanup(frame)

			expect(node.hookStorage.Test.storage.a).never.to.equal(nil)
			expect(node.hookStorage.Test.storage.b).to.equal(nil)

			Runtime:pop()
		end)

		it("cleanup respects cleanup callback", function()
			local node = {
				hookStorage = {
					Test = {
						storage = {
							a = {},
						},

						cleanupCallback = function()
							return true
						end,
					},
				},
			}

			local frame = Runtime:push(node)

			Runtime:cleanup(frame)

			expect(node.hookStorage.Test.storage.a).never.to.equal(nil)

			Runtime:pop()
		end)

		it("cleanup removes storage when callback returns false", function()
			local node = {
				hookStorage = {
					Test = {
						storage = {
							a = {},
						},

						cleanupCallback = function()
							return false
						end,
					},
				},
			}

			local frame = Runtime:push(node)

			Runtime:cleanup(frame)

			expect(node.hookStorage.Test.storage.a).to.equal(nil)

			Runtime:pop()
		end)

		it("start pushes and pops automatically", function()
			expect(Runtime:isRunning()).to.equal(false)

			Runtime:start({}, function()
				expect(Runtime:isRunning()).to.equal(true)
				expect(Runtime:depth()).to.equal(1)
			end)

			expect(Runtime:isRunning()).to.equal(false)
			expect(Runtime:depth()).to.equal(0)
		end)

		it("start returns the frame", function()
			local frame = Runtime:start({}, function() end)

			expect(frame).never.to.equal(nil)
			expect(frame.depth).to.equal(1)
		end)

		it("rethrows errors", function()
			expect(function()
				Runtime:start({}, function()
					error("Boom")
				end)
			end).to.throw()
		end)
	end)
end
