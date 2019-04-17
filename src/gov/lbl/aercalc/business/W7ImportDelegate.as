package gov.lbl.aercalc.business
{

import flash.crypto.generateRandomBytes;
import flash.desktop.NativeProcess;
import flash.desktop.NativeProcessStartupInfo;
import flash.events.EventDispatcher;
import flash.events.NativeProcessExitEvent;
import flash.events.ProgressEvent;
import flash.filesystem.*;

import gov.lbl.aercalc.error.InvalidImportWindowNameError;
import gov.lbl.aercalc.error.LblWindowDelegateError;
import gov.lbl.aercalc.model.ApplicationModel;
import gov.lbl.aercalc.model.ImportModel;
import gov.lbl.aercalc.model.LibraryModel;
import gov.lbl.aercalc.model.domain.W7WindowImportVO;
import gov.lbl.aercalc.model.settings.SettingsModel;
import gov.lbl.aercalc.util.Logger;
import gov.lbl.aercalc.util.Utils;

import mx.collections.ArrayCollection;
import mx.core.Application;
import mx.core.mx_internal;
import mx.events.DynamicEvent;


/** This delegate manages the running of W7 to
 *
 *   - generate a list of glazing systems for import
 *
 */


public class W7ImportDelegate extends EventDispatcher
{

    /* CONSTANTS */
    // Events launched from this delegate
    public static const GLAZING_SYSTEM_LIST_IMPORTED:String = "glazingSystemListImportedFromW6";
    public static const GLAZING_SYSTEM_LIST_IMPORT_FAILED:String = "glazingSystemListImportFromW6Failed";

    public static const BSDF_GENERATED:String = "bsdfGeneratedFromW7";
    public static const BSDF_GENERATION_FAILED:String = "bsdfGenerationFromW7Failed";

    // Constants for internal use
    protected static const WINDOWS_LIST_FILENAME:String = "windows_all.xml";
    protected static const REQUESTED_BSDF_FILENAME:String = "out.idf";
    protected static const GENERATED_BSDF_FILENAME:String = "out_bsdf.idf";


	
    // Injected dependencies
    [Inject]
    public var applicationModel:ApplicationModel;

    [Inject]
    public var settingsModel:SettingsModel;

    [Inject]
    public var libraryModel:LibraryModel;

    [Inject]
    public var importModel:ImportModel;

    // public vars

    // protected and private vars

    // File object for WINDOW executable
    protected var _wExe:File;

    // File object for  WINDOW DB file
    protected var _wDB:File;

    // Lock file for the db. We can delete this if it shows up,
    // since we're not doing any operations on the db.
    protected var _wDBLockFile:File;


    // File object defining where the input XML File
    // this delegate writes will be placed.
    protected var _xmlInputPath:File;

    // File object defining where log will be written.
    protected var _logDir:File;

    // Local .ini file for WINDOW
    protected var _iniFile:File;

    // Our preferred name for the BSDF file W7 generates
    protected var _requestedBsdfOutputFile:File;
    // The *actual*  BSDF output file as W7 currently names it
    // (There's a bug in W7 that it doesn't generate the file with the exact
    //  name you provide in the 'output' paramter)
    protected var _generatedBsdfOutputFile:File;


    //File object for the XML file that W7 will generate
    //to list all glazing systems available in DB.
    protected var _allWindowsXML:File;

    protected var _wPassword:String = "comfen"; //TODO change to "aercalc"
    protected var _process:NativeProcess;
    protected var _exportWindowsXML:XML;

    // Remember the glazing system ID we're working on
    // during async calls to W7
    protected var _currGlzSysW7ID:String;
	protected var _currGlzSysName:String;

    public function W7ImportDelegate():void
    {

    }

    /* ************** */
    /* PUBLIC METHODS */
    /* ************** */

    /* Initialize local variables that manage location of files,
       so we don't have to resolve them each time we run nativeProcess.
       This method is public as we might need to re-init file locations
       if the user changes preferences (e.g. location of WINDOW .mdb)
     */
    public function initW7Files():void
    {
		//make sure 'output' directory exists in W7 folder, since W7 will bomb if it doesn't
		var outDir:File = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.WINDOW_SUBDIR + "output");
		outDir.createDirectory();
		
        _process = new NativeProcess();
        _wDB = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.WINDOW_MDB_FILE_PATH);
        _wDBLockFile = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.WINDOW_MDB_LOCK_FILE_PATH);
        _wExe = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.WINDOW_EXE_FILE_PATH);
        _logDir = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.WINDOW_LOGS_FILE_PATH);
        _iniFile = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.WINDOW_INI_FILE_PATH);
        var wDir:File = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.WINDOW_SUBDIR);
        _allWindowsXML = wDir.resolvePath("output/" + WINDOWS_LIST_FILENAME);
        _xmlInputPath = wDir.resolvePath("input/in.xml");
        _requestedBsdfOutputFile = wDir.resolvePath("output/" + REQUESTED_BSDF_FILENAME);
        _generatedBsdfOutputFile = wDir.resolvePath("output/" + GENERATED_BSDF_FILENAME);

        updateIniIfMissing();

        if (Utils.isMac) {

            // Copy over test data files so we have something to parse

            // Glazing systems list
            var sample_glazing_systems:File = File.applicationDirectory.resolvePath('test_data/glazingsystems_all.xml');
            sample_glazing_systems.copyTo(_allWindowsXML, true);

            // BSDF output
            var bsdf:File = File.applicationDirectory.resolvePath('test_data/out_Bsdf.idf');
            bsdf.copyTo(_generatedBsdfOutputFile, true);

        }
    }


    /* Run WINDOW to get an xml list of all glazing systems available in the current DB
     *
     * command to launch WINDOW process should look like this:
     *
     *       w7 -DBExportTable GlzSys -DBExportXML (xml filename defined above in STATIC)
     *
     * */
    public function getGlazingSystemList():void {
        Logger.debug("getGlazingSystemList() Getting glazing system list");
        //clearLockFile();
		getWindowListFromW7();
    }

    /* Cancel process of importing all glazing systems list. */
    public function cancelGetGlazingSystemList():void {
        Logger.debug("cancelGetGlazingSystemList() ... cancelling process...");
        if(_process){
            _process.exit(true);
            removeGetGlazingSystemListListeners();
        }
    }

    public function getBSDF(W7ID:String, name:String):void {
        Logger.debug("getBSDFFromW7() Getting BSDF for glazing system with WINDOW7 ID " + W7ID, this);
        //clearLockFile();
        _currGlzSysW7ID = W7ID;
		_currGlzSysName = name;
        getBSDFFromW7();
    }

    public function cancelGetBSDF():void {
        Logger.debug("cancelGetGlazingSystemList() ... cancelling process...");
        _currGlzSysW7ID = "";
        if(_process){
            _process.exit(true);
            removeGetBSDFListeners();
        }
    }


    /* *************** */
    /* PRIVATE METHODS */
    /* *************** */

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /* GET GLAZING SYSTEM LIST METHODS */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    protected function getWindowListFromW7():void{

        //use latest paths...might have been changed.
        initW7Files();

        //If this is a mac, just fake it
        if (Utils.isMac) {
            onWindowListProcessFinished(null);
            return;
        }

        //clear out any existing files
		Logger.debug("clear out existing any previous window list xml files...", this);
        if (_allWindowsXML && _allWindowsXML.exists){
            _allWindowsXML.deleteFile();
        }
		
		Logger.debug("stopping any existing processes...", this);
        if (_process && _process.running){
            _process.exit(true)
        }

        // Get path to WINDOW DB as specified in application settings
        // (Could be a user selected db selected via preferences)
        var wDB:File = new File(settingsModel.appSettings.lblWindowDBPath);

        //make sure WINDOW .exe and .mdb exist		
		Logger.debug("make sure WINDOW .exe and .mdb exist...", this);
        if (_wExe.exists==false){
            Logger.error("Couldn't find the WINDOW executable in the default directory.", this);
            var msg:String = "Couldn't find the WINDOW executable in the default directory. ";
            msg += ("Please make sure the WINDOW .exe (" + _wExe.name + ") file exists in the AERCalc installation folder in the W7 sub-folder." + _wExe);
            throw new LblWindowDelegateError(msg)
        }

        if (wDB.exists==false)
        {
            Logger.error("Couldn't find the WINDOW database at path: " + wDB.nativePath, this);
            msg = "Couldn't find the WINDOW database at path: " + wDB.nativePath;
            msg += "Please select AERCalc > Preferences from the menu and update the WINDOW database path to point to a valid .mdb file";
            throw new LblWindowDelegateError(msg);
        }
		
        var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
        startupInfo.executable = _wExe;
        var processArgs:Vector.<String> = new Vector.<String>();
        processArgs.push("-pw");
        processArgs.push(_wPassword);
        processArgs.push("-ini");
        processArgs.push(_iniFile.nativePath);
		processArgs.push("-log");
		processArgs.push(_logDir.nativePath);
		processArgs.push("-verbose");
        processArgs.push("-db" );
        processArgs.push(wDB.nativePath);
        processArgs.push("-DBExportTable");
        processArgs.push("Window");
        processArgs.push("-DBExportXML");
        processArgs.push(_allWindowsXML.nativePath);        
        processArgs.push("-exit");


        Logger.debug(processArgs.join(" "), this);
        startupInfo.arguments = processArgs;

        Logger.debug("Starting W7 with ", processArgs.concat().toString());

        _process.addEventListener(NativeProcessExitEvent.EXIT, onWindowListProcessFinished);
        _process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onWStandardOutput);
        _process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onWStandardError);
        _process.start(startupInfo);

    }


    /* Remove all listeners involved in running native process */
    protected function removeGetGlazingSystemListListeners():void {
		if (_process){
			try {
				_process.removeEventListener(NativeProcessExitEvent.EXIT, onWindowListProcessFinished);
				_process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onWStandardOutput);
				_process.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onWStandardError);
			} catch(error:Error){
				Logger.error("Couldn't remove listeners. Error: " + error.message);
			}
		}     
    }

    /* Called when WINDOW finishes, regardless of exit state */
    protected function onWindowListProcessFinished(event:NativeProcessExitEvent):void
    {
        removeGetGlazingSystemListListeners();
        try
        {
			var resultsAC:ArrayCollection = readWindowListsResults();
        }
        catch(error:Error)
        {
            Logger.error("onWindowListProcessFinished() threw error: " + error, this);
            var evt:DynamicEvent = new DynamicEvent(W7ImportDelegate.GLAZING_SYSTEM_LIST_IMPORT_FAILED, false);
            evt.errorMessage = error.message;
            dispatchEvent(evt)
        }

		//clear out any existing files
		try{
			if(!settingsModel.appSettings.keepIntermediateFiles)
			{
				_allWindowsXML.deleteFile();
			}
		} catch (error:Error){
			Logger.warn("Error when trying to clear out glazing system xml: " + error);
		}

        //TODO Should I use a proper typed event? This event is really just to communicate between delegate and controller
        var successEvt:DynamicEvent = new DynamicEvent(W7ImportDelegate.GLAZING_SYSTEM_LIST_IMPORTED, false);
        successEvt.resultsAC = resultsAC;
        dispatchEvent(successEvt);

    }

    /* Reads an exported Window list from W7
       Throws an error if the actual file doesn't exist, or
       if there are no entries in the list.

       @return  An ArrayCollection of W7WindowImportVOs. These will have 'status'
                property set to identify whether they can be imported or not.
     */
    protected function readWindowListsResults():ArrayCollection
    {
		Logger.debug("Reading window list export from W7...");
		
        //check to see if xml is there
        if (_allWindowsXML.exists==false)
        {
            throw new Error("No export file was generated by WINDOW7 at this location: " + _allWindowsXML.nativePath);
        }

        //read in file contents
        var fileStream:FileStream = new FileStream();
        fileStream.open(_allWindowsXML, FileMode.READ);
        var result:String = fileStream.readUTFBytes(fileStream.bytesAvailable);
        fileStream.close();

        //parse and return results to command
        _exportWindowsXML = XML(result);

        var resultsAC:ArrayCollection = new ArrayCollection();
        for each (var windowXML:XML in _exportWindowsXML.*)
        {
            var vo:W7WindowImportVO = new W7WindowImportVO;
            vo.WINDOWVersion = ApplicationModel.VERSION_WINDOW;
            try {
                vo.W7ID = windowXML.ID;
                vo.W7GlzSysID = windowXML.GlzSysList.GlzSysID;
                vo.W7ShdSysID = windowXML.GlzSysList.GlzSys.ShadeList.ID;
                vo.name = windowXML.Name;
                vo.Tvis = windowXML.Tvis;
                vo.Tsol = windowXML.GlzSysList.GlzSys.Tsol;
                vo.Emishout = windowXML.GlzSysList.GlzSys.Emishout;
                vo.Emishin = windowXML.GlzSysList.GlzSys.Emishin;
                vo.SHGC = windowXML.SHGC;

                vo._UvalWinter = windowXML.UvalWinter;
                // There are a bunch of values that are not being exported by WINDOW when doing a dbexport of the window table.
                // Just filling them in with NANs so they'll be noticed

                // following fields to be imported were described by Robin M. in email 4/29/2009
                vo.envConditions = windowXML.EnvConditions;
                vo.tilt = windowXML.Tilt;

                vo._height = windowXML.Height;
                vo._width = windowXML.Width;
                vo.certification = windowXML.Certification;
                vo.status = windowXML.Status;
                vo.shadingSystemType = Utils.getShadingTypeFromWindowName(vo.name);
            }
            catch (error:Error){
                // If we have trouble parsing W7 XML for this window, still create
                // an 'invalid' row and add to results, so user can see more error details in rollover
                Logger.error("Error reading window ID: " + windowXML.ID + " Error: " + error, this);
                vo.importState = ImportModel.IMPORT_STATE_INVALID;
                vo.errorMessage = error.message;
                resultsAC.addItem(vo);
                continue;
            }

            //Capture CGDB ID, if available
            try {
                var source:String = windowXML.GlzSysList.GlzSys.ShadeList.ShadingLayer.Source;
                if (source=="CGDB"){

                    // NOTE ABOUT CGDB VERSION!!
                    // At the moment, the WINDOW mdb database defines the version as a float, which makes
                    // reading it as a proper 'version' string problematic (it gets written like "2.00000")
                    // Until the field is saved as a String in the W7 db, we are going to operate under the assumption
                    // that the version will only have a minor (not patch) portion, and the minor
                    // will never be more than 9, therefore we only look for a tenths place in the float.

                    var cgdbVer:String = windowXML.GlzSysList.GlzSys.ShadeList.ShadingLayer.Version;
                    var verArr:Array = cgdbVer.split(".");
                    cgdbVer = verArr[0];
                    if (verArr[1]&&verArr[1].length>=1){
                        cgdbVer += "." +verArr[1].slice(0,1);
                    }
                    else {
                        cgdbVer += ".0";
                    }
                    vo.cgdbVersion = cgdbVer;
                }
            }
            catch (error:Error) {
                // If we have trouble parsing cgdb ID this window, it doesn't invalidate import
                Logger.warn("Window ShadingLayer didn't have, or we couldn't read, CGDB version. Error: " + error, this);
            }

            // Capture shading system manufacturer, if available. Otherwise
            // this is an invalid product.
            try {
                vo.shadingSystemManufacturer = getShadingSystemManufacturer(vo, windowXML);
            } catch (error:Error){
                Logger.error("readWindowListsResults() Couldn't parse shading system manufacturer for window (W7ID: " + vo.W7ID + ")." + error, this);
                vo.importState = ImportModel.IMPORT_STATE_INVALID;
                vo.errorMessage = "Couldn't parse shading system manufacturer: " + error.message;
                resultsAC.addItem(vo);
                continue;
            }

            try {
                var shadingLayerType:String = windowXML.GlzSysList.GlzSys.ShadeList.ShadingLayer.Type;
            } catch (error:Error){
                Logger.error("readWindowListsResults() Couldn't find <ShadingLayer><Type/></ShadingLayer> (W7ID: " + vo.W7ID + ")." + error, this);
                vo.importState = ImportModel.IMPORT_STATE_INVALID;
                vo.errorMessage = "Couldn't find shading layer type : " + error.message;
                resultsAC.addItem(vo);
                continue;
            }

            // If this shading layer is a certain type, capture the shading
            // material manufacturer, which may be different from shading system manufacturer
            try {
                if (importModel.shadingLayerRequiresMaterial(int(shadingLayerType))){
                    vo.shadingMaterialManufacturer = getShadingMaterialManufacturer(vo, windowXML);
                } else {
                    vo.shadingMaterialManufacturer = ""; //just to be explicit!
                }
            } catch (error:Error){
                Logger.error("readWindowListsResults() Couldn't parse shading material manufacturer for window (W7ID: " + vo.W7ID + ")." + error, this);
                vo.importState = ImportModel.IMPORT_STATE_INVALID;
                vo.errorMessage = " Couldn't parse shading material manufacturer: " + error.message;
                resultsAC.addItem(vo);
                continue;
            }

            // Capture THERMFiles by reading all <Filename> elements from each <FrameList> in <Window>
            try {
                var thermFiles:String = "";
                for each (var frameListXML:XML in windowXML.FrameList){
                    var fullPath:String = frameListXML.Frame.Filename;
                    var thermFileName:String = fullPath.split("\\").pop();
                    thermFiles += thermFileName + ";";
                }
                vo.THERMFiles =thermFiles;
            } catch (error:Error){
                Logger.error("readWindowListsResults() Couldn't parse THERMFiles from FrameList (W7ID: " + vo.W7ID + ")." + error, this);
                vo.importState = ImportModel.IMPORT_STATE_INVALID;
                vo.errorMessage = "Couldn't parse THERMFiles. " + error.message;
                resultsAC.addItem(vo);
                continue;
            }


            // Parse the window name and set shading type and base window appropriately.
            // If name isn't correct, set item to invalid so it can't be imported.
            try {
                vo.setPropsByWindowName();
                vo.importState = ImportModel.IMPORT_STATE_AVAILABLE;
            }
            catch(error:InvalidImportWindowNameError){
                Logger.error("Error parsing window name. " + error.message);
                vo.importState = ImportModel.IMPORT_STATE_INVALID;
                vo.errorMessage = error.message
            }
            
            resultsAC.addItem(vo);

        }

        if (resultsAC.length==0)
        {
            throw new Error("No glazing systems available in WINDOW7");
        }

        return resultsAC;

    }


    /* Parse the windowXML looking for a manufacturer, and return
       if we find a valid one. Otherwise throw an error.
       Note that different window types look for the manufacturer
       in different places within the XML.
     */
    public function getShadingSystemManufacturer(vo:W7WindowImportVO, windowXML:XML):String{
		var manufacturer:String = "";
		if (vo.shadingSystemType=="WP"){
			var allClear:Boolean = true;
			for each (var glass:XML in windowXML.GlzSysList.GlzSys.GlassList.Glass){
				var glassLayerName:String = glass.Name;
				if (glassLayerName.indexOf("CLEAR_")>-1){
					continue;
				}
				allClear = false;
				
				if(glass.Manufacturer == null || glass.Manufacturer == ""){
					throw new Error("WP layer is missing manufacturer: " + glassLayerName);
				}
				
				//If the glass manufacturer is already in the list of manufacturers don't include it again
				if(manufacturer.toLocaleUpperCase().indexOf(glass.Manufacturer.toLocaleUpperCase()) > -1){
					continue;
				}
				if(manufacturer.length > 0){
					manufacturer += ";";
				}
				manufacturer += glass.Manufacturer;
			}
			
			// If all the layers are some sort of CLEAR just return generic for a manufacturer.
			if(allClear){
				manufacturer = "Generic"
			}
			if (manufacturer=="" || manufacturer==null){
				throw new Error("Couldn't find manufacturer of WP product in glass layers");
			}
			
			return manufacturer;
			
        }else if (vo.shadingSystemType=="AF"){
            for each (var glass:XML in windowXML.GlzSysList.GlzSys.GlassList.Glass){
                var glassLayerName:String = glass.Name;
                if (glassLayerName.indexOf("CLEAR_")>-1){
                    continue;
                }
                manufacturer = glass.Manufacturer;
            }
            if (manufacturer=="" || manufacturer==null){
                throw new Error("Couldn't find manufacturer of AF product in glass layers");
            }
            return manufacturer;
        } else {
            manufacturer = windowXML.GlzSysList.GlzSys.ShadeList.ShadingLayer.Manufacturer;
            if (windowXML.GlzSysList.GlzSys.ShadeList.length()>1){
                var msg:String = "Window has more than one shading layer: " + windowXML.toString();
                throw new Error(msg);
            }
            if (manufacturer==null || manufacturer == ""){
                msg = "Window (W7ID: " + vo.W7ID + ") is missing manufacturer.";
                throw new Error(msg);
            }
            return manufacturer;
        }
    }

    /* Return a shading material manufacturer *if* a ShadeMaterial element is defined,
       otherwise return empty string.
       If a ShadeMaterial is defined and no manufacturer can be found,
       that's not a good thing so we'll throw an error.
     */

    public function getShadingMaterialManufacturer(vo:W7WindowImportVO, windowXML:XML):String {
        if (windowXML.GlzSysList.GlzSys.ShadeList.ShadingLayer.ShadeMaterial == undefined){
            return "";
        }
        var shadeMaterial:XML = windowXML.GlzSysList.GlzSys.ShadeList.ShadingLayer.ShadeMaterial[0];
        if (shadeMaterial==undefined){
            return "";
        }
        var manufacturer:String = shadeMaterial.Manufacturer;
        if (manufacturer.length > 0){
            return manufacturer;
        }
        else {
            throw new Error("ShadeMaterial is missing Manufacturer.");
        }
    }


    public function getProcessRunning():Boolean
    {
        return _process.running
    }


    protected function writeInXML(inXML:XML):void
    {
        //write out in.xml
        var fileStream:FileStream = new FileStream();
        fileStream.open(_xmlInputPath, FileMode.WRITE);
        fileStream.writeUTFBytes(inXML.toXMLString());
        fileStream.close()
    }


    protected function updateIniIfMissing():void
    {

        var iniFile:File = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.WINDOW_INI_FILE_PATH);
        if (iniFile.exists)
        {
            return;
        }
        else
        {
            var defaultFile:File = File.applicationDirectory.resolvePath(ApplicationModel.WINDOW_INI_TEMPLATE_FILE_PATH);
            defaultFile.copyTo(iniFile, true);

            //append machine dependent lines
            var s:FileStream = new FileStream();
            s.open(iniFile, FileMode.APPEND);

            //var w6InstallationPath:String = appSettingsModel.w6InstallationPath
            //var lbnlSharedPath:String = appSettingsModel.w6InstallationPath

            var w6Dir:String = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.WINDOW_SUBDIR).nativePath;
			var thermExePath:String = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.THERM_EXE_FILE_PATH).nativePath;

            var out:String = File.lineEnding + "O5StandardsPath=" + w6Dir + "\\Standards\\W5_NFRC_2003.std";
            out += File.lineEnding + "W6BasisStandard=" + w6Dir + "\\W6_full_basis.xml";
            out += File.lineEnding + "W6BasisHalf=" + w6Dir + "\\W6_half_basis.xml";
            out += File.lineEnding + "W6BasisQuarter=" + w6Dir + "\\W6_quarter_basis.xml";
            out += File.lineEnding + "W6Database="+w6Dir + "\\" + ApplicationModel.WINDOW_MDB_FILE_PATH;
			out += File.lineEnding + "ThermPath=" + thermExePath;
			out += File.lineEnding + "HoneycombGenBSDFPath=" + w6Dir + "\\genBSDF";

            s.writeUTFBytes(out)
            s.close()

        }
    }


    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
    /*       GET BSDF METHODS       */
    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    protected function getBSDFFromW7():void{

        //use latest paths...might have been changed.
        initW7Files();

        //If this is a mac, just fake it
        if (Utils.isMac) {
            onGetBSDFProcessFinished(null);
            return;
        }

        //clear out any existing files
        if (_generatedBsdfOutputFile.exists){
            try {
                _generatedBsdfOutputFile.deleteFile();
            } catch(error:Error){
                throw new Error ("Can't delete the WINDOW7 BSDF output file. Please make sure it's not currently being used. The file is located here : " + _generatedBsdfOutputFile.nativePath)
            }

        }

        if (_process.running){
            _process.exit(true)
        }

        // Get path to WINDOW DB as specified in application settings
        // (Could be a user selected db selected via preferences)
        var wDB:File = new File(settingsModel.appSettings.lblWindowDBPath);

        //make sure WINDOW .exe and .mdb exist
        if (_wExe.exists==false){
            Logger.error("Couldn't find the WINDOW executable in the default directory.", this);
            var msg:String = "Couldn't find the WINDOW executable in the default directory. ";
            msg += ("Please make sure the WINDOW .exe (" + _wExe.name + ") file exists in the AERCalc installation folder in the W7 sub-folder." + _wExe);
            throw new LblWindowDelegateError(msg);
        }

        if (wDB.exists==false)
        {
            Logger.error("Couldn't find the WINDOW database at path: " + wDB.nativePath, this);
            msg = "Couldn't find the WINDOW database at path: " + wDB.nativePath;
            msg += "Please select AERCalc > Preferences from the menu and update the WINDOW database path to point to a valid .mdb file";
            throw new LblWindowDelegateError(msg);
        }

        var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
        startupInfo.executable = _wExe;
        var processArgs:Vector.<String> = new Vector.<String>();
        processArgs.push("-pw");
        processArgs.push(_wPassword);
        processArgs.push("-ini");
        processArgs.push(_iniFile.nativePath);
		processArgs.push("-log");
		processArgs.push(_logDir.nativePath);
		processArgs.push("-verbose");
        processArgs.push("-db" );
        processArgs.push(wDB.nativePath);
        processArgs.push("-windowReport");
        processArgs.push("AERC Energy Plus BSDF IDF");
        processArgs.push("-windowIDStart");
        processArgs.push(_currGlzSysW7ID);
        processArgs.push("-windowIDStop");
        processArgs.push(_currGlzSysW7ID);
        processArgs.push("-output");
        processArgs.push(_requestedBsdfOutputFile.nativePath);        
        processArgs.push("-exit");


        Logger.debug(processArgs.join(" "), this);
        startupInfo.arguments = processArgs;

        Logger.debug("Starting W7 with " + processArgs.join(" ").toString(), this);

        _process.addEventListener(NativeProcessExitEvent.EXIT, onGetBSDFProcessFinished);
        _process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onWStandardOutput);
        _process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onWStandardError);
        _process.start(startupInfo);


    }

    /* Called when WINDOW finishes, regardless of exit state */
    protected function onGetBSDFProcessFinished(event:NativeProcessExitEvent):void
    {
        Logger.info("W7 process finished.");

        removeGetBSDFListeners();
        try
        {
            // save generated BSDF to our BSDF storage directory
            // and then tell controller we're done
            var bsdfStorageDir:File = applicationModel.getCurrentProjectBSDFDir();
            if (!bsdfStorageDir.exists){
                bsdfStorageDir.createDirectory();
            }
            var newBSDFName:String = libraryModel.getBSDFName(_currGlzSysName);
            var targetBSDF:File = bsdfStorageDir.resolvePath(newBSDFName);
            _generatedBsdfOutputFile.copyTo(targetBSDF, true);
			
			changeComplexFenestrationStateName(targetBSDF, _currGlzSysName);

            // cleanup generic output file
			_generatedBsdfOutputFile.deleteFile();

            var evt:DynamicEvent = new DynamicEvent(W7ImportDelegate.BSDF_GENERATED, false);
            evt.glzSysID = _currGlzSysW7ID;
            evt.bsdfFileName = newBSDFName;
            dispatchEvent(evt);
        }
        catch(error:Error)
        {
            Logger.error("onGetBSDFProcessFinished() threw error while saving BSDF: " + error, this);
            evt = new DynamicEvent(W7ImportDelegate.BSDF_GENERATION_FAILED, false);
            evt.errorMessage = "Error saving generated BSDF: " + error.message;
            dispatchEvent(evt);
        }

        _currGlzSysW7ID = "";

    }


    protected function changeComplexFenestrationStateName(f:File, newName:String):void
    {
        var fileStream:FileStream = new FileStream();
        fileStream.open(f, FileMode.READ);
        var result:String = fileStream.readUTFBytes(fileStream.bytesAvailable);
        fileStream.close();
        var resultLines:Array = result.split("\n");
        for (var i:int = 0; i < resultLines.length; ++i)
        {
            if(resultLines[i].indexOf("Construction:ComplexFenestrationState") > -1)
            {
                resultLines[i+1] = newName + ",                                          !- name";
                break;
            }
        }

        fileStream.open(f, FileMode.WRITE);
        fileStream.writeUTFBytes(resultLines.join("\n"));
        fileStream.close();
    }


    /* Remove all listeners involved in running native process */
    protected function removeGetBSDFListeners():void {
        try {
            _process.removeEventListener(NativeProcessExitEvent.EXIT, onGetBSDFProcessFinished);
            _process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onWStandardOutput);
            _process.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onWStandardError);
        } catch(error:Error) {
            Logger.error("Couldn't remove listeners. Error: " + error.message);
        }
    }


    /* Handles WINDOW output for all processes */

    public function onWStandardOutput(event:ProgressEvent):void
    {
        var text:String = _process.standardOutput.readUTFBytes(_process.standardOutput.bytesAvailable)
        Logger.debug("LBNL WINDOW output: " + text, this);
    }

    public function onWStandardError(event:ProgressEvent):void
    {
        var text:String = _process.standardError.readUTFBytes(_process.standardError.bytesAvailable)
        Logger.error("LBNL WINDOW error when generating BSDF: " + text, this);

        var evt:DynamicEvent = new DynamicEvent(W7ImportDelegate.BSDF_GENERATION_FAILED, false);
        evt.errorMessage = "LBNL WINDOW error when generating BSDF: " + text;
        dispatchEvent(evt);

    }
	
	
	
	/* Clear any lock files W7 wrote, probably during
	a recent AERCalc action. We don't do any writing
	so don't need to worry about blowing these away if
	they're hanging around.
	*/
	
	protected function clearLockFile():void {
		if (_wDBLockFile.exists){
			_wDBLockFile.deleteFile();
		}
	}

}
}
