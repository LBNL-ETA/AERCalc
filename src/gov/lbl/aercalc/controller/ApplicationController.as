package gov.lbl.aercalc.controller
{


import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.IEventDispatcher;
import flash.events.TimerEvent;
import flash.events.UncaughtErrorEvent;
import flash.filesystem.File;
import flash.utils.Timer;

import gov.lbl.aercalc.business.FileManager;
import gov.lbl.aercalc.error.InvalidProjectDirectoryError;
import gov.lbl.aercalc.error.MissingBSDFDirectoryError;
import gov.lbl.aercalc.error.MissingSQLiteFileError;
import gov.lbl.aercalc.events.DBEvent;
import gov.lbl.aercalc.events.FileEvent;

import gov.lbl.aercalc.events.LoadProjectEvent;
import gov.lbl.aercalc.model.ApplicationModel;
import gov.lbl.aercalc.model.ApplicationModel;
import gov.lbl.aercalc.model.ImportModel;
import gov.lbl.aercalc.model.SimulationModel;
import gov.lbl.aercalc.model.settings.AppSettings;

import mx.core.FlexGlobals;
import mx.events.CloseEvent;
import mx.managers.PopUpManager;

import spark.components.Alert;
import spark.components.Application;

import gov.lbl.aercalc.business.AppSettingsDelegate;
import gov.lbl.aercalc.business.DBManager;
import gov.lbl.aercalc.business.LibraryDelegate;
import gov.lbl.aercalc.business.MigrationManager;
import gov.lbl.aercalc.events.ApplicationEvent;
import gov.lbl.aercalc.model.ApplicationModel;
import gov.lbl.aercalc.model.LibraryModel;
import gov.lbl.aercalc.model.settings.SettingsModel;
import gov.lbl.aercalc.util.Logger;
import gov.lbl.aercalc.util.Utils;
import gov.lbl.aercalc.view.ErrorView;
import gov.lbl.aercalc.view.dialogs.MigrationMessageDialog;


public class ApplicationController
	{

		[Inject]
		public var applicationModel:ApplicationModel;
		
		[Inject]
		public var dbManager:DBManager;
		
		[Inject]
		public var libraryDelegate:LibraryDelegate;

		[Inject]
		public var migrationMgr:MigrationManager;
		
		[Inject]
		public var libraryModel:LibraryModel;
		
		[Inject]
		public var libraryController:LibraryController;
		
		[Inject]
		public var dbController:DBController;

		[Inject]
		public var settingsModel:SettingsModel;

		[Inject]
		public var appSettingsDelegate:AppSettingsDelegate;

        [Inject]
        public var importModel:ImportModel;

        [Inject]
        public var simulationModel:SimulationModel;

		[Inject]
		public var fileManager:FileManager;

		[Dispatcher]
		public var dispatcher : IEventDispatcher;

		protected var _debugDate:Date; //date for timing execution


		/* FOR DEV AND TEST */
		// Set this to true to force all user files to be updated
		private var _forceClean: Boolean = false;
		
		public function ApplicationController() {}

		/* From SWIZ docs:
		
		If your startup logic only involves one bean, let that bean (probably a "main controller") implement IInitializingBean, 
		or decorate a method with [PostConstruct], and start with your application logic in that method. Swiz calls 
		these methods on beans when the injection process is complete.
		
		However, if your startup logic depends on events that must be handled by other beans, you need 
		to be sure that all of your beans have been properly set up. In this case, you can
		use an event handler method such as [EventHandler( "mx.events.FlexEvent.APPLICATION_COMPLETE" )]. This will mediate 
		the applicationComplete event, and only kick off processing once all of the beans have been set up.
		
		We implement the APPLICATION_COMPLETE approach here...			
		
		*/
		
		[EventHandler( "mx.events.FlexEvent.APPLICATION_COMPLETE" )]
		public function onApplicationComplete():void
		{
			Logger.debug("onApplicationComplete()",this);
			FlexGlobals.topLevelApplication.stage.nativeWindow.addEventListener(Event.CLOSING, onWindowClose);
			FlexGlobals.topLevelApplication.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);

			/* TODO
				When we start allowing user to switch SI <> IP, make sure
				to initialize formatters in Utils each time units are changed
				by calling Utils.setUnits(). Probably watch for units changed
				events in this controller and then call Utils.setUnits() within
				that handler function.
			*/
			//Initial initializations!
			Utils.initFormatters();
			Utils.setUnits(ApplicationModel.currUnits);

			//give popup a sec to show before starting anything computationally extensive...
			var t:Timer = new Timer(100);
			t.addEventListener(TimerEvent.TIMER, onStartInitApp);
			t.start()
		}
		

		public function onStartInitApp(event:TimerEvent):void
		{						
			var t:Timer = Timer(event.target);
			t.stop();
			t.removeEventListener(TimerEvent.TIMER, onStartInitApp);
			_debugDate = new Date();
				
			//Load settings (or create settings if none exist)
			applicationModel.loadingProgress = "Initializing...";
			settingsModel.appSettings = appSettingsDelegate.load();
				
			// Make sure all files are in order
			checkAndUpdateHelperFiles();

            var defaultProjectDir:File = ApplicationModel.baseStorageDir;
			var defaultDB:File = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.AERCALC_DEFAULT_DB_PATH);
            loadProject(defaultProjectDir, defaultDB, true);
		}


		/* ================ */
		/* LOADING PROJECTS */
        /* ================ */

		/* Opens a database and loads all data. Validates
		*  helper files are present (e.g. BSDF files).
		*  We use a direct callback rather than events, since
		*  the dbController is pretty closely coupled to this main
		*  application controller, and using events makes that harder to see.
		*
		*  @param projectDir	File object pointing to directory to be opened as project
		*  @param dbFileName	File object pointing to .sqlite file in db subdirectory of project
		*  @param isStartup		Boolean	flag indicating whether this is the initial loading of
		 *  					project when app starts up.
		*
		* */
		public function loadProject(projectDir:File, dbFile:File, isStartup:Boolean = false):void {

            dispatcher.dispatchEvent(new ApplicationEvent(ApplicationEvent.LOADING_PROJECT, true));

			if (!isStartup){
                closeCurrentProject();
			}

			//db should always be in 'db' subdirectory in a project
			if (!dbFile.exists){
                Alert.show("Can't find AERCalc db: " + dbFile.name + " in a 'db' subdirectory in folder " +  projectDir.nativePath + ". Please select a different database.", "Database Error");
				Logger.error("openProject() couldn't find dbFile " + dbFile.nativePath, this);
				var evt:ApplicationEvent = new ApplicationEvent(ApplicationEvent.PROJECT_LOAD_FAILED, true);
                dispatcher.dispatchEvent(evt);
				return;
			}
            applicationModel.loadingProgress  = "Opening database...";
			applicationModel.currProjectDir = projectDir;
			applicationModel.currProjectDB = dbFile;
			try{
				dbController.openDatabase(dbFile);
			} catch (error:Error){
				Logger.error("openDatabase() Couldn't open database. " + error, this);
				Alert.show("Couldn't open the database." + error + ". Please select a different database.", "Database Error");
                evt = new ApplicationEvent(ApplicationEvent.PROJECT_LOAD_FAILED, true);
                dispatcher.dispatchEvent(evt);
                closeCurrentProject();
				return;
			}
		}


		/**  Open database callback. Assumes database has been opened without issue
		 *   and is now connected.
		 */
		[EventHandler(event="DBEvent.DB_OPEN_COMPLETE")]
		public function onDatabaseOpened(event:DBEvent):void {

			//check for database version and do migrations if necessary
			applicationModel.loadingProgress = "Checking database version...";
			if (migrationMgr.isDBCurrent==false)
			{
				var userNotesArr:Array = migrationMgr.getUserNotes();
				var currDBVersion:int = migrationMgr.installedDBVersion;
				var targetDBVersion:int = migrationMgr.targetDBVersion;
				Logger.debug("DB migrations required. Asking user if we should proceed. currDBVersion: " + currDBVersion + " targetDBVersion: " + targetDBVersion, this);
				var dialog:MigrationMessageDialog = new MigrationMessageDialog();
				dialog.setValues(userNotesArr, onMigrateDBUserResponse, currDBVersion,targetDBVersion);
				PopUpManager.addPopUp(dialog, FlexGlobals.topLevelApplication as Application, true);
				PopUpManager.centerPopUp(dialog);
			}
			else
			{
				Logger.debug("No DB migrations required.", this);
				continueLoadingDB();
			}
		}

		[EventHandler(event="DBEvent.DB_OPEN_FAILED")]
		public function onDatabaseOpenFailed(event:DBEvent):void {
			Alert.show("Couldn't open database. Please restart AERCalc to open default project. (" + event.msg + ")", "ERROR");
		}


		/**
		 * 	Get user's input and either proceed with migration or exit
		 */
		protected function onMigrateDBUserResponse(detail:int):void
		{
			if (detail==Alert.OK)
			{
				//give dialog a change to remove itself
				var t:Timer = new Timer(100);
				t.addEventListener(TimerEvent.TIMER, migrateDB);
				t.start();
			}
			else
			{
				Alert.show("Database was not migrated. Please open a different project.");
                closeCurrentProject();
			}
		}


		/**
		 * 	Migrate the db then go back to db loading process once migration complete.
		 */
		protected function migrateDB(event:TimerEvent):void
		{
			var t:Timer = event.target as Timer;
			t.stop();
			t.removeEventListener(TimerEvent.TIMER, migrateDB);
			t=null;
			applicationModel.loadingProgress = "Updating database...";

			//this will throw a DatabaseMigrationError if it goes bad...
			try{
                migrationMgr.migrateDB();
			} catch(error:Error){
				Logger.error("migrateDB() error: " + error, this);
				Alert.show("Could not migrate database " + dbManager.dbPath + ". See log for details. Please load a different database.", "Database Error");
                closeCurrentProject();
				return;
			}

			Alert.show("Database updated successfully.");
			continueLoadingDB();
		}


		/**
		 * 	Load all required items from DB for startup.
		 *  All necessary migrations should have already been run.
		 */
		protected function continueLoadingDB():void {

			//Right now all we have to do is load libraries.
			libraryDelegate.loadLibraries();

			//Get a list of BSDF files and flag windows that are missing a bsdf
			var bsdfDir:File = applicationModel.getCurrentProjectBSDFDir();
			var bsdfFileListing:Array = bsdfDir.getDirectoryListing();
			var bsdfFileNamsArr:Array =[];
			var numFiles:uint = bsdfFileListing.length;
			for (var fileIndex:uint = 0; fileIndex<numFiles; fileIndex++){
                bsdfFileNamsArr.push(File(bsdfFileListing[fileIndex]).name);
			}
			libraryDelegate.setBSDFlags(bsdfFileNamsArr);

			libraryModel.windowsAC.refresh();

			FlexGlobals.topLevelApplication.title = "Current project directory: " + applicationModel.currProjectDir.nativePath;

			dispatcher.dispatchEvent(new ApplicationEvent(ApplicationEvent.PROJECT_LOADED, true));
		}


        public function closeCurrentProject():void {
			dbManager.clear();
			applicationModel.currProjectDir = null;
            applicationModel.currProjectDB = null;
			libraryModel.clear();
        }





        /* ***************************** */
        /* HANDLE LOADING NEW PROJECT    */
        /* ***************************** */

		/* Respond to user request to load a new project */
        [EventHandler(event="ApplicationEvent.ON_LOAD_PROJECT")]
        public function onLoadProject(event:ApplicationEvent):void{

            //Do context check to make sure we can open a new file
            if (importModel.isImportInProgress()){
                Alert.show("Cannot open new project while import is in progress.", "Warning");
                return;
            }
            if (simulationModel.simulationInProgress){
                Alert.show("Cannot open new project while simulation is in progress.", "Warning");
                return;
            }

            //Allow user to select a target project file
			//Another method in this class will receive
			//async event after user selects and system
			//validates directory.
            try{
                fileManager.browseToLoadProjectDirectory();
            } catch (error:InvalidProjectDirectoryError){
                Alert.show("The selected item is not a directory.", "Error");
                return;
            } catch (error:MissingSQLiteFileError){
                Alert.show("The selected directory does not have a db subdirectory with a .sqlite file.");
                return;
            } catch (error:MissingBSDFDirectoryError){
                Alert.show("The selected directory is missing 'bsdf' subdirectory and AERCalc cannot automatically create one.", "Error");
                return;
            } catch (error:Error){
                Alert.show("Error when trying to open selected directory: " + error, "Error");
                return;
            }
        }

		/*
			The user has selected a project directory to load. The
			directory contents should have been validated by this point,
			so begin actual loading of project.
		 */
		[EventHandler(event="FileEvent.PROJECT_DIRECTORY_OPENED")]
        public function onProjectFileOpenSelected(event:FileEvent):void{
            var projectDir:File = event.targetProjectDirectory;
			var dbFile:File = event.targetDBFile;
			Logger.debug("onProjectFileOpenSelected(): User selected project directory to load: " + projectDir.nativePath, this);
			loadProject(projectDir, dbFile);
        }

        [EventHandler(event="FileEvent.INVALID_PROJECT_DIRECTORY")]
		public function onProjectFileOpenFailed(event:FileEvent):void{
			Alert.show("Couldn't open the selected project. " + event.msg, "ERROR");
		}





        /* ********************* */
        /* HANDLE SAVE PROJECT   */
        /* ********************* */


		[EventHandler(event="ApplicationEvent.ON_PROJECT_SAVE_AS")]
		public function onProjectSaveAs(event:ApplicationEvent):void{

            //Do context check to make sure we can open a new file
            if (importModel.isImportInProgress()){
                Alert.show("Cannot save project while import is in progress.", "Warning");
                return;
            }
            if (simulationModel.simulationInProgress){
                Alert.show("Cannot save project while simulation is in progress.", "Warning");
                return;
            }

            //Allow user to select a target project file
            //Another method in this class will receive
            //async event after user selects and system
            //validates directory.
            try {
                fileManager.browseToSaveProjectAsDirectory();
            } catch (error:Error){
				Logger.error("onProjectSaveAs() Couldn't browse to save file : " + error, this);
			}

		}


		/* Assumption is that selected directory is valid and empty */
        [EventHandler(event="FileEvent.PROJECT_SAVE_AS_DIRECTORY_SELECTED")]
		public function onProjectSaveAsDirSelected(event:FileEvent):void {

			var targetDir:File = event.targetProjectDirectory;
			var db:File = targetDir.resolvePath("db");
			db.createDirectory();

			var currDB:File = applicationModel.currProjectDB;
			var targetDB:File = db.resolvePath(targetDir.name + ".sqlite");
			try{
                currDB.copyTo(targetDB);
			} catch (error:Error){
				Logger.error("Couldn't copy sqlite database. Error: " + error, this);
				Alert.show("Could not copy current database into target directory.","Error");
				return;
			}

			var currBSDF:File = applicationModel.currProjectDir.resolvePath("bsdf");
			var targetBSDF:File = targetDir.resolvePath("bsdf");
			try{
                currBSDF.copyTo(targetBSDF);
			} catch (error:Error){
                Logger.error("Couldn't copy 'bsdf' directory. Error: " + error, this);
                Alert.show("Couldn't copy current 'bsdf' directory to target directory. See log for details.","Error");
                return;
			}
			Alert.show("Project saved");
		}


        [EventHandler(event="FileEvent.INVALID_PROJECT_SAVE_AS_DIRECTORY_SELECTED")]
        public function onProjectSaveAsDirInvalid(event:FileEvent):void {
			Alert.show("You must select an empty directory to save project into.", "Error");
        }





        /* ********************* */
		/* HANDLE APP CLOSING    */
		/* ********************* */

		public function onWindowClose(event:Event):void
		{
			Logger.debug("onWindowClose()", this);
			event.preventDefault();
			dispatcher.dispatchEvent(new ApplicationEvent(ApplicationEvent.QUIT));
		}

		[EventHandler(event="ApplicationEvent.QUIT")]
		public function quitApp(event:ApplicationEvent):void
		{
			Logger.debug("quitApp()", this);
			dispatcher.dispatchEvent(new ApplicationEvent(ApplicationEvent.QUITTING));
			appSettingsDelegate.save(settingsModel.appSettings);

			// Make sure all changed values are saved
			try {
                libraryController.saveChanges();
                FlexGlobals.topLevelApplication.exit();
			} catch (error:Error){
				Logger.error("Error when trying to saveChanges in libraryModel: " + error, this);
				Alert.show("Couldn't save changes to database. Do you still want to quit?", "Error", Alert.YES | Alert.CANCEL, null, onConfirmQuitAfterError);
			}
		}

		private function onConfirmQuitAfterError(event:CloseEvent):void {
			if (event.detail == Alert.YES){
                FlexGlobals.topLevelApplication.exit();
			}
		}




		/* ********************* */
		/* HANDLE ERRORS         */
		/* ********************* */

		/* Catch all uncaught errors, including during the startup process */
		private function onUncaughtError(e:UncaughtErrorEvent):void
		{
			/* TODO : 	Handle different kinds of errors.
						Some might require showing a dialog with
						extra information or instructions.

						 - DatabaseMigrationError
			*/


			if (e.error is Error)
			{
				var error:Error = e.error as Error;
				var msg:String = error.errorID + " " + error.name + " " + error.message;
				var stackTrace:String = error.getStackTrace();
				if (stackTrace!="")
				{
					msg += "\n\n" + stackTrace;
				}
				Logger.error(msg, this);
			}
			else
			{
				var errorEvent:ErrorEvent = e.error as ErrorEvent;
				msg = "error ID :" + errorEvent.errorID;
				msg += "\n type: " + errorEvent.type;
				msg += "\n current target: " + errorEvent.currentTarget;
				msg += "\n target: " + errorEvent.target;
				Logger.error(msg, this);
			}			
			ErrorView.show(msg);
		}





        /* ********************* */
        /* HELPER METHODS        */
        /* ********************* */

        /**
         * Make sure base storage directory exists and all required files are present.
         */
        private function checkAndUpdateHelperFiles():void {

            var baseDir:File = ApplicationModel.baseStorageDir;
            if (baseDir.exists==false)
            {
                try
                {
                    baseDir.createDirectory();
                }
                catch(error:Error)
                {
                    var errorMsg:String = "AERCalc couldn't create the necessary files in your user directory. Please make sure you have the correct permissions to run this program and then restart AERCalc (error: couldn't create file: " + baseDir.nativePath + ")"
                    Logger.error(errorMsg, this);
                    throw Error(errorMsg)
                }
            }

            // Make sure all helper files subdirectories
            // are present in user directory (they might have deleted one or all)
            // Also check for some key files themselves in case user deleted file
            // not subdirectory
            if (Utils.isMac) {
                var weather_dir:String = ApplicationModel.ENERGY_PLUS_MAC_SUBDIR;
            } else {
                weather_dir = ApplicationModel.ENERGY_PLUS_SUBDIR;
            }

            var helperFiles:Array = [
                weather_dir,
                ApplicationModel.AERCALC_DB_SUBDIR,
                ApplicationModel.AERCALC_DEFAULT_DB_PATH,
                ApplicationModel.WINDOW_SUBDIR,
                ApplicationModel.ENERGY_PLUS_SUBDIR,
                ApplicationModel.AERCALC_DB_SUBDIR,
                ApplicationModel.EPCALC_SUBDIR,
                ApplicationModel.BSDF_SUBDIR,
                ApplicationModel.THERM_SUBDIR,
                ApplicationModel.THERM_FILES_SUBDIR
            ];
			
			//bsdf is a special case.  Since it is empty AIR won't create it when making the install
			//adding code here to make sure it is created
			
			var bsdf_dir:File = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.BSDF_SUBDIR)
			if(!bsdf_dir.exists)
			{
				bsdf_dir.createDirectory();
			}
				
            for (var fileIndex:uint = 0 ; fileIndex < helperFiles.length; fileIndex++) {
                var helperFilesDir:String = helperFiles[fileIndex];
                var source:File =  File.applicationDirectory.resolvePath(helperFilesDir);
                var target:File = ApplicationModel.baseStorageDir.resolvePath(helperFilesDir);
                ensureHelperFilesPresent(source, target);
            }
        }

        private function ensureHelperFilesPresent(source:File, target:File):void {

            if (target.exists) {
                return;
            }

            if (source.isDirectory && !target.exists) {
                target.createDirectory();
            }

            try {
                source.copyTo(target, true);
            }
            catch (error:Error) {
                var errMsg:String = "Couldn't copy " + source.nativePath + " file to user directory: " + target.nativePath + " Error: " + error;
                Logger.warn(errMsg, this);

            }
        }


	}
}