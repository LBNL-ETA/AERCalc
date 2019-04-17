package flexUnitTests.business
{
	import flash.filesystem.File;
	
	import gov.lbl.aercalc.business.ExportDelegate;
	import gov.lbl.aercalc.model.domain.WindowVO;

	public class TestExportDelegate
	{		
		/* Tests some basic parts of export function. Hard 
		   to test the "only export children if parent is expanded"
		   feature, since this involves UI state of AdvancedDataGrid
		
		*/

		//The column index for the parent/child type. 
		//TODO: get this programmatically.
		public static const PARENT_CHILD_TYPE_COL_INDEX:uint = 1;
		
		import mx.collections.ArrayCollection;
		import gov.lbl.aercalc.model.LibraryModel;
		import gov.lbl.aercalc.model.domain.WindowVO;
		import gov.lbl.aercalc.business.ExportDelegate;		
		import org.flexunit.asserts.*
		

		private var _windowsAC:ArrayCollection;
		private var _exportDelegate:ExportDelegate = new ExportDelegate();
		private var _totalNumRows:uint = 0;
		private var _totalNumParents:uint = 0;
		private var _totalNumChildren:uint = 0;
		
		
		[BeforeClass]
		public static function setUpBeforeClass():void
		{
			
		}
		
		
		[AfterClass]
		public static function tearDownAfterClass():void
		{
		}
		
		
		/* This could be more sophisticated */
		public static function createDummyWindow(object:Object):WindowVO {
			var windowVO:WindowVO = new WindowVO();
			for(var prop:String in object){
				windowVO[prop] = object[prop];
			}
			return windowVO;
		}
		
		
		[Before]
		public function setUp():void
		{
			
			/* 	Create dummy window data and populate into library.
			For now we'll just test one normal window and one 
			parent window with one child windows.
			*/
			var window1:WindowVO = TestExportDelegate.createDummyWindow(
				{
					"id": 1,
					"name": "Single cell Light color (Levolor) Interior::CS::BW-A",
					"type": "",
					"width": 1200,
					"height": 1500,
					"UvalWinter": 1.635598,
					"SHGC":	0.254652,
					"Tvis":0.17478,
					"epc":0.1,
					"eph":0.2,
					"shadingSystemType":"CS",
					"airInfiltration":"1.9999999370000001",
					"W7Name":"Single cell Light color (Levolor) Interior::CS::BW-A",
					"parent_id":0,
					"isParent":false,
					"W7ID":"1003",
					"W7GlzSysID":"1003",
					"baseWindowType":"BW-A",
					"WINDOWOriginDB":"",
                    "THERMFiles":"BASE_B_HD_1003.thm;BASE_B_JB_1003.thm; BASE_B_JB_1003.thm;BASE_B_SL_1003.thm"
				}
			);
			
			var window2:WindowVO = TestExportDelegate.createDummyWindow(
				{
					"id": 2,
					"name": "1 inch Dark Blue Aluminum Venetian Blind Interior",
					"type": "",
					"width": "",
					"height": "",
					"UvalWinter": "",
					"SHGC":	"",
					"Tvis":"",
					"epc":0.3,
					"eph":0.4,
					"shadingSystemType":"",
					"airInfiltration":"",
					"W7Name":"",
					"parent_id":0,
					"isParent": true,
					"isOpen": true,
					"W7ID":"",
					"W7GlzSysID":"",
					"baseWindowType":"",
					"WINDOWOriginDB":"",
                    "THERMFiles":"BASE_B_HD_1003.thm;BASE_B_JB_1003.thm; BASE_B_JB_1003.thm;BASE_B_SL_1003.thm"
				}
			);
			
			var childWindow1:WindowVO = TestExportDelegate.createDummyWindow(
				{
					"id": 3,
					"name": "1 inch Dark Blue Aluminum Venetian Blind Interior::VB0::BW-A",
					"type": "",
					"width": 5,
					"height":4,
					"UvalWinter": 0.4,
					"SHGC":	.5,
					"Tvis":.6,
					"epc":.8,
					"eph":.9,
					"shadingSystemType":"VB0",
					"airInfiltration":1.9,
					"W7Name":"1 inch Dark Blue Aluminum Venetian Blind Interior::VB0::BW-A",
					"parent_id": 2,
					"isParent": false,
					"W7ID":"2005",
					"W7GlzSysID":"2005",
					"baseWindowType":"BW-A",
					"WINDOWOriginDB":"",
                    "THERMFiles":"BASE_B_HD_1003.thm;BASE_B_JB_1003.thm; BASE_B_JB_1003.thm;BASE_B_SL_1003.thm"
				}
			);
			window2.isParent = true;
			window2.children = [childWindow1];
			childWindow1.parent_id = window2.id;
			
			var window3:WindowVO = 	 TestExportDelegate.createDummyWindow(
				{
					"id": 10,
					"name": "Test Venetian Blind Interior",
					"type": "",
					"width": "",
					"height": "",
					"UvalWinter": "",
					"SHGC":	"",
					"Tvis":"",
					"epc":0.3,
					"eph":0.4,
					"shadingSystemType":"",
					"airInfiltration":"",
					"W7Name":"",
					"parent_id":0,
					"isOpen": true,
					"isParent": true,
					"W7ID":"",
					"W7GlzSysID":"",
					"baseWindowType":"",
					"WINDOWOriginDB":"",
                    "THERMFiles":"BASE_B_HD_1003.thm;BASE_B_JB_1003.thm; BASE_B_JB_1003.thm;BASE_B_SL_1003.thm"
				}
			);
			
			var childWindow2:WindowVO = TestExportDelegate.createDummyWindow(
				{
					"id": 11,
					"name": "Test Venetian Blind Interior::VB0::BW-A",
					"type": "",
					"width": "6",
					"height": "7",
					"UvalWinter": "0.3",
					"SHGC":	".4",
					"Tvis":".5",
					"epc":".6",
					"eph":".7",
					"shadingSystemType":"VB0",
					"airInfiltration":"2.8",
					"W7Name":"Test Venetian Blind Interior::VB0::BW-A",
					"parent_id": 10,
					"isParent": false,
					"W7ID":"2005",
					"W7GlzSysID":"2005",
					"baseWindowType":"BW-A",
					"WINDOWOriginDB":"",
                    "THERMFiles":"BASE_B_HD_1003.thm;BASE_B_JB_1003.thm; BASE_B_JB_1003.thm;BASE_B_SL_1003.thm"
				}
			);
			window3.isParent = true;
			window3.children = [childWindow2];
			childWindow1.parent_id = window3.id;
			
			_windowsAC = new ArrayCollection([window1, window2, window3]);
			
			//set some convenience vars for testing
			for (var i:uint = 0; i < _windowsAC.length; i++){
				var windowVO:WindowVO = _windowsAC[i] as WindowVO;
				if(windowVO.isParent) {
					_totalNumParents++;
					_totalNumChildren += windowVO.children.length;
					_totalNumRows = _totalNumRows + 1 + windowVO.children.length;
				} else if (windowVO.isChild()==false){
					_totalNumRows++;
				}
			}
			
			
		}
		
		[After]
		public function tearDown():void
		{
		}
		
		
		/* Do some simple checks to make sure csv string is 
		   generated correctly for export. At the moment
		   we're just making sure the routine returns a string
		   and that it has the same number of columns as what's defined 
		   in the export class
		*/
		
		// TODO: Check individual values to make sure they're correct
		
		[Test (description = "Test generate csv from windows")]
		public function testExportRows():void {
			
			var results:String = _exportDelegate.getCSVFromWindows(_windowsAC);
			
			assertNotNull(results);
			
			var rowsArr:Array = results.split(File.lineEnding);
			//remove header
			rowsArr.shift();
			//get rid of empty row caused by split
			rowsArr.pop(); 
			
			assertEquals(_totalNumRows, rowsArr.length);
			
			var row1Arr:Array = rowsArr[1].split(",");
			var columnDefsArr:Array = _exportDelegate.getColumnsDefs();
			
			//Should have same number of columns as columns defined in export class
			assertEquals(columnDefsArr.length, row1Arr.length);
		}
		
		
		[Test (description = "Test only export child rows from parents that are 'open' (expanded) ")]
		public function testOnlyExportChildrenFromOpenParents():void {
			
			//Set one parent isOpen to false, and then make sure
			//that child row for that parent doesn't export
			
			var windowVO:WindowVO = _windowsAC[2] as WindowVO;
			//sanity check
			assertTrue(windowVO.isParent);
			assertEquals(1, windowVO.numChildren());
			windowVO.isOpen = false;
			
			var results:String = _exportDelegate.getCSVFromWindows(_windowsAC);
			
			assertNotNull(results);
			
			var rowsArr:Array = results.split(File.lineEnding);
			//remove header
			rowsArr.shift();
			//get rid of empty row caused by split
			rowsArr.pop(); 
			
			assertEquals(_totalNumRows-1, rowsArr.length); //one less than normal since the child row should be skipped
			
			var row1Arr:Array = rowsArr[1].split(",");
			var columnDefsArr:Array = _exportDelegate.getColumnsDefs();
			
			//Should have same number of columns as columns defined in export class
			assertEquals(columnDefsArr.length, row1Arr.length);
		}


        [Test (description = "Test parent/child type")]
        public function testParentChildType():void {

            var results:String = _exportDelegate.getCSVFromWindows(_windowsAC);

            var rowsArr:Array = results.split(File.lineEnding);
            //remove header
            rowsArr.shift();
            //get rid of empty row caused by split
            rowsArr.pop();

			
			var parentIDColIndex:int = _exportDelegate.getColumnIndex("parentChildType");
			
			//First row is neither parent nor child
			assertEquals(rowsArr[0].split(",")[parentIDColIndex], "");
			
			//Second row is parent
			assertEquals(rowsArr[1].split(",")[parentIDColIndex], "P"); 
			
			//Third row is child
			assertEquals(rowsArr[2].split(",")[parentIDColIndex], "C"); 
			
            //Should have same number of columns as columns defined in export class
            assertEquals(_exportDelegate.getColumnsDefs().length, rowsArr[1].split(",").length);
        }


		
		
		[Test (description = "Test the value in the 'Parent/Child' column is correct ")]
		public function testParentChildTypeColumn():void {
		
			var results:String = _exportDelegate.getCSVFromWindows(_windowsAC);
			var rowsArr:Array = results.split(File.lineEnding);
			//remove header
			rowsArr.shift();
			//get rid of empty row caused by split
			rowsArr.pop(); 
			
			var rows1:Array = rowsArr[0].split(",");
			assertEquals("", rows1[PARENT_CHILD_TYPE_COL_INDEX]);
			
			var rows2:Array = rowsArr[1].split(",");
			assertEquals("P", rows2[PARENT_CHILD_TYPE_COL_INDEX]);
			
			var rows3:Array = rowsArr[2].split(",");
			assertEquals("C", rows3[PARENT_CHILD_TYPE_COL_INDEX]);
			
			var rows4:Array = rowsArr[3].split(",");
			assertEquals("P", rows4[PARENT_CHILD_TYPE_COL_INDEX]);
			
			var rows5:Array = rowsArr[4].split(",");
			assertEquals("C", rows5[PARENT_CHILD_TYPE_COL_INDEX]);
			
			
		}
		
		
		
	}
}