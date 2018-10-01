return function()
	local createElement = require(script.Parent.Parent.createElement)
	local createReconciler = require(script.Parent.Parent.createReconciler)
	local createSpy = require(script.Parent.Parent.createSpy)
	local NoopRenderer = require(script.Parent.Parent.NoopRenderer)
	local Type = require(script.Parent.Parent.Type)

	local Component = require(script.Parent.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	it("should throw on mount if not overridden", function()
		local MyComponent = Component:extend("MyComponent")

		local element = createElement(MyComponent)
		local hostParent = nil
		local key = "Test"

		local success, result = pcall(function()
			noopReconciler.mountNode(element, hostParent, key)
		end)

		expect(success).to.equal(false)
		expect(result:match("MyComponent")).to.be.ok()
		expect(result:match("render")).to.be.ok()
	end)

	it("should be invoked when a component is mounted", function()
		local Foo = Component:extend("Foo")

		local renderSpy = createSpy()
		Foo.render = renderSpy.value

		local element = createElement(Foo)
		local hostParent = nil
		local key = "Foo Test"

		noopReconciler.mountNode(element, hostParent, key)

		expect(renderSpy.callCount).to.equal(1)

		local renderArguments = renderSpy:captureValues("self")

		expect(Type.of(renderArguments.self)).to.equal(Type.StatefulComponentInstance)
	end)

	it("should be invoked when a component is updated via props", function()
		local Foo = Component:extend("Foo")

		local renderSpy = createSpy()
		Foo.render = renderSpy.value

		local element = createElement(Foo)
		local hostParent = nil
		local key = "Foo Test"

		local node = noopReconciler.mountNode(element, hostParent, key)

		expect(renderSpy.callCount).to.equal(1)

		local newElement = createElement(Foo)

		noopReconciler.updateNode(node, newElement)

		expect(renderSpy.callCount).to.equal(2)

		local renderArguments = renderSpy:captureValues("self")
		expect(Type.of(renderArguments.self)).to.equal(Type.StatefulComponentInstance)
	end)

	it("should be invoked when a component is updated via state", function()
		local Foo = Component:extend("Foo")

		local setState
		function Foo:init()
			setState = function(...)
				return self:setState(...)
			end
		end

		local renderSpy = createSpy()
		Foo.render = renderSpy.value

		local element = createElement(Foo)
		local hostParent = nil
		local key = "Foo Test"

		noopReconciler.mountNode(element, hostParent, key)

		expect(renderSpy.callCount).to.equal(1)

		local initialRenderArguments = renderSpy:captureValues("self")
		local initialProps = initialRenderArguments.self.props
		local initialState = initialRenderArguments.self.state

		expect(Type.of(initialRenderArguments.self)).to.equal(Type.StatefulComponentInstance)

		setState({})

		expect(renderSpy.callCount).to.equal(2)

		local renderArguments = renderSpy:captureValues("self")
		local props = renderArguments.self.props
		local state = renderArguments.self.state

		expect(Type.of(renderArguments.self)).to.equal(Type.StatefulComponentInstance)
		expect(props).to.equal(initialProps)
		expect(state).never.to.equal(initialState)
	end)
end