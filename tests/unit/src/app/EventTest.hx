package app;

import lime.app.Event;
import lime.system.System;
import utest.Assert;
import utest.Test;

class EventTest extends Test
{
	public function new()
	{
		super();
	}

	public function testTimestampUsesDispatchTime():Void
	{
		var event = new Event<Int->Void>();
		var observed = -1;
		var before = System.getTimer();

		event.add(function(_)
		{
			observed = event.timestamp;
		});

		event.dispatch(1);
		var after = System.getTimer();

		Assert.isTrue(observed >= before);
		Assert.isTrue(observed <= after);
	}

	public function testExplicitTimestampIsVisible():Void
	{
		var event = new Event<Int->Void>();
		var observed = -1;

		event.add(function(_)
		{
			observed = event.timestamp;
		});

		@:privateAccess event.__dispatchWithTimestamp(1234, 1);
		Assert.equals(1234, observed);
	}

	public function testNestedDispatchUsesMostRecentTimestamp():Void
	{
		var event = new Event<Int->Void>();
		var timestamps:Array<Int> = [];
		var nested = false;

		event.add(function(_)
		{
			timestamps.push(event.timestamp);

			if (!nested)
			{
				nested = true;
				@:privateAccess event.__dispatchWithTimestamp(200, 2);
				Assert.equals(200, event.timestamp);
			}
		});

		@:privateAccess event.__dispatchWithTimestamp(100, 1);
		Assert.same([100, 200], timestamps);
		Assert.equals(200, event.timestamp);
	}

	public function testOnceListenerAddedAheadDuringDispatch():Void
	{
		var event = new Event<Int->Void>();
		var calls:Array<String> = [];

		function later(_:Int):Void
		{
			calls.push("later");
		}

		var added = false;

		event.add(function(value)
		{
			calls.push("running " + value);

			if (!added)
			{
				added = true;
				event.add(later, true, 1);
			}
		});

		event.dispatch(1);
		Assert.same(["running 1"], calls);
		Assert.isTrue(event.has(later));

		event.dispatch(2);
		Assert.same(["running 1", "later", "running 2"], calls);
		Assert.isFalse(event.has(later));
	}

	public function testOnceListenerAddingAheadIsTheOneRemoved():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];

		function ahead():Void
		{
			calls.push("ahead");
		}

		function once():Void
		{
			calls.push("once");

			if (!event.has(ahead))
			{
				event.add(ahead, false, 1);
			}
		}

		event.add(once, true);
		event.dispatch();
		Assert.same(["once"], calls);
		Assert.isFalse(event.has(once));
		Assert.isTrue(event.has(ahead));

		event.dispatch();
		Assert.same(["once", "ahead"], calls);
	}

	public function testListenerAddedAheadDoesNotRepeatEarlierListeners():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];
		var added = false;

		event.add(function()
		{
			calls.push("first");
		}, false, 2);

		event.add(function()
		{
			calls.push("second");

			if (!added)
			{
				added = true;
				event.add(function()
				{
					calls.push("added");
				}, false, 3);
			}
		}, false, 1);

		event.add(function()
		{
			calls.push("third");
		});

		event.dispatch();
		Assert.same(["first", "second", "third"], calls);
	}

	public function testListenerAddedBehindRunsInSameDispatch():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];
		var added = false;

		event.add(function()
		{
			calls.push("first");

			if (!added)
			{
				added = true;
				event.add(function()
				{
					calls.push("added");
				});
			}
		});

		event.dispatch();
		Assert.same(["first", "added"], calls);
	}

	public function testListenerRemovingItselfDoesNotSkipNext():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];

		function first():Void
		{
			calls.push("first");
			event.remove(first);
		}

		event.add(first);
		event.add(function()
		{
			calls.push("second");
		});

		event.dispatch();
		Assert.same(["first", "second"], calls);
		Assert.isFalse(event.has(first));
	}

	public function testListenerRemovingEarlierListenerDoesNotRepeat():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];

		function first():Void
		{
			calls.push("first");
		}

		event.add(first);
		event.add(function()
		{
			calls.push("second");
			event.remove(first);
		});
		event.add(function()
		{
			calls.push("third");
		});

		event.dispatch();
		Assert.same(["first", "second", "third"], calls);
		Assert.isFalse(event.has(first));
	}

	public function testListenerExceptionKeepsDispatchTimestamp():Void
	{
		var event = new Event<Int->Void>();

		event.add(function(_)
		{
			throw "listener failure";
		});

		Assert.raises(function():Void
		{
			@:privateAccess event.__dispatchWithTimestamp(1234, 1);
		});

		Assert.equals(1234, event.timestamp);
	}
}
