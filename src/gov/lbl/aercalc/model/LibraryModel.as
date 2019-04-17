package gov.lbl.aercalc.model
{
import gov.lbl.aercalc.util.Logger;

import mx.collections.ArrayCollection;
import mx.core.Window;

import gov.lbl.aercalc.business.DBManager;
import gov.lbl.aercalc.error.WindowDoesNotExistError;
import gov.lbl.aercalc.model.domain.WindowVO;


public class LibraryModel
	{


		// the list of window objects available for simulation
		[Bindable]
		public var windowsAC:ArrayCollection;

		//currently selected indices from windowsAC
		[Bindable]
		public var selectedIndices:Array;

		//pattern used for creating bsdf names from window name
        protected var _globalInvalidFilenameCharactersPattern:RegExp = /[\:\\\/\*\?\"\<\>\|]/g;

		
		public function LibraryModel()
		{
		}

		public function clear():void {
			if (windowsAC){
                windowsAC.removeAll();
                windowsAC.refresh();
			}
			selectedIndices = [];
		}
		
		public function addWindow(windowVO:WindowVO):void {
			//if this is a child, add beneath parent
			if (windowVO.isChild()){
				var parentIndex:int = getWindowIndex(windowVO.parent_id);
				this.windowsAC.addItemAt(windowVO, parentIndex+1);
			}else {
				this.windowsAC.addItem(windowVO);
			}
		}

		
		public function getWindowByID(id:uint):WindowVO{
			var len:uint = windowsAC.length;
			for (var index:uint=0;index<len;index++){
				var vo:WindowVO = windowsAC.getItemAt(index) as WindowVO;
				if (vo.id==id){
					return vo;
				}
				if (vo.isParent){
					var childVO:WindowVO = vo.getChildByID(vo.id);
					if (childVO) {
						return childVO;
					}
				}
			}
			return null;
		}

		
		public function getChildWindows(parentWindowID:uint):Array {
			var parentWindowVO:WindowVO = getWindowByID(parentWindowID);
			if (parentWindowVO==null){
				return [];
			}
			return parentWindowVO.children;
		}

		
		/* Remove a window from the model. Assumption is that
		   window has already been removed from DB.
		   Throw a WindowDoesNotExist error if matching window exists. 
		*/
		public function removeWindow(windowVO:WindowVO):void{
			if (windowVO.isChild()){
				var parentVO:WindowVO = this.getWindowByID(windowVO.parent_id);
				if (parentVO){
					parentVO.removeChild(windowVO);
					return;
				}
			} else {
				var wasRemoved:Boolean = windowsAC.removeItem(windowVO);
				if (wasRemoved==false){
					throw new WindowDoesNotExistError();
				}
			}
		}
		
		
		public function getWindowByW7Name(W7Name:String):WindowVO{
			var len:uint = windowsAC.length;
			for (var index:uint=0;index<len;index++){
				var vo:WindowVO = windowsAC[index] as WindowVO;
				if (vo.W7Name==W7Name){
					return vo;
				}
				if (vo.isParent){
					var numChildren:uint = vo.children.length;
					for (var childIndex:uint=0;childIndex<numChildren;childIndex++){
						var childVO:WindowVO = vo.children[childIndex] as WindowVO;
						if (childVO.W7Name == W7Name){
							return childVO;
						}
					}
				}
			}
			return null;
		}
		
		
		public function getWindowByName(name:String, ignoreChildren:Boolean=false):WindowVO{
			var len:uint = windowsAC.length;
			for (var index:uint=0;index<len;index++){
				var vo:WindowVO = windowsAC[index] as WindowVO;
				if (vo.name==name){
					return vo;
				}
				if (vo.isParent && ignoreChildren==false){
					var numChildren:uint = vo.children.length;
					for (var childIndex:uint=0;childIndex<numChildren;childIndex++){
						var childVO:WindowVO = vo.children[childIndex] as WindowVO;
						if (childVO.name == name){
							return childVO;
						}
					}
				}
			}
			return null;
		}


		public function getBSDFName(windowName:String):String {
			if (!windowName || windowName.length<1){
                Logger.error("getBSDFName() windowName was : " + windowName, this);
				throw new Error("windowName cannot be null or empty");
			}
            return windowName.replace(_globalInvalidFilenameCharactersPattern, "_") + "_bsdf.idf";
		}

		
		/* Get the index of a window in the library's window ArrayCollection */
		public function getWindowIndex(windowID:int):int{
			var len:uint = windowsAC.length;
			for (var index:uint=0;index<len;index++){
				if (this.windowsAC.getItemAt(index).id==windowID){
					return index;
				}
			}
			return -1;
		}

	}
}