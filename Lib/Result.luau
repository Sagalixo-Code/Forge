--!strict
local Result = {}
Result.__index = Result

export type Result<T, E> = typeof(setmetatable({} :: { _ok: boolean, _value: T, _error: E }, Result))

function Result.ok<T>(value: T): Result<T, any>
	return setmetatable({ _ok = true, _value = value }, Result) :: any
end

function Result.err<E>(err: E): Result<any, E>
	return setmetatable({ _ok = false, _error = err }, Result) :: any
end

function Result:isOk(): boolean
	return self._ok
end

function Result:isErr(): boolean
	return not self._ok
end

function Result:unwrap()
	if not self._ok then
		error(`called unwrap() on an Err value: {tostring(self._error)}`, 2)
	end
	return self._value
end

function Result:unwrapOr(default: any)
	if self._ok then
		return self._value
	end
	return default
end

function Result:unwrapOrElse(fn: (any) -> any)
	if self._ok then
		return self._value
	end
	return fn(self._error)
end

function Result:expect(message: string)
	if not self._ok then
		error(`{message}: {tostring(self._error)}`, 2)
	end
	return self._value
end

function Result:map(fn: (any) -> any)
	if self._ok then
		return Result.ok(fn(self._value))
	end
	return self
end

function Result:mapErr(fn: (any) -> any)
	if not self._ok then
		return Result.err(fn(self._error))
	end
	return self
end

function Result:andThen(fn: (any) -> any)
	if self._ok then
		return fn(self._value)
	end
	return self
end

function Result:match(onOk: (any) -> any, onErr: (any) -> any)
	if self._ok then
		return onOk(self._value)
	end
	return onErr(self._error)
end

return Result
