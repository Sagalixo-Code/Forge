--!strict
local Logger = {}
Logger.__index = Logger

export type LogLevel = number

Logger.Levels = {
	TRACE = 1,
	DEBUG = 2,
	INFO = 3,
	WARN = 4,
	ERROR = 5,
	NONE = 6,
}

type LoggerImpl = {
	Tag: string,
	MinLevel: LogLevel,
	SetLevel: (self: LoggerImpl, level: LogLevel) -> (),
	Trace: (self: LoggerImpl, ...any) -> (),
	Debug: (self: LoggerImpl, ...any) -> (),
	Info: (self: LoggerImpl, ...any) -> (),
	Warn: (self: LoggerImpl, ...any) -> (),
	Error: (self: LoggerImpl, ...any) -> (),
	Fatal: (self: LoggerImpl, ...any) -> (),
}

export type Logger = LoggerImpl

local GLOBAL_MIN_LEVEL: LogLevel = Logger.Levels.INFO
local HttpService = game:GetService("HttpService")

local COLORS = {
	TRACE = "🙍‍♂️",
	DEBUG = "💻",
	INFO = "💡",
	WARN = "⚠️",
	ERROR = "❌",
	FATAL = "🚨",
}

function Logger.new(tag: string?): Logger
	local self = setmetatable({}, Logger)
	self.Tag = tag or "System"
	self.MinLevel = GLOBAL_MIN_LEVEL
	return (self :: any) :: Logger
end

function Logger:SetLevel(level: LogLevel)
	self.MinLevel = level
end

function Logger.SetGlobalLevel(level: LogLevel)
	GLOBAL_MIN_LEVEL = level
end

local function serialize(value: any): string
	local t = type(value)
	if t == "table" then
		local success, result = pcall(function()
			return HttpService:JSONEncode(value)
		end)
		return success and result or tostring(value)
	elseif t == "userdata" or t == "vector" then
		return string.format("%s (%s)", tostring(value), typeof(value))
	end
	return tostring(value)
end

local function formatMessage(tag: string, levelName: string, ...: any): string
	local args = table.pack(...)
	local segments = table.create(args.n)

	for i = 1, args.n do
		segments[i] = serialize(args[i])
	end

	local message = table.concat(segments, " ")
	local timestamp = os.date("%H:%M:%S")
	local icon = COLORS[levelName] or ""

	return string.format("[%s] %s [%s] [%s]: %s", timestamp, icon, levelName, tag, message)
end

function Logger:Trace(...: any)
	if self.MinLevel > Logger.Levels.TRACE then
		return
	end
	print(formatMessage(self.Tag, "TRACE", ...))
end

function Logger:Debug(...: any)
	if self.MinLevel > Logger.Levels.DEBUG then
		return
	end
	print(formatMessage(self.Tag, "DEBUG", ...))
end

function Logger:Info(...: any)
	if self.MinLevel > Logger.Levels.INFO then
		return
	end
	print(formatMessage(self.Tag, "INFO", ...))
end

function Logger:Warn(...: any)
	if self.MinLevel > Logger.Levels.WARN then
		return
	end
	warn(formatMessage(self.Tag, "WARN", ...))
end

function Logger:Error(...: any)
	if self.MinLevel > Logger.Levels.ERROR then
		return
	end
	warn(formatMessage(self.Tag, "ERROR", ...))
end

function Logger:Fatal(...: any)
	local msg = formatMessage(self.Tag, "FATAL", ...)
	error(msg, 2)
end

return Logger
