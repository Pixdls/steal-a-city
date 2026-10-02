--!strict
-- Tiny signal that passes arguments by reference. BindableEvents deep-copy
-- tables, which breaks identity checks on carry records and object handles.
local Signal = {}
Signal.__index = Signal

export type Connection = { Disconnect: () -> () }

function Signal.new()
	return setmetatable({ _handlers = {} :: { any } }, Signal)
end

function Signal.Connect(self: any, fn: (...any) -> ()): Connection
	local handler = { fn = fn }
	table.insert(self._handlers, handler)
	return {
		Disconnect = function()
			local i = table.find(self._handlers, handler)
			if i then
				table.remove(self._handlers, i)
			end
		end,
	}
end

function Signal.Fire(self: any, ...: any)
	for _, handler in table.clone(self._handlers) do
		task.spawn(handler.fn, ...)
	end
end

return Signal
