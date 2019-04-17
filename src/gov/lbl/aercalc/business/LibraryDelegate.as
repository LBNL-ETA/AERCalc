package gov.lbl.aercalc.business
{

import flash.filesystem.File;

import gov.lbl.aercalc.model.ApplicationModel;

import mx.collections.ArrayCollection;
	import mx.core.Window;
	
	import gov.lbl.aercalc.model.LibraryModel;
	import gov.lbl.aercalc.model.domain.WindowVO;
	import gov.lbl.aercalc.util.Logger;


public class LibraryDelegate
	{
		[Inject]
		public var libraryModel:LibraryModel;
		
		[Inject]
		public var dbManager:DBManager;
		
		
		public function LibraryDelegate():void
		{
		}
		
		public function loadLibraries():void
		{			
			var startTime:Date = new Date();
			
			// setup data structures to parse and hold flat data into hierarchical structure
			var lookup:Object = {} //for quick sorting below
			var hierWindowsArr:Array = new Array();
			
			// load table data from AERCalc db
			var dbWindowsAC:ArrayCollection = dbManager.findAll(WindowVO);
			
			// The window data in windows table is flat.
			// So now create hierarchical format within our model layer
			
			// First capture parents...
			var len:uint = dbWindowsAC.length;
			for (var wIndex:uint=0;wIndex<len;wIndex++){
				var wVO:Object = dbWindowsAC[wIndex];
				if (wVO.parent_id == 0){
					hierWindowsArr.push(wVO);
					lookup[wVO.id] = wVO;
				} 
			}
			
			// Then add children
			for (wIndex=0;wIndex<len;wIndex++){
				wVO = dbWindowsAC[wIndex];
				if (wVO.parent_id>0){
					lookup[wVO.parent_id].addChild(wVO);
				}
			}
			
			for (wIndex=0;wIndex<len;wIndex++){
				wVO = dbWindowsAC[wIndex];
				wVO.setVersionStatus();
			}

			libraryModel.windowsAC = new ArrayCollection(hierWindowsArr);
		
			var stopTime:Date = new Date();
			Logger.debug("finished database loading in : " + ((stopTime.time - startTime.time)/1000)+ " seconds", this)
			
			
		}

        /* Check each window and mark the BSDF missing
           if the window should have a BSDF but one
           doesn't exist in the bsdf folder.
        */
		public function setBSDFlags(bsdfFileNames:Array):void{
            checkForBSDFFiles(bsdfFileNames, libraryModel.windowsAC.source);
		}


		// Recursively iterate through windows. Mark those that
		// are missing BSDF files.
		private function checkForBSDFFiles(bsdfFileNames:Array, windowsArr:Array):int{
			var missingCount:int = 0;
            var len:uint = windowsArr.length;
            for (var wIndex:uint=0;wIndex<len;wIndex++){
                var wVO:WindowVO = windowsArr[wIndex];
				if (wVO.children && wVO.children.length>0){
                    missingCount += checkForBSDFFiles(bsdfFileNames, wVO.children);
				}
				else{
					if (wVO.isParent==false){
						var expectedName:String = libraryModel.getBSDFName(wVO.name);
                        wVO.hasBSDF = (bsdfFileNames.indexOf(expectedName)>=0);
						if(!wVO.hasBSDF){
							missingCount++;
						}
					}
				}
            }
			return missingCount;
		}

		
	}
}