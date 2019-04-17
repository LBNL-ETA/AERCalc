
package gov.lbl.aercalc.controller {
import flash.events.IEventDispatcher;
import flash.filesystem.File;

import gov.lbl.aercalc.constants.Commands;
import gov.lbl.aercalc.model.ApplicationModel;

import mx.events.DynamicEvent;
import gov.lbl.aercalc.events.MenuEvent;

import spark.components.Alert;

import gov.lbl.aercalc.business.DBManager;
import gov.lbl.aercalc.business.W7ImportDelegate;
import gov.lbl.aercalc.error.DatabaseError;
import gov.lbl.aercalc.events.ApplicationEvent;
import gov.lbl.aercalc.events.W7ImportEvent;
import gov.lbl.aercalc.model.ImportModel;
import gov.lbl.aercalc.model.LibraryModel;
import gov.lbl.aercalc.model.SimulationModel;
import gov.lbl.aercalc.model.domain.W7WindowImportVO;
import gov.lbl.aercalc.model.domain.WindowVO;
import gov.lbl.aercalc.model.settings.AppSettings;
import gov.lbl.aercalc.model.settings.SettingsModel;
import gov.lbl.aercalc.util.Logger;
import gov.lbl.aercalc.view.dialogs.ImportW7WindowsDialog;


public class W7ImportController {

    /*
        This controller handles two main tasks:
            - getting a list of glazing systems that can be imported (and flagging those that are invalid)
            - generating the BDSF for a glazing system the user chooses to import

     */


    [Inject]
    public var importModel:ImportModel;

    [Inject]
    public var libraryModel:LibraryModel;

    [Inject]
    public var wDelegate:W7ImportDelegate;

    [Inject]
    public var dbManager:DBManager;

    [Inject]
    public var settings:SettingsModel;

    [Dispatcher]
    public var dispatcher:IEventDispatcher;

    [Inject]
    public var simulationModel:SimulationModel;

    [Inject]
    public var settingsModel:SettingsModel;


    //This variable tracks which window we're trying
    //to do a BSDF generation for.
    private var _currImportIndex:uint = 0;

    [PostConstruct]
    public function onPostConstruct():void {
        wDelegate.addEventListener(W7ImportDelegate.GLAZING_SYSTEM_LIST_IMPORTED, onGlazingSystemListImported);
        wDelegate.addEventListener(W7ImportDelegate.GLAZING_SYSTEM_LIST_IMPORT_FAILED, onGlazingSystemListImportFailed);

        wDelegate.addEventListener(W7ImportDelegate.BSDF_GENERATED, onBSDFGenerated);
        wDelegate.addEventListener(W7ImportDelegate.BSDF_GENERATION_FAILED, onBSDFGenerationFailed);

    }

    public function W7ImportController()
    {

    }

    /* Show a dialog for the list of WINDOW glazing systems
    *  Dialog will immediately default to progress bar while
    *  we attempt to load glazing systems from WINDOW.
    * */
    [EventHandler("ApplicationEvent.SHOW_IMPORT_W7_WINDOWS_VIEW")]
    public function onShowImportW7WindowsView(event:ApplicationEvent):void {

        //Make sure import db exists, otherwise force user to update
        try {
            var w7ImportDB:File = new File();
            w7ImportDB.nativePath = settings.appSettings.lblWindowDBPath;
            if (!w7ImportDB.exists) {
                throw new Error();
            }
        }
        catch(error){
            var msg:String =    "Can't find the WINDOW database specified in settings. \n\n" +
                                "Please open File > Preferences, select the WINDOW7 tab and then browse to a valid WINDOW database.\n";
            Alert.show(msg, "WINDOW database not found", Alert.OK);
            return;
        }

        var dial:ImportW7WindowsDialog = new ImportW7WindowsDialog();
        //Setup dialog and dependencies
        //TODO : Maybe use SWIZ inside dialog?
        dial.importModel = importModel;
        dial.importController = this;
        importModel.importW7WindowsDialog = dial;
        dial.show();
        dial.w7ImportPath  = settings.appSettings.lblWindowDBPath;
        importGlazingSystemList();
    }



    [EventHandler(event="MenuEvent.MENU_COMMAND", priority="10")]
    public function onMenuCommand(event:MenuEvent):void {

        // Intercept UI events if import window is showing
        if(event.command == Commands.SELECT_ALL && importModel.importW7WindowsDialog && importModel.importW7WindowsDialog.visible){
            event.stopImmediatePropagation();
            event.preventDefault();
            event.stopPropagation();
            switch (event.command) {
                case Commands.SELECT_ALL:
                    importModel.importW7WindowsDialog.selectAll();
                    break;
                case Commands.DESELECT_ALL:
                    importModel.importW7WindowsDialog.deselectAll();
                    break;
            }

        }
    }


    public function importGlazingSystemList():void {
        //Get list of available glazing systems from WINDOW
        importModel.currentState = ImportModel.STATE_IMPORTING_WINDOW_LIST;
		try {
			wDelegate.getGlazingSystemList();
		} catch (error:Error){
			Logger.error("Couldn't load W7 glazing system list. " + error, this);
			Alert.show("Couldn't load W7 glazing system list. Please check log for details.","Import Error");
			importModel.currentState = "";
		}       
    }


    public function onUserCancelGetList():void {
        wDelegate.cancelGetGlazingSystemList();
        importModel.currentState = "";
    }


    public function startWindowImport(selectedItems:Vector.<Object>):void {

        importModel.currentState = ImportModel.STATE_IMPORTING_WINDOW;

        //Build up a list of glazing systems to import, based on user selections
        importModel.importGlazingSystemAC.removeAll();
        var len:uint = selectedItems.length;
        for (var index:int=0; index<len; index++){
            var selectedItem:W7WindowImportVO = selectedItems[index] as W7WindowImportVO;
            importModel.importGlazingSystemAC.addItem(selectedItem);
        }

        //Init popup
        importModel.importW7WindowsDialog.setImportProgress(0,  importModel.importGlazingSystemAC.length);
		
        //Iterate through each selected item and run the BSDF generation sequence
        importModel.currImportIndex = 0;
        importModel.numBSDFImportFailures = 0;
        var glzSysVO:W7WindowImportVO = importModel.importGlazingSystemAC.getItemAt(_currImportIndex) as W7WindowImportVO;
        wDelegate.getBSDF(glzSysVO.W7ID, glzSysVO.name);

    }


    /* Stop W7 Import function per user request (if W7 is in progress) */
    public function onUserCancelWindowImport():void {
        wDelegate.cancelGetBSDF();
        importModel.currentState = "";
    }
	
	
	[EventHandler("ApplicationEvent.QUITTING")]
	public function onQuitting(event:ApplicationEvent):void {
		if (importModel.currentState == ImportModel.STATE_IMPORTING_WINDOW_LIST){
			wDelegate.cancelGetGlazingSystemList();
		}
		else if (importModel.currentState == ImportModel.STATE_IMPORTING_WINDOW){
			wDelegate.cancelGetBSDF();
		}
	}

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* PROTECTED/PRIVATE FUNCTIONS  */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

	/* 	
		When delegate reports that WINDOW list has been produced and parsed,
		update model with results and set dialog to proper state so user
		can view and select for importing.
	*/
	protected function onGlazingSystemListImported(event:DynamicEvent):void {
		importModel.w7GlazingSystemsAC = event.resultsAC;
        importModel.importW7WindowsDialog.refreshLists();
        importModel.importW7WindowsDialog.currentState = "default";
		importModel.currentState = "";
	}
		
	protected function onGlazingSystemListImportFailed(event:DynamicEvent):void {
		Alert.show("Couldn't load a list of glazing system from W7. See log for details.", "Import Error");
        importModel.importW7WindowsDialog.currentState = "listError";
		importModel.currentState = "";
	}


	/* 
		If a BSDF was generated, we can go ahead and 
		add the window to our library, or replace a 
		window with the same name if it exists.
	*/
    protected function onBSDFGenerated(event:DynamicEvent):void {

        //Save glz system to DB
        var importGlzSysVO:W7WindowImportVO = importModel.importGlazingSystemAC.getItemAt(importModel.currImportIndex) as W7WindowImportVO;
		dbManager.sqlConnection.begin();
        try {
            createOrUpdateWindow(importGlzSysVO);
            importGlzSysVO.importState = ImportModel.IMPORT_STATE_COMPLETE;
			dbManager.sqlConnection.commit();
			// TODO: Only copy BSDF from temporary location if window was imported ok
        } catch(error:Error) {
            Logger.error("onBSDFGenerated(): couldn't save Window object: " + error, this);
            importModel.numBSDFImportFailures++;
            importGlzSysVO.importState = ImportModel.IMPORT_STATE_FAILED;
            importGlzSysVO.errorMessage = error.toString();
			dbManager.sqlConnection.rollback();
        }
        importModel.currImportIndex++;
        importModel.w7GlazingSystemsAC.refresh();
        doNextBSDFImport();
    }


    protected function doNextBSDFImport():void {

        var numImports:uint = importModel.importGlazingSystemAC.length;

        //Progress bar should show all imported up until the current index, but not including current item, so don't adjust for 0-based index.
        importModel.importW7WindowsDialog.setImportProgress(importModel.currImportIndex, numImports);

        if (importModel.currImportIndex < numImports){
            var glzSysVO:W7WindowImportVO = importModel.importGlazingSystemAC.getItemAt(importModel.currImportIndex) as W7WindowImportVO;
            wDelegate.getBSDF(glzSysVO.W7ID, glzSysVO.name);
        }
        else {
            onImportFinished();
        }
    }


    protected function onBSDFGenerationFailed(event:DynamicEvent):void {
        var glzSysVO:W7WindowImportVO = importModel.importGlazingSystemAC.getItemAt(importModel.currImportIndex) as W7WindowImportVO;
        glzSysVO.importState = ImportModel.IMPORT_STATE_FAILED;
        glzSysVO.errorMessage = event.errorMessage;
        importModel.numBSDFImportFailures++;
        importModel.currImportIndex++;
        doNextBSDFImport();
    }


    protected function onImportFinished():void {
		
		// TODO: Reload all records from database so we
		// 		 make sure we have accurate data in memory
		//		 (some rows might have errored on import and
		//		 that particular transaction was rolled back)
		
        importModel.importW7WindowsDialog.importFinished();
        importModel.currentState = "";
        importModel.currImportIndex = 0;
        importModel.numBSDFImportFailures = 0;
    }


	/* 
		Take an incoming glazing system and either add it to
		our library or replace an existing item.
	*/
	
    protected function createOrUpdateWindow(importGlzSysVO:W7WindowImportVO):void{

        var parentWindowVO:WindowVO = null;

		// FIND EXISTING WINDOW (AND PARENT) OR CREATE
		
        // If this is a blind, make sure parent
        // exists so we can create parent<>child relationship.
		
		var w7Name:String = importGlzSysVO.name;
		var w7BaseName:String = importGlzSysVO.getBaseName();
		
        if (importGlzSysVO.isBlind()) {

			// Look for existing parent...
			// Parents are always named with the W7 base name
            parentWindowVO = libraryModel.getWindowByName(w7BaseName, true);

            if (parentWindowVO){
				var windowVO:WindowVO = parentWindowVO.getChildByW7Name(w7Name);
            }
			else {
				// If parent doesn't exist, create it now and save so we can
				// get an id. In this case the name will be same as the W7 base name
				parentWindowVO = new WindowVO();
				parentWindowVO.isParent = true;
				parentWindowVO.W7Name = "";
				parentWindowVO.name = w7BaseName;
				dbManager.save(parentWindowVO);
				libraryModel.addWindow(parentWindowVO);
			}
			
			if (!windowVO){
				windowVO = new WindowVO();
				windowVO.W7Name = importGlzSysVO.name;
				windowVO.name = importGlzSysVO.name;
				parentWindowVO.addChild(windowVO);
				dbManager.save(windowVO);
			}
        } else {
			//This is not a blind, therefore not a parent<>child window
			windowVO = libraryModel.getWindowByW7Name(w7Name);
			if (!windowVO){
				windowVO = new WindowVO();
				windowVO.W7Name = importGlzSysVO.name;
				windowVO.name = importGlzSysVO.name;
				windowVO.isParent = false;
				dbManager.save(windowVO);
				libraryModel.addWindow(windowVO);
			}
		}

        // UPDATE DATA
		
		// Zero out existing EPc and EPh value when importing
		windowVO.epc = 0;
		windowVO.eph = 0;
        // We just generated a bsdf
		windowVO.hasBSDF = true;
        windowVO.WINDOWVersion = ApplicationModel.VERSION_WINDOW;

        // Remember the name of the origin WINDOW DB
        if (settingsModel && settingsModel.appSettings){
            windowVO.WINDOWOriginDB = settingsModel.appSettings.lblWindowDBPath;
        } else {
            //Not a critical error
            Logger.error("Couldn't find W7 db path to assign to WINDOWOriginDB. Current path is : " + settingsModel.appSettings.lblWindowDBPath, this);
			windowVO.WINDOWOriginDB = "?";
        }

        //TODO: This is so kludgy...there must be a better way than manually adding every field to be copied from import VO to windowVO...

        // Copy over the base values of properties we care about.
        // TODO: Should we just be dealing with one object here? Perhaps not since their context may change and diverge
        // TODO: Come up with more efficient way of copying set of props from one object type to a different (but similar) object type
        // Copy W7ID as if it's a property, since the real unique identifier is the name, and perhaps the user
        // deleted and then created a new window with the same name
        var commonVarNames:Array = [    "_height",
                                        "_width",
                                        "_UvalWinter",
                                        "SHGC",
                                        "Tvis",
                                        "TvT",
                                        "shadingSystemType",
                                        "shadingSystemManufacturer",
                                        "shadingMaterialManufacturer",
                                        "attachmentPosition",
                                        "baseWindowType",
                                        "W7ID",
                                        "W7GlzSysID",
                                        "W7ShdSysID",
                                        "cgdbVersion",
                                        "WINDOWVersion",
                                        "THERMFiles",
                                        "Tsol",
                                        "Emishin",
                                        "Emishout"
                                    ];

        var len:uint = commonVarNames.length;
        for (var index:uint=0; index<len; index++){
            try {
                var commonVarName:String = commonVarNames[index];
                windowVO[commonVarName] = importGlzSysVO[commonVarName];
            } catch (error:Error){
                var errMsg:String = "Couldn't copy property " + commonVarName + " from imported row";
                Logger.error(errMsg, this);
                throw new Error(errMsg);
            }

        }
		//clear out any existing user IDs.
		windowVO.userID = null;
        dbManager.save(windowVO);
        libraryModel.windowsAC.refresh();

        var windowEvent:W7ImportEvent = new W7ImportEvent(W7ImportEvent.W7_WINDOW_IMPORTED);
        windowEvent.window = windowVO;
        dispatcher.dispatchEvent(windowEvent);
    }

}

}
