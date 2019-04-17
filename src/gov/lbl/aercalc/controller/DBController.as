package gov.lbl.aercalc.controller
{
	
	import flash.events.Event;
	import flash.events.IEventDispatcher;
import flash.filesystem.File;

import gov.lbl.aercalc.business.DBManager;
	import gov.lbl.aercalc.business.LibraryDelegate;
import gov.lbl.aercalc.events.DBEvent;
import gov.lbl.aercalc.util.Logger;

public class DBController
	{
		[Dispatcher]
		public var dispatcher:IEventDispatcher;
		
		[Inject]
		public var libraryDelegate:LibraryDelegate;
		
		[Inject]
		public var dbManager:DBManager;
				
		public function DBController(){}
				
		
		public function openDatabase(dbFile:File):void {

			if (!dbFile.exists){
				throw new Error("Database file doesn't exist: " + dbFile.nativePath);
			}

			dbManager.setDBFile(dbFile);
			dbManager.addEventListener(DBManager.DB_CONNECTION_OPENED, onDBConnectionOpened);
			dbManager.addEventListener(DBManager.DB_CONNECTION_ERROR, onDBConnectionError);
			try
			{
				dbManager.openDB();
			}
			catch(err:Error)
			{
				var errorMsg:String = "Couldn't open database at " + dbManager.dbPath + ". Please place the " +
						"database in this location or use File>Options to select the correct path " +
						"to the database. Until then, AERCalc will not work properly.";
				throw new Error(errorMsg);
			}
		}
		
		public function onDBConnectionError(event:Event):void
		{
			var errorMsg:String = "Could not open connection to database at location: " + dbManager.dbPath + ". Please check log for details.";
			Logger.error("onDBConnectionError() " + errorMsg + " " + event.toString(),this);
			var evt:DBEvent = new DBEvent(DBEvent.DB_OPEN_FAILED, true);
			evt.msg = errorMsg;
			dispatcher.dispatchEvent(evt);


		}

		/** When the database is connected, read version then return.
		 *  Don't load any data, since we might have to do some migrations before that
		 */
		public function onDBConnectionOpened(event:Event):void
		{				
			//Now that DB has opened properly, make sure it's a valid DB. 
			//Right now the way I do this is just try the version function
			try
			{
				var version:Number = dbManager.getDBVersion();
			}
			catch(error:Error)
			{
				var errorMsg:String = "onDBConnectionOpened() database appears corrupted. Can't find version number in database. Error: " + error;
                Logger.error("onDBConnectionError() " + errorMsg + " " + event.toString(),this);
                var evt:DBEvent = new DBEvent(DBEvent.DB_OPEN_FAILED, true);
                evt.msg = errorMsg;
                dispatcher.dispatchEvent(evt);
			}

			evt = new DBEvent(DBEvent.DB_OPEN_COMPLETE, true);
			dispatcher.dispatchEvent(evt);

		}




	}
}