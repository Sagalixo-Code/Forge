--!strict
--!optimize 2

local Players = game:GetService("Players")

local Flags = require(script.Parent.Flags)
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

type Callback = (...any) -> ()

type Registry = {
	getStageCallbacks: (self: Registry, stage: Stage) -> { Callback },
}

type Components = {
	[string]: any,
}

type CharacterConnections = {
	[Player]: RBXScriptConnection,
}

type PluginManager = {
	dispatch: (self: PluginManager, hookName: string, ...any) -> (),
	hasStageMiddleware: (self: PluginManager) -> boolean,
	wrapStage: (self: PluginManager, stage: string, finalFn: (string, ...any) -> any, ...any) -> any,
}

local START_STAGES: { Stage } = {
	"PreInit",
	"Init",
	"PostInit",
}

local Runtime = {}
Runtime.__index = Runtime

function Runtime.new(registry: Registry, components: Components, plugins: PluginManager?)
	return setmetatable({
		_registry = registry,
		_components = components,
		_characterConnections = {} :: CharacterConnections,
		_plugins = plugins,
	}, Runtime)
end

export type Runtime = typeof(Runtime.new({} :: Registry, {} :: Components, nil :: PluginManager?))

local function runStageSync(runtime: Runtime, stage: Stage, ...: any)
	local callbacks = runtime._registry:getStageCallbacks(stage)
	local total = #callbacks

	if total == 0 then
		return Result.ok(0)
	end

	local errors: { string }? = nil
	local ran = 0

	for i = 1, total do
		local ok, err = pcall(callbacks[i], ...)

		if ok then
			ran += 1
		else
			if not errors then
				errors = {}
			end

			local list = errors :: { string }
			list[#list + 1] = `[{stage}] {tostring(err)}`
		end
	end

	if errors then
		return Result.err(errors)
	end

	return Result.ok(ran)
end

local function runStageAsync(runtime: Runtime, stage: Stage, ...: any)
	local callbacks = runtime._registry:getStageCallbacks(stage)
	local total = #callbacks

	if total == 0 then
		return
	end

	local n = select("#", ...)

	if n == 0 then
		for i = 1, total do
			local callback = callbacks[i]

			task.spawn(function()
				local ok, err = pcall(callback)
				if not ok then
					warn(`[Forge] Erro em {stage}: {tostring(err)}`)
				end
			end)
		end

		return
	end

	local args = table.pack(...)

	for i = 1, total do
		local callback = callbacks[i]

		task.spawn(function()
			local ok, err = pcall(callback, table.unpack(args, 1, args.n))
			if not ok then
				warn(`[Forge] Erro em {stage}: {tostring(err)}`)
			end
		end)
	end
end

function Runtime:run(stage: Stage, async: boolean, ...: any)
	assert(Flags.ByName[stage] ~= nil, `[Forge] Unknown lifecycle stage '{stage}'`)

	local plugins = self._plugins

	if plugins then
		plugins:dispatch("onStageStart", stage)
	end

	local result

	if plugins and plugins:hasStageMiddleware() then
		local function execute(innerStage: Stage, ...: any)
			if async then
				runStageAsync(self, innerStage, ...)
				return Result.ok(true)
			end
			return runStageSync(self, innerStage, ...)
		end

		local ok, res = pcall(plugins.wrapStage, plugins, stage, execute, ...)

		if ok then
			result = res
		else
			warn(`[Forge] stageMiddleware chain errored for '{stage}': {tostring(res)}`)
			result = execute(stage, ...)
		end
	elseif async then
		runStageAsync(self, stage, ...)
		result = Result.ok(true)
	else
		result = runStageSync(self, stage, ...)
	end

	if plugins then
		plugins:dispatch("onStageComplete", stage, result)
	end

	return result
end

function Runtime:init()
	local allErrors: { string } = {}

	for _, stage in START_STAGES do
		local result = self:run(stage, false)

		if result:isErr() then
			for _, err in result:unwrapOr({}) do
				allErrors[#allErrors + 1] = err
			end
		end
	end

	if #allErrors > 0 then
		return Result.err(allErrors)
	end

	return Result.ok(true)
end

function Runtime:start()
	local errors: { string } = {}

	local preResult = self:run("PreStart", false)
	if preResult:isErr() then
		errors = preResult:unwrapOr({})
	end

	self:run("Start", true, self._components)

	local postResult = self:run("PostStart", false)
	if postResult:isErr() then
		for _, err in postResult:unwrapOr({}) do
			errors[#errors + 1] = err
		end
	end

	if #errors > 0 then
		return Result.err(errors)
	end

	return Result.ok(true)
end

function Runtime:shutdown()
	return self:run("Shutdown", false)
end

function Runtime:bindPlayerLifecycle()
	Players.PlayerAdded:Connect(function(player: Player)
		self:run("PlayerAdded", true, player, self._components)

		self._characterConnections[player] = player.CharacterAdded:Connect(function(character: Model)
			self:run("CharacterAdded", true, player, character, self._components)
		end)

		player.CharacterRemoving:Connect(function(character: Model)
			self:run("CharacterRemoving", true, player, character, self._components)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self:run("PlayerRemoving", true, player, self._components)

		local connection = self._characterConnections[player]
		if connection then
			connection:Disconnect()
			self._characterConnections[player] = nil
		end
	end)
end

return Runtime
