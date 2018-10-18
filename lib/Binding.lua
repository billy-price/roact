local Symbol = require(script.Parent.Symbol)
local Type = require(script.Parent.Type)

local createSignal = require(script.Parent.createSignal)

local Internal = {
	changeSignal = Symbol.named("changeSignal"),
	value = Symbol.named("value"),

	update = Symbol.named("update"),
	subscribe = Symbol.named("subscribe"),
}

local bindingMetatable = {
	__tostring = function(self)
		return ("RoactBinding(%s)"):format(tostring(self[Internal.value]))
	end
}

local Binding = {}

function Binding.create(initialValue)
	local binding = Binding.createFromSource(initialValue, function(value)
		return value
	end)

	local updater = function(newValue)
		binding[Internal.update](binding, newValue)
	end

	return binding, updater
end

function Binding.createFromSource(source, mapFunc)
	local initialValue = source
	if Type.of(source) == Type.Binding then
		initialValue = source:getValue()
	end

	local subCount = 0
	local disconnectSource = nil

	local binding = {
		[Type] = Type.Binding,

		[Internal.value] = mapFunc(initialValue),
		[Internal.changeSignal] = createSignal(),
	}

	binding[Internal.update] = function(self, newValue)
		newValue = mapFunc(newValue)

		self[Internal.value] = newValue
		self[Internal.changeSignal]:fire(newValue)
	end

	binding[Internal.subscribe] = function(self, handler)
		if Type.of(source) == Type.Binding and subCount == 0 then
			disconnectSource = source[Internal.subscribe](source, function(value)
				self[Internal.update](self, value)
			end)
		end

		local disconnect = self[Internal.changeSignal]:subscribe(handler)
		subCount = subCount + 1

		return function()
			disconnect()
			subCount = subCount - 1

			if subCount == 0 and disconnectSource ~= nil then
				disconnectSource()
				disconnectSource = nil
			end
		end
	end

	function binding:getValue()
		--[[
			If our source is another binding but we're not subscribed, we'll
			manually update ourselves before returning a value.

			This allows us to avoid subscribing to our source until someone
			has subscribed to us, and avoid creating dangling connections
		]]
		if Type.of(source) == Type.Binding and disconnectSource == nil then
			self[Internal.update](self, source:getValue())
		end

		return self[Internal.value]
	end

	function binding:map(newMapFunc)
		return Binding.createFromSource(self, newMapFunc)
	end

	setmetatable(binding, bindingMetatable)

	return binding
end

function Binding.update(binding, newValue)
	return binding[Internal.update](binding, newValue)
end

function Binding.subscribe(binding, handler)
	return binding[Internal.subscribe](binding, handler)
end

return Binding