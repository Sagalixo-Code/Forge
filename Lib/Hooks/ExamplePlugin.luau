return {
	Name = "Logger",

	onStageStart = function(stage)
		print("Starting", stage)
	end,

	onStageComplete = function(stage, result)
		print("Finished", stage)
	end,

	stageMiddleware = function(stage, next, ...)
		print("Before", stage)

		local result = next(stage, ...)

		print("After", stage)

		return result
	end,
}
