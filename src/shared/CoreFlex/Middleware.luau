--!strict
--!optimize 2

const Middleware = {}
Middleware.__index = Middleware

export type Context = {
	Player: Player?,
	Character: Model?,
	Action: string?,
	Cancelled: boolean?,
	[string]: any,
}

export type MiddlewareCallback = (Context, () -> ()) -> ()

export type MiddlewareObject = {
	_registry: {
		[string]: { MiddlewareCallback },
	},

	Register: (self: MiddlewareObject, ContextName: string, Callback: MiddlewareCallback) -> (),

	Execute: (self: MiddlewareObject, ContextName: string, Context) -> boolean,

	Clear: (self: MiddlewareObject, ContextName: string) -> (),
}

function Middleware.new(): MiddlewareObject
	local self = setmetatable({}, Middleware)

	self._registry = {}

	return self
end

function Middleware:Register(ContextName: string, Callback: MiddlewareCallback)
	local Registry = self._registry

	if not Registry[ContextName] then
		Registry[ContextName] = {}
	end

	table.insert(Registry[ContextName], Callback)
end

function Middleware:Execute(ContextName: string, Context): boolean
	local Stack = self._registry[ContextName]

	if not Stack then
		return true
	end

	local Index = 0

	local function Next()
		Index += 1

		local Current = Stack[Index]

		if Current then
			Current(Context, Next)
		end
	end

	Next()

	return Context.Cancelled ~= true
end

function Middleware:Clear(ContextName: string)
	self._registry[ContextName] = nil
end

return Middleware
