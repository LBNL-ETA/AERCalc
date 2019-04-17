package flexUnitTests.model
{
	import mx.collections.ArrayCollection;
	
	import gov.lbl.aercalc.model.LibraryModel;
	import gov.lbl.aercalc.model.domain.WindowVO;
	
	import org.flexunit.asserts.assertEquals;
	import org.flexunit.asserts.assertNotNull;
	import org.flexunit.asserts.assertNull;
	import org.flexunit.asserts.assertTrue;
	

	public class TestLibraryModel
	{		
		
		private static var testWindowsArr:Array = [];
		
		private var libraryModel:LibraryModel
		
		private var exampleBasicWindow:WindowVO;
		private var exampleParentWindow:WindowVO;
		
		
		
		[Before]
		public function setUp():void
		{
			libraryModel = new LibraryModel();
			testWindowsArr = [];
			exampleBasicWindow = null;
			exampleParentWindow = null;
			
			
			/* create dummy window data and populate into library */
			var windowsArr:Array = [
				{
					"id": 1,
					"name": "Single cell Light color (Levolor) Interior::CS::BW-A",
					"type": "",
					"width": "1200",
					"height": "1500",
					"UvalWinter": "1.635598",
					"SHGC":	"0.254652",
					"Tvis":"0.17478",
					"epc":"0.375061247071",
					"eph":"0.00839088025314",
					"shadingSystemType":"CS",
					"airInfiltration":"1.9999999370000001",
					"W7Name":"Single cell Light color (Levolor) Interior::CS::BW-A",
					"parent_id":"0",
					"isParent":false,
					"W7ID":"1003",
					"W7GlzSysID":"1003",
					"baseWindowType":"BW-A",
					"WINDOWOriginDB":""
				}
			]
			
			for (var index:uint=0;index<windowsArr.length;index++){
				var w:Object = windowsArr[index];
				var windowVO:WindowVO = new WindowVO()
				for(var prop:String in w){
					windowVO[prop] = w[prop];
				}
				testWindowsArr.push(windowVO);
			}
			
			// Add some parent child combinations
			var p1:WindowVO = new WindowVO();
			p1.id = 10;
			p1.name = "parent";
			
			var c1:WindowVO = new WindowVO();
			c1.id = 11;
			c1.name = "child1";
			
			var c2:WindowVO = new WindowVO();
			c2.id = 12;
			c2.name = "child2";
			
			p1.children = [c1,c2];
			
			testWindowsArr.push(p1);
			
			exampleParentWindow = p1;
			exampleBasicWindow = testWindowsArr[0] as WindowVO;
			
			libraryModel.windowsAC = new ArrayCollection(TestLibraryModel.testWindowsArr);
			
			
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
		
		
		[Test (description = "Test remove one window")]
		public function testRemoveOneWindow():void {
			
			var windowToRemove:WindowVO = exampleBasicWindow;
			var idToRemove:int = windowToRemove.id;
			var totalWindows:uint = libraryModel.windowsAC.length;
			libraryModel.removeWindow(windowToRemove);
			
			assertEquals(libraryModel.windowsAC.length, totalWindows-1);
			
			var shouldNotExistWindow:WindowVO = libraryModel.getWindowByID(idToRemove);
			assertNull(shouldNotExistWindow);
		}
		
		
		[Test (description = "Test remove window that doesn't exist", expects="gov.lbl.aercalc.error.WindowDoesNotExistError")]
		public function testRemoveWindowThatDoesNotExist():void {
			
			var bogusWindow:WindowVO = new WindowVO();
			bogusWindow.id = 15125243;
			libraryModel.removeWindow(bogusWindow);
			
		}
		
		
		[Test (description = "Add one window")]
		public function addOneWindow():void {
			
			var totalWindows:uint = libraryModel.windowsAC.length;
			var newWindow:WindowVO = new WindowVO();
			newWindow.id = 999;
			libraryModel.addWindow(newWindow);
			
			var shouldExistWindow:WindowVO = libraryModel.getWindowByID(999);
			assertEquals(shouldExistWindow, newWindow);
			assertEquals(libraryModel.windowsAC.length, totalWindows + 1);
			
		}
		
		
	}
}