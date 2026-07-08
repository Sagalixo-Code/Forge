--!strict

local Players = game:GetService("Players")

local Result = require(script.Parent.Result)

local pcall = pcall
local warn = warn
local tostring = tostring

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

local INIT_STAGES: { Stage } = {
	"PreInit",
	"Init",
	"PostInit",
}

local Runtime = {}
Runtime.__index = Runtime

export type Runtime = {
	_registry: Registry,
	_components: Components,
	_characterConnections: CharacterConnections,
}

function Runtime.new(registry: Registry, components: Components): Runtime
	return setmetatable({
		_registry = registry,
		_components = components,
		_characterConnections = {} :: CharacterConnections,
	}, Runtime) :: any
end

local function runStageSync(self: Runtime, stage: Stage, ...: any)
	local callbacks = self._registry:getStageCallbacks(stage)
	local errors: { string } = {}
	local ran = 0

	for i = 1, #callbacks do
		local callback = callbacks[i]

		local ok, err = pcall(callback, ...)
		if ok then
			ran += 1
		else
			errors[#errors + 1] = `[{stage}] {tostring(err)}`
		end
	end

	if #errors > 0 then
		return Result.err(errors)
	end

	return Result.ok(ran)
end

local function runStageAsync(self: Runtime, stage: Stage, ...: any)
	local callbacks = self._registry:getStageCallbacks(stage)
	local args = { ... }

	for i = 1, #callbacks do
		local callback = callbacks[i]

		task.spawn(function()
			local ok, err = pcall(callback, table.unpack(args))
			if not ok then
				warn(`[Forge] Erro em {stage}: {tostring(err)}`)
			end
		end)
	end
end

function Runtime:run(stage: Stage, async: boolean, ...: any)
	if async then
		runStageAsync(self, stage, ...)
		return Result.ok(true)
	end

	return runStageSync(self, stage, ...)
end

function Runtime:init()
	local allErrors: { string } = {}

	for _, stage in INIT_STAGES do
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
