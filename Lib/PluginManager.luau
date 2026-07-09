--!strict
--!optimize 2

local Result = require(script.Parent.Result)

export type Stage =
	"PreInit"
	| "Init"
	| "PostInit"
	| "PreStart"
	| "Start"
	| "PostStart"
	| "Shutdown"
	| "PlayerAdded"
	| "PlayerRemoving"
	| "CharacterAdded"
	| "CharacterRemoving"

export type PluginHook =
	"onRegister"
	| "onInit"
	| "onStart"
	| "onShutdown"
	| "onStageStart"
	| "onStageComplete"
	| "onError"
	| "onModuleRejected"

export type Middleware = (
	stage: Stage,
	next: (stage: Stage, ...any) -> Result.Result<any, string>,
	...any
) -> Result.Result<any, string>

export type Plugin = {

	Name: string,

	Hooks: {
		[string]: ((...any) -> ())?,
	},

	Middleware: Middleware?,
}

local PluginManager = {}
PluginManager.__index = PluginManager

function PluginManager.new()
	return setmetatable({

		_plugins = {},

		_hooks = {},

		_middlewares = {},
	}, PluginManager)
end

export type PluginManager = typeof(PluginManager.new())

function PluginManager:Register(plugin: Plugin): Result.Result<Plugin, string>
	if self._plugins[plugin.Name] then
		return Result.err("Plugin already registered: " .. plugin.Name)
	end

	self._plugins[plugin.Name] = plugin

	if plugin.Middleware then
		self._middlewares[#self._middlewares + 1] = plugin.Middleware
	end

	for hook, callback in plugin.Hooks do
		if callback then
			local hooks = self._hooks[hook]

			if not hooks then
				hooks = {}

				self._hooks[hook] = hooks
			end

			hooks[#hooks + 1] = callback
		end
	end

	local registerHook = plugin.Hooks.onRegister

	if registerHook then
		local success, err = pcall(registerHook)

		if not success then
			return Result.err("Plugin register failed: " .. tostring(err))
		end
	end

	return Result.ok(plugin)
end

function PluginManager:dispatch(hook: PluginHook, ...: any): Result.Result<number, string>
	local callbacks = self._hooks[hook]

	if not callbacks then
		return Result.ok(0)
	end

	local executed = 0

	for _, callback in callbacks do
		local success, err = pcall(callback, ...)

		if not success then
			return Result.err("Plugin hook '" .. hook .. "' failed: " .. tostring(err))
		end

		executed += 1
	end

	return Result.ok(executed)
end

function PluginManager:hasStageMiddleware(): boolean
	return #self._middlewares > 0
end

function PluginManager:wrapStage(
	stage: Stage,
	callback: (stage: Stage, ...any) -> Result.Result<any, string>,
	...: any
): Result.Result<any, string>
	local function execute(index: number, currentStage: Stage, ...: any): Result.Result<any, string>
		local middleware = self._middlewares[index]

		if middleware then
			return middleware(currentStage, function(nextStage: Stage, nextArgs: any)
				return execute(index + 1, nextStage, nextArgs)
			end, ...)
		end

		return callback(currentStage, ...)
	end

	return execute(1, stage, ...)
end

return PluginManager
