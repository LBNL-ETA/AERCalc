package flexUnitTests.utils
{
	import gov.lbl.aercalc.util.Utils;
	
	import org.flexunit.assertThat;
	import org.flexunit.asserts.assertEquals;

	public class TestUtils
	{		
		[Before]
		public function setUp():void
		{
			//IMPORTANT : You have to initialize the formatters before using them
			Utils.initFormatters();
		}
		
		[After]
		public function tearDown():void
		{
		}
		
		[BeforeClass]
		public static function setUpBeforeClass():void
		{
		}
		
		[AfterClass]
		public static function tearDownAfterClass():void
		{
		}
		
		
		[Test( description = "Test setUnits fails on unrecognized units", expects="gov.lbl.aercalc.error.InvalidUnitsError" )]
		public function testUnits():void
		{
			var newBadUnits:String = "blah";
			Utils.setUnits(newBadUnits);
		}
		
		
		[Test (description = "Test normalize EP value")]
		public function testNormalizeEPValue():void {
			var initialValue:Number = 0.12345;
			assertEquals(12, Utils.normalizeEPValue(initialValue));
		}
		
		
		[Test( description = "Test rounding function behaves correctly")]
		public function testRoundingFunction():void {
			var initialValue:Number = 0.44444;
			assertEquals(0.44, Utils.roundValue(initialValue, 2));
			initialValue = 0.466666;
			assertEquals(0.47, Utils.roundValue(initialValue, 2));
			initialValue = 0.44444;
			assertEquals(0.444, Utils.roundValue(initialValue, 3));
			initialValue = 0.466666;
			assertEquals(0.467, Utils.roundValue(initialValue, 3));
		}
		
		
		/* At the moment our SI and IP values are both set to the Utils.ARGS_SAME rounding (2)
		   but this might change in the future */
		
		[Test (description = "Test rounding SI values")]
		public function testRoundingSIValues():void{
			Utils.setUnits("SI");
			
			var initialValue:Number = 0.12345;
			assertEquals(0.12, Utils.roundUFactor(initialValue));
			
			initialValue = 0.1299;
			assertEquals(0.13, Utils.roundUFactor(initialValue));
			
			initialValue = 0.12345;
			assertEquals(0.12, Utils.roundInfiltration(initialValue));
			
			initialValue = 0.1299;
			assertEquals(0.13, Utils.roundUFactor(initialValue));
			assertEquals(0.13, Utils.roundInfiltration(initialValue));
			
		}
		
		[Test (description = "Test rounding IP values")]
		public function testRoundingIPValues():void{
			
			Utils.setUnits("IP");
			
			var initialValue:Number = 0.12345;
			assertEquals(0.12, Utils.roundUFactor(initialValue));
			
			initialValue = 0.1299;
			assertEquals(0.13, Utils.roundUFactor(initialValue));
			
			initialValue = 0.12345;
			assertEquals(0.12, Utils.roundInfiltration(initialValue));
			
			initialValue = 0.1299;
			assertEquals(0.13, Utils.roundUFactor(initialValue));
			assertEquals(0.13, Utils.roundInfiltration(initialValue));
		}
		
		
		[Test (description="Test clone object")]
		public function testCloneObject():void{
			
			var sourceObj:Object = { "myString" : "something",
								"myInt" : 3,
								"myFloat" : 4.25,
								"myObj" : { "myProp" : "cheerio" }
			}
				
			var clone:Object = Utils.clone(sourceObj);	
			assertEquals(3, clone.myInt);
			assertEquals(4.25, clone.myFloat);
			assertEquals("something", clone.myString);
			assertEquals("cheerio", clone.myObj.myProp);
			
		}
		
		[Test (description="Test strip spaces")]
		public function testStripSpaces():void {
		
			var orig:String = "   blah   ";
			assertEquals("blah",Utils.stripspaces(orig));
			orig = "    blah";
			assertEquals("blah",Utils.stripspaces(orig));
			orig = "blah    ";
			assertEquals("blah",Utils.stripspaces(orig));
			orig = "   blah    blah   ";
			assertEquals("blahblah",Utils.stripspaces(orig));
			
		}
		
		
		[Test (description="Test replace all")]
		public function testReplaceAll():void {
			var orig:String = "It's all about me that's right me!";
			assertEquals("It's all about you that's right you!", Utils.replaceAll(orig,"me","you"));
		}
		
		
		[Test (description="Test scrubNewlines")]
		public function testScrubNewlines():void {
			var orig:String = "test\n\r\n";
			assertEquals("test", Utils.scrubNewlines(orig));
			
			orig = "\n\r\ntest";
			assertEquals("test", Utils.scrubNewlines(orig));
			
			orig = " keep these spaces \n\r\n";
			assertEquals(" keep these spaces ", Utils.scrubNewlines(orig));
			
		}
		
		
		[Test (description="Test munch")]
		public function testMunch():void {
			var orig:String = "test\n\n    \n\r\n   \n";
			assertEquals("test", Utils.munch(orig));
		}
		
		
		[Test (description="Test chump")]
		public function testChump():void {
			var orig:String = "                test  test  ";
			assertEquals("test  test  ", Utils.chump(orig));
		}
		
		
		[Test (description="Test get unique values")]
		public function testGetUniqueValues():void {
			var orig:Array = [1,2,2,3,3,3,4,5,4,5,6,1,2,3];
			assertThat([1,2,3,4,5,6], orig);

		}


   		 [Test (description="Test compare semver")]
		public function testCompareSemVer():void{
			
			assertEquals(Utils.SECOND_ARG_HIGHER, Utils.compareVersions("0.0.1","0.0.2"));
			assertEquals(Utils.SECOND_ARG_HIGHER, Utils.compareVersions("0.0.1","8.0"));
			assertEquals(Utils.SECOND_ARG_HIGHER, Utils.compareVersions("8.1", "8.1.1"));
			assertEquals(Utils.SECOND_ARG_HIGHER, Utils.compareVersions("7.0", "8"));
			assertEquals(Utils.SECOND_ARG_HIGHER, Utils.compareVersions("7.0.1", "8"));
			assertEquals(Utils.SECOND_ARG_HIGHER, Utils.compareVersions("7.0.1", "8.1"));
			assertEquals(Utils.SECOND_ARG_HIGHER, Utils.compareVersions("7.8", "8.1"));
			assertEquals(Utils.SECOND_ARG_HIGHER, Utils.compareVersions("7.8.1","8.1.0"));
			assertEquals(Utils.SECOND_ARG_HIGHER, Utils.compareVersions("8.1.1","8.1.2"));
			assertEquals(Utils.SECOND_ARG_HIGHER, Utils.compareVersions("8.1", "8.1.1"));
			 
			 assertEquals(Utils.ARGS_SAME, Utils.compareVersions("8","8.0.0"));
			 assertEquals(Utils.ARGS_SAME, Utils.compareVersions("8.0.0","8.0.0"));
			 assertEquals(Utils.ARGS_SAME, Utils.compareVersions("8","8.0"));
			 assertEquals(Utils.ARGS_SAME, Utils.compareVersions("8.0.0","8"));
			 assertEquals(Utils.ARGS_SAME, Utils.compareVersions("8.0","8"));
			 
			 assertEquals(Utils.FIRST_ARG_HIGHER, Utils.compareVersions("0.0.2","0.0.1"));
			 assertEquals(Utils.FIRST_ARG_HIGHER, Utils.compareVersions("8.0","0.0.1"));
			 assertEquals(Utils.FIRST_ARG_HIGHER, Utils.compareVersions("8.0","7"));
			 assertEquals(Utils.FIRST_ARG_HIGHER, Utils.compareVersions("8","7.0"));
			 assertEquals(Utils.FIRST_ARG_HIGHER, Utils.compareVersions("8","7.0.1"));
			 assertEquals(Utils.FIRST_ARG_HIGHER, Utils.compareVersions("8.1","7.0.1"));
			 assertEquals(Utils.FIRST_ARG_HIGHER, Utils.compareVersions("8.1","7.8"));
			 assertEquals(Utils.FIRST_ARG_HIGHER, Utils.compareVersions("8.1.0","7.8.1"));
			 assertEquals(Utils.FIRST_ARG_HIGHER, Utils.compareVersions("8.1.2","8.1.1"));
			 assertEquals(Utils.FIRST_ARG_HIGHER, Utils.compareVersions("8.1.1","8.1"));
		 }


		[Test(description="Test catches name with only two delimeters", expects="Error")]
		public function testTooFewDelimetersInName():void {
			var missingOneDelimiterName:String = "blah::blah";
			var name:String = Utils.getShadingTypeFromWindowName(missingOneDelimiterName);
		}


        [Test(description="Test catches name with four delimeters", expects="Error")]
        public function testTooManyDelimetersInName():void {
            var tooManyDelimiters:String = "blah::blah::blah::blah";
            var name:String = Utils.getShadingTypeFromWindowName(tooManyDelimiters);
        }

        [Test(description="Test catches invalid window name", expects="Error")]
        public function testInvalidWindowType():void {
            var tooManyDelimiters:String = "blah::blah::blah";
            var name:String = Utils.getWindowTypeFromWindowName(tooManyDelimiters);
        }



	}
}