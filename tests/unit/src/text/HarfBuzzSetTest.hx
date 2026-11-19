package text;

#if (lime_cffi && lime_harfbuzz && !macro)
import lime.text.harfbuzz.HBSet;
#end
import utest.Assert;
import utest.Test;

/**
	`HBSet` against HarfBuzz's API reference for hb_set_t, a set of code points
	or glyphs. Where a set has no value to give, HarfBuzz gives HB_SET_VALUE_INVALID,
	which is -1 as an `Int`.
**/
class HarfBuzzSetTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_harfbuzz && !macro)
	private static inline var INVALID = -1;

	public function testANewSetIsEmpty():Void
	{
		var set = new HBSet();

		Assert.isTrue(set.isEmpty);
		Assert.isTrue(set.allocationSuccessful);
		Assert.equals(0, set.population);
		Assert.equals(INVALID, set.min);
		Assert.equals(INVALID, set.max);
		Assert.isFalse(set.has(0));
	}

	public function testAddedValuesAreMembers():Void
	{
		var set = of([7, 3, 1000]);

		Assert.isFalse(set.isEmpty);
		Assert.equals(3, set.population);
		Assert.isTrue(set.has(3));
		Assert.isTrue(set.has(7));
		Assert.isTrue(set.has(1000));
		Assert.isFalse(set.has(4));
		Assert.isFalse(set.has(999));
		Assert.equals(3, set.min);
		Assert.equals(1000, set.max);
	}

	public function testAValueIsAMemberOnlyOnce():Void
	{
		var set = of([5, 5, 5]);
		Assert.equals(1, set.population);
	}

	public function testZeroIsAValueLikeAnyOther():Void
	{
		var set = of([0]);

		Assert.isFalse(set.isEmpty);
		Assert.isTrue(set.has(0));
		Assert.equals(1, set.population);
		Assert.equals(0, set.min);
		Assert.equals(0, set.max);
	}

	public function testTheLastCodePointAndLargerValuesAreMembers():Void
	{
		// Values are 32 bits wide, so the largest an Int can hold is 0x7FFFFFFF
		var set = of([0x10FFFF, 0x40000000, 0x7FFFFFFF]);

		Assert.equals(3, set.population);
		Assert.isTrue(set.has(0x10FFFF));
		Assert.isTrue(set.has(0x40000000));
		Assert.isTrue(set.has(0x7FFFFFFF));
		Assert.isFalse(set.has(0x10FFFE));
		Assert.equals(0x10FFFF, set.min);
		Assert.equals(0x7FFFFFFF, set.max);
	}

	public function testDelRemovesAValue():Void
	{
		var set = of([1, 2, 3]);
		set.del(2);

		Assert.isFalse(set.has(2));
		Assert.equals(2, set.population);

		// Removing what is not there changes nothing
		set.del(99);
		Assert.equals(2, set.population);
	}

	public function testRangesIncludeBothEnds():Void
	{
		var set = new HBSet();
		set.addRange(10, 20);

		Assert.equals(11, set.population);
		Assert.isFalse(set.has(9));
		Assert.isTrue(set.has(10));
		Assert.isTrue(set.has(20));
		Assert.isFalse(set.has(21));

		set.delRange(12, 14);
		Assert.equals(8, set.population);
		Assert.isTrue(set.has(11));
		Assert.isFalse(set.has(12));
		Assert.isFalse(set.has(14));
		Assert.isTrue(set.has(15));

		// A range of one value
		set.addRange(100, 100);
		Assert.isTrue(set.has(100));
		Assert.equals(9, set.population);
	}

	public function testARangeAcrossManyPagesIsCounted():Void
	{
		var set = new HBSet();
		set.addRange(0x1F600, 0x2F5FF);

		Assert.equals(0x10000, set.population);
		Assert.equals(0x1F600, set.min);
		Assert.equals(0x2F5FF, set.max);
	}

	public function testClearEmptiesTheSet():Void
	{
		var set = of([1, 2, 3]);
		set.clear();

		Assert.isTrue(set.isEmpty);
		Assert.equals(0, set.population);
		Assert.isFalse(set.has(1));
	}

	public function testSetsWithTheSameValuesAreEqual():Void
	{
		var set = of([1, 50, 70000]);

		Assert.isTrue(set.isEqual(of([70000, 1, 50])));
		Assert.isFalse(set.isEqual(of([1, 50])));
		Assert.isFalse(set.isEqual(of([1, 50, 70001])));
		Assert.isTrue(new HBSet().isEqual(new HBSet()));
		Assert.isFalse(set.isEqual(new HBSet()));
	}

	public function testSetCopiesAnotherSet():Void
	{
		var source = of([4, 8]);
		var set = of([1, 2, 3]);
		set.set(source);

		Assert.isTrue(set.isEqual(source));
		Assert.same([4, 8], members(set, [1, 2, 3, 4, 8]));

		// The copy is its own set
		set.add(9);
		Assert.isFalse(source.has(9));
		Assert.equals(2, source.population);
	}

	public function testUnionHoldsTheValuesOfEither():Void
	{
		var set = of([1, 2, 3, 100]);
		var other = of([3, 4, 100, 5000]);
		set.union(other);

		Assert.isTrue(set.isEqual(of([1, 2, 3, 4, 100, 5000])));
		Assert.isTrue(other.isEqual(of([3, 4, 100, 5000])));
	}

	public function testIntersectHoldsTheValuesOfBoth():Void
	{
		var set = of([1, 2, 3, 100]);
		var other = of([3, 4, 100, 5000]);
		set.intersect(other);

		Assert.isTrue(set.isEqual(of([3, 100])));
		Assert.isTrue(other.isEqual(of([3, 4, 100, 5000])));

		set.intersect(new HBSet());
		Assert.isTrue(set.isEmpty);
	}

	public function testSubtractRemovesTheValuesOfTheOther():Void
	{
		var set = of([1, 2, 3, 100]);
		var other = of([3, 4, 100, 5000]);
		set.subtract(other);

		Assert.isTrue(set.isEqual(of([1, 2])));
		Assert.isTrue(other.isEqual(of([3, 4, 100, 5000])));
	}

	public function testSymmetricDifferenceHoldsTheValuesOfOnlyOne():Void
	{
		var set = of([1, 2, 3, 100]);
		var other = of([3, 4, 100, 5000]);
		set.symmetricDifference(other);

		Assert.isTrue(set.isEqual(of([1, 2, 4, 5000])));
		Assert.isTrue(other.isEqual(of([3, 4, 100, 5000])));
	}

	public function testInvertSwapsMembersAndTheRest():Void
	{
		var set = of([5, 0x10FFFF]);
		set.invert();

		Assert.isFalse(set.has(5));
		Assert.isFalse(set.has(0x10FFFF));
		Assert.isTrue(set.has(0));
		Assert.isTrue(set.has(4));
		Assert.isTrue(set.has(6));
		Assert.isTrue(set.has(0x10FFFE));
		Assert.isFalse(set.isEmpty);
		Assert.equals(0, set.min);

		// Inverting twice gives the set back
		set.invert();
		Assert.isTrue(set.isEqual(of([5, 0x10FFFF])));
	}

	public function testTheEmptySetStaysEmpty():Void
	{
		// hb_set_get_empty: the one empty set, which cannot be changed
		var empty = HBSet.empty;
		Assert.isTrue(empty.isEmpty);

		empty.add(5);
		Assert.isTrue(HBSet.empty.isEmpty);
		Assert.isFalse(HBSet.empty.has(5));
		Assert.isTrue(HBSet.empty.isEqual(new HBSet()));
	}

	public function testNextOfAnEmptySetIsNothing():Void
	{
		var set = new HBSet();

		Assert.equals(INVALID, set.next());
		Assert.isNull(set.nextRange());
	}

	public function testNextStartsWithTheSmallestValue():Void
	{
		// hb_set_next: starting from HB_SET_VALUE_INVALID gives the first value of the set
		Assert.equals(3, of([7, 3, 900]).next());
		Assert.equals(0x10FFFF, of([0x10FFFF]).next());
	}

	public function testNextStartsWithZeroWhenZeroIsAMember():Void
	{
		Assert.equals(0, of([0, 7]).next());
		Assert.equals(0, of([0]).next());
	}

	public function testNextRangeStartsWithTheFirstRunOfValues():Void
	{
		// hb_set_next_range: starting from HB_SET_VALUE_INVALID gives the first run of consecutive values
		var set = new HBSet();
		set.addRange(5, 8);
		set.addRange(20, 30);
		var range = set.nextRange();

		Assert.notNull(range);
		if (range == null) return;

		Assert.equals(5, Std.int(range.x));
		Assert.equals(8, Std.int(range.y));
	}

	public function testNextRangeStartsAtZeroWhenZeroIsAMember():Void
	{
		var set = new HBSet();
		set.addRange(0, 3);
		set.addRange(10, 12);
		var range = set.nextRange();

		Assert.notNull(range);
		if (range == null) return;

		Assert.equals(0, Std.int(range.x));
		Assert.equals(3, Std.int(range.y));
	}

	// Helpers

	private static function of(values:Array<Int>):HBSet
	{
		var set = new HBSet();

		for (value in values)
		{
			set.add(value);
		}

		return set;
	}

	/** Which of `candidates` the set holds **/
	private static function members(set:HBSet, candidates:Array<Int>):Array<Int>
	{
		return [for (candidate in candidates) if (set.has(candidate)) candidate];
	}
	#end
}
