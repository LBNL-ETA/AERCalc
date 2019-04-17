/**
 * Created by danie on 24/01/2017.
 */
package gov.lbl.aercalc.controller {
import gov.lbl.aercalc.util.Logger;

import flash.events.IEventDispatcher;
import flash.filesystem.File;

import mx.collections.ArrayCollection;

import spark.components.Alert;

import gov.lbl.aercalc.business.DBManager;
import gov.lbl.aercalc.error.WindowDoesNotExistError;
import gov.lbl.aercalc.events.DeleteWindowsEvent;
import gov.lbl.aercalc.model.ApplicationModel;
import gov.lbl.aercalc.model.LibraryModel;
import gov.lbl.aercalc.model.domain.WindowVO;

public class LibraryController {

    [Inject]
    public var applicationModel:ApplicationModel;

    [Inject]
    public var libraryModel:LibraryModel;

    [Inject]
    public var dbManager:DBManager;

    [Dispatcher]
    public var dispatcher:IEventDispatcher;


    public function LibraryController() {
    }



    /* Delete windows selected by user. */
    [EventHandler(event="DeleteWindowsEvent.DELETE_WINDOWS")]
    public function onDeleteWindows(event:DeleteWindowsEvent):void {

		var warningMsg:String = null;
		
        // Keep track of windows deleted
		var deletedIDs:Array = [];

		// local ref for which windowVOs to delete
		var deleteWindowVOs:Array = event.selectedItems;
        var numWindowsToDelete:uint=deleteWindowVOs.length;

        // add in any parents if all their children are marked for deletion
        var deleteChildIDsArr:Array = [];
        var deleteParentIDsArr:Array = [];
        // Gather all child and parent ids
        for (var windowIndex:uint=0;windowIndex<numWindowsToDelete;windowIndex++){
            var windowVO:WindowVO = deleteWindowVOs[windowIndex]as WindowVO;
            if (windowVO.isChild()){
                deleteChildIDsArr.push(windowVO.id);
            } else if (windowVO.isParent){
                deleteParentIDsArr.push(windowVO.id);
            }  else {
                //don't need to index IDs of 'normal' WindowVOs
            }
        }
        // Check for parents with all children marked for deletion
        for (windowIndex=0;windowIndex<numWindowsToDelete;windowIndex++){
            windowVO = deleteWindowVOs[windowIndex]as WindowVO;
            if (windowVO.isChild()){
                var parentVO:WindowVO = libraryModel.getWindowByID(windowVO.parent_id);
                var childrenWindowsArr:Array = parentVO.children;
                var allChildrenMarked:Boolean = true;
                for (var childIndex:uint=0;childIndex<childrenWindowsArr.length; childIndex++){
                    var childID:uint = childrenWindowsArr[childIndex].id;
                    if (deleteChildIDsArr.indexOf(childID)<0){
                        allChildrenMarked = false;
                    }
                }
                if (allChildrenMarked && deleteParentIDsArr.indexOf(parentVO.id)<0){
                    deleteWindowVOs.push(parentVO);
                }
            }
        }

        //make sure if a parent was selected, all child WindowVOs are on the delete list
        for (windowIndex=0;windowIndex<numWindowsToDelete;windowIndex++){
            windowVO = deleteWindowVOs[windowIndex]as WindowVO;
			if (!windowVO){
				continue;
			}
            if (windowVO.isParent) {
                var childVOsArr:Array = libraryModel.getChildWindows(windowVO.id);
                for (childIndex=0;childIndex<childVOsArr.length;childIndex++){
                    var childVO:WindowVO = childVOsArr[childIndex] as WindowVO;
                    if (childVO && deleteWindowVOs.indexOf(childVO) < 0) {
						// add this child window to list of deletes..
                        deleteWindowVOs.push(childVO);
                    }
                }
            }
        }

        // We may now have a few extra windows...
        numWindowsToDelete = deleteWindowVOs.length;

        // Try deleting windows, if any fails, rollback and don't continue
		dbManager.sqlConnection.begin();
        for (windowIndex=0;windowIndex<numWindowsToDelete;windowIndex++){
            windowVO = deleteWindowVOs[windowIndex]as WindowVO;
            try {
                deleteWindow(windowVO);
            } catch(error:Error) {
                Logger.error("Couldn't delete window " + windowVO.id, this);
                dbManager.sqlConnection.rollback();
                var errorEvent:DeleteWindowsEvent = new DeleteWindowsEvent(DeleteWindowsEvent.DELETE_WINDOWS_ERROR, true);
                errorEvent.deleteErrorWindowID = windowVO.id;
                dispatcher.dispatchEvent(errorEvent);
                return
            }
        }
        dbManager.sqlConnection.commit();

		// for windows we successfully deleted,
		// cleanup any related files or relations
		// and remove actual VOs
		for (windowIndex=0;windowIndex<numWindowsToDelete;windowIndex++){
			windowVO = deleteWindowVOs[windowIndex]as WindowVO;
			deleteBSDFFile(windowVO);
			try{
				libraryModel.removeWindow(windowVO);
			}catch(error:WindowDoesNotExistError){
				Logger.warn("Expected window id " + windowVO.id + " to be present in library for removal but it wasn't there.", this);
				warningMsg = "There was an error remove a window from the library. Please restart.";
			}
			deletedIDs.push(windowVO.id);
		}
		
		if (warningMsg){
			Alert.show("Warning", warningMsg);
		}
		libraryModel.windowsAC.refresh();
		
        var completeEvent:DeleteWindowsEvent = new DeleteWindowsEvent(DeleteWindowsEvent.DELETE_WINDOWS_COMPLETE, true);
		completeEvent.deletedWindowIDsArr = deletedIDs;
        dispatcher.dispatchEvent(completeEvent);

    }

	
	public function saveChanges():void {
		for each (var windowVO:WindowVO in libraryModel.windowsAC){
			if (windowVO.isDirty){
				dbManager.save(windowVO);
			}
		}
	}
	
	public function saveWindow(windowVO:WindowVO):void {
		dbManager.save(windowVO);
	}

	
	/* Delete a window from the db.

	   @returns id of deleted window

	 */
	private function deleteWindow(windowVO:WindowVO):uint {
		//later we might need to do other things here.
		dbManager.remove(windowVO);
		return windowVO.id;
    }


	private function deleteBSDFFile(windowVO:WindowVO):void {
        // delete window BSDF if it's around
        try {
            var bsdfName:String = libraryModel.getBSDFName(windowVO.name);
            var projectBSDFDir:File = applicationModel.getCurrentProjectBSDFDir()
            var bsdfFile:File = projectBSDFDir.resolvePath(bsdfName);
            bsdfFile.deleteFile();
        } catch (error:Error) {
            //it's not a fatal error if we can't delete this file, so fail silently.
            Logger.error("Couldn't delete bsdf file : " + bsdfName, this);
        }
	}

	
	

}
}
