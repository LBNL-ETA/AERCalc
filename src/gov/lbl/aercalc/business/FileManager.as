package gov.lbl.aercalc.business {
import flash.events.Event;
import flash.events.IEventDispatcher;
import flash.filesystem.File;
import flash.net.FileFilter;

import gov.lbl.aercalc.error.InvalidProjectDirectoryError;
import gov.lbl.aercalc.error.MissingBSDFDirectoryError;
import gov.lbl.aercalc.error.MissingSQLiteFileError;
import gov.lbl.aercalc.events.FileEvent;
import gov.lbl.aercalc.model.ApplicationModel;
import gov.lbl.aercalc.util.Logger;

public class FileManager {


    /* Manages saving and loading AERCalc .sqlite databases
       and related files, e.g. helper bsdfs. */

    protected var _currentProjectPath:String;

    [Dispatcher]
    public var dispatcher:IEventDispatcher;


    public function FileManager() {
    }



    /* ********************** */
    /* HANDLE PROJECT SAVE AS */
    /* ********************** */

    public function browseToSaveProjectAsDirectory():void {
        var loadFile:File = File.documentsDirectory;
        loadFile.addEventListener(Event.SELECT, onBrowseToSaveProjectAsDirectorySelected, false, 0, true);
        loadFile.browseForDirectory("Select an empty folder to export project to.");
    }

    protected function onBrowseToSaveProjectAsDirectorySelected(event:Event):void {
        var f:File = event.target as File;
        f.removeEventListener(Event.SELECT, onBrowseToSaveProjectAsDirectorySelected);
        Logger.debug("User selected file to save project as : " + event.target, this);

        if (f.isDirectory==false){
            Logger.warn("onBrowseToSaveProjectAsDirectorySelected() User selected file for export, but should be directory",this);
            var evt:FileEvent = new FileEvent(FileEvent.INVALID_PROJECT_SAVE_AS_DIRECTORY_SELECTED);
            dispatcher.dispatchEvent(evt);
            return;
        }

        var files:Array = f.getDirectoryListing();
        if (files.length>0){
            Logger.warn("onBrowseToSaveProjectAsDirectorySelected() User selected non-empty directory for save as.",this);
            evt = new FileEvent(FileEvent.INVALID_PROJECT_SAVE_AS_DIRECTORY_SELECTED);
            dispatcher.dispatchEvent(evt);
            return;
        }

        evt = new FileEvent(FileEvent.PROJECT_SAVE_AS_DIRECTORY_SELECTED);
        evt.targetProjectDirectory = f;
        dispatcher.dispatchEvent(evt);
    }


    /* ********************** */
    /* HANDLE PROJECT LOAD    */
    /* ********************** */

    /* Allows user to browse for a directory that should have
       a AERCalc .sqlite database and a bsdf directory. This method
       will try to create the bsdf directory if it's missing, and will
       throw an error if it can't. It'll also throw errors if the .sqlite
       file is missing or the selected file is not a directory.
     */
    public function browseToLoadProjectDirectory():void {

        var loadFile:File = File.documentsDirectory;

        if (_currentProjectPath != "" && _currentProjectPath != null)
        {
            try{
                loadFile.nativePath = _currentProjectPath;
            }
            catch(error:Error){
                Logger.warn("browseToLoadProjectDirectory() Couldn't assign loadFile to locally saved default project path. Using documents directory...", this);
                loadFile = File.documentsDirectory;
            }
        }

        loadFile.addEventListener(Event.SELECT, onBrowseForProjectDirectorySelected, false, 0, true);
        loadFile.browseForDirectory("Select an AERCalc project directory")
    }


    protected function onBrowseForProjectDirectorySelected(event:Event):void{
        var targetProjectDirectory:File = event.target as File;
        targetProjectDirectory.removeEventListener(Event.SELECT, onBrowseToSaveProjectAsDirectorySelected);

        try{
            validateDirectory(targetProjectDirectory);
        }
        catch (error:InvalidProjectDirectoryError){
            var evt:FileEvent = new FileEvent(FileEvent.INVALID_PROJECT_DIRECTORY);
            evt.msg = "Invalid project directory";
            dispatcher.dispatchEvent(evt);
            return;
        }
        catch (error:MissingBSDFDirectoryError){
            /*
                Only catch this particular error. We'll create
                a bsdf directory if it doesn't exist. And if we can't we'll re-throw the error
                Other errors should bubble up to calling instance.
             */
            try{
                var bsdfDir:File = targetProjectDirectory.resolvePath("bsdf");
                bsdfDir.createDirectory();
            }
            catch(error:Error){
                Logger.error("onBrowseForProjectDirectorySelected(): Tried to automatically create a " +
                        "missing bsdf file in directory the user wants to open, but got error when doing so: " + error, this);
                evt = new FileEvent(FileEvent.INVALID_PROJECT_DIRECTORY);
                evt.msg = "Missing 'bsdf' subdirectory in project directory.";
                dispatcher.dispatchEvent(evt);
                return;
            }
        }
        catch (error:MissingSQLiteFileError){
            evt = new FileEvent(FileEvent.INVALID_PROJECT_DIRECTORY);
            evt.msg = error.message;
            dispatcher.dispatchEvent(evt);
            return;
        }
        catch (error:Error){
            evt = new FileEvent(FileEvent.INVALID_PROJECT_DIRECTORY);
            evt.msg = error.message;
            dispatcher.dispatchEvent(evt);
            return;
        }

        _currentProjectPath = targetProjectDirectory.nativePath;

        var targetDBFile:File = getDBFile(targetProjectDirectory);

        evt = new FileEvent(FileEvent.PROJECT_DIRECTORY_OPENED);
        evt.targetProjectDirectory = targetProjectDirectory;
        evt.targetDBFile = targetDBFile;
        dispatcher.dispatchEvent(evt);

    }


    /* Make sure supplied directory has all required files
       that a proper AERCalc directory would have. Returns a
       string describing errors, otherwise null.
     */
    public function validateDirectory(projectDir:File):Boolean {

        if (!projectDir.isDirectory){
            Logger.error("validateDirectory(): User tried opening file that wasn't a directory.", this);
            throw new InvalidProjectDirectoryError();
        }

        var bsdfSubDir:File = projectDir.resolvePath(ApplicationModel.BSDF_SUBDIR);
        if (!bsdfSubDir.exists){
            Logger.error("validateDirectory(): No 'bsdf' subdirectory in project folder.", this);
            throw new MissingBSDFDirectoryError("No bsdf directory in project");
        }

        var dbSubdir:File = projectDir.resolvePath(ApplicationModel.AERCALC_DB_SUBDIR);
        if (!dbSubdir.exists){
            Logger.error("validateDirectory(): No db subdirectory in project folder.", this);
            throw new MissingSQLiteFileError("No db subdirectory in project folder.");
        }

        var files:Array = dbSubdir.getDirectoryListing();
        var numSQLiteFiles:int = 0;
        for(var i:uint = 0; i < files.length; i++)
        {
            var fileName:String = files[i].name;
            if (fileName.split(".").pop()=="sqlite"){
                numSQLiteFiles++;
            }
        }

        if (numSQLiteFiles==0){
            Logger.error("validateDirectory(): User selected directory without .sqlite file.", this);
            throw new MissingSQLiteFileError("No .sqlite file present in a 'db' subdirectory.");
        }
        if (numSQLiteFiles>1){
            Logger.error("validateDirectory(): Too many .sqlite files in directory.", this);
            throw new Error("More than one .sqlite file in the 'db' subdirectory.");
        }

        return true;
    }


    /* Gets the first .sqlite file in project's db subdirectory.
       Assumes validation has already been run.
     */
    protected function getDBFile(projectDir:File):File {

        var dbSubdir:File = projectDir.resolvePath(ApplicationModel.AERCALC_DB_SUBDIR);
        var files:Array = dbSubdir.getDirectoryListing();
        for(var i:uint = 0; i < files.length; i++)
        {
            var fileName:String = files[i].name;
            if (fileName.split(".").pop()=="sqlite"){
               return dbSubdir.resolvePath(fileName);
            }
        }
        return null;

    }


}
}
