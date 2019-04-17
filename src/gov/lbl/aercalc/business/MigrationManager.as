package gov.lbl.aercalc.business
{
import gov.lbl.aercalc.util.Logger;

import flash.data.SQLConnection;
import flash.filesystem.File;

import spark.components.Alert;

import gov.lbl.aercalc.business.migrations.*;
import gov.lbl.aercalc.error.DatabaseMigrationError;
import gov.lbl.aercalc.model.ApplicationModel;

/*  MigrationManager
    This class manages a list of migrations that should be run at startup if the user's database
    is not in the most current state. The migrations that need to be run are compiled into AERCalc
    at build time as an array of values assigned to a property of this class.

 */

public class MigrationManager
{
    [Inject]
    public var dbManager:DBManager;

    [Inject]
    public var applicationModel:ApplicationModel;

    // Current version of database already extant on the target machine
    // If the db has no version, we'll assume it's 0
    private var _installedDBVersion:Number=0;

    // Location to store a backup of the DB
    // before running migrations
    public var backupDBPath:String = ApplicationModel.baseStorageDir.resolvePath("DBBackup/").nativePath;
    private var _backupDBFile:File;
    private var _backupDBFileName:String = "";

    // Array of migration classes to run for this particular version of
    // AERCalc and the verison it expects the DB to be in.
    private var _migrationsArr:Array;

    private var _currDBFile:File;

    public function MigrationManager()
    {
        loadMigrations();
    }

    public function loadMigrations():void
    {
        //all migrations should be added here. This will
        //serve as an authoratative list of all migrations that
        //should be applied to a database from the original version
        //to the most current version

        //IMPORTANT: THESE MUST BE ADDED TO THE ARRAY IN ORDER OF THEIR VERSION NUMBER
        _migrationsArr = [];
        _migrationsArr.push(new Migration2());
        _migrationsArr.push(new Migration3());
    }

    public function get installedDBVersion():Number
    {
        if (_installedDBVersion==0)
        {
            _installedDBVersion = dbManager.getDBVersion();
        }
        return _installedDBVersion;
    }

    /* Return true if database's version is the most recent. */
    public function get isDBCurrent():Boolean
    {
        var installedDBVersion:uint = dbManager.getDBVersion();
        Logger.debug("Checking db to see if it needs updating...", this);
        Logger.debug("installedDBVersion:" + installedDBVersion, this);
        Logger.debug("targetDBVersion:   " + targetDBVersion, this);
        return (installedDBVersion >= targetDBVersion);
    }


    /* Target version of database */
    public function get targetDBVersion():Number
    {
        if (_migrationsArr && _migrationsArr.length>0)
        {
            return BaseMigration(_migrationsArr[_migrationsArr.length-1]).version;
        }
        throw new Error("Can't get target DB version");
    }


    /** Returns array of user notes from all migrations that need to be run. */
    public function getUserNotes():Array
    {
        var returnArr:Array = [];
        var currentVersion:uint = dbManager.getDBVersion();
        var len:uint = _migrationsArr.length;
        for (var migrationIndex:uint=0;migrationIndex<len;migrationIndex++)
        {
            var migration:BaseMigration = _migrationsArr[migrationIndex] as BaseMigration;
            if (migration.version <= currentVersion) {
                continue;
            }
            if (migration.userNote!="")
            {
                returnArr.push("v" + migration.version.toString() + ": " + migration.userNote);
            }
        }
        return returnArr;
    }

    /* Migrates DB from installed to target version, based on migrations described in this class */
    public function migrateDB():void
    {
        Logger.debug("****************  MIGRATING DB  ****************", this);

        try {
            makeBackupDB();
        }catch(error:Error){
            var errorMsg:String = "Could't backup database before migration.";
            Logger.error("migrateDB(): " + errorMsg + " database : " + _currDBFile.nativePath + " backup target: " + _backupDBFile.nativePath + " " +  error, this);
            throw new DatabaseMigrationError(errorMsg);
        }

        var success:Boolean = runMigrations();

        if (success)
        {
            Logger.debug("All migrations complete. success: " + success, this);
        }
        else
        {
            errorMsg = 	"Couldn't completely update existing database to new version. Please contact the AERCalc administrators. ";
            errorMsg += "Your current database may be in an unusable state. Your old AERCalc database was backed up here: " + _backupDBFile.nativePath;
            throw new DatabaseMigrationError(errorMsg);
        }
    }

    /* Make a backupe of the aercalc.sqlite database */
    private function makeBackupDB():void
    {
        _currDBFile = applicationModel.currProjectDB;

        //copy DB in case something goes wrong
        var backupName:String = "backup.sqlite";
        _backupDBFile = applicationModel.currProjectDir.resolvePath(ApplicationModel.AERCALC_DB_SUBDIR);

        if (!_backupDBFile.exists)
        {
            _backupDBFile.createDirectory();
        }
        _backupDBFileName = _currDBFile.name + "." + new Date().getTime() + ".bk";
        _backupDBFile = _backupDBFile.resolvePath(_backupDBFileName);
        Logger.debug("current db path: " + _currDBFile.nativePath, this);
        _currDBFile.copyTo(_backupDBFile);
        Logger.debug("backed up to : " + _backupDBFile.nativePath, this);
    }

    /* Run all migrations stored in this class */
    private function runMigrations():Boolean
    {
        Logger.debug("runMigrations()", this);

        var installedDBVersion:uint = dbManager.getDBVersion();
        if (installedDBVersion < targetDBVersion)
        {
			
			//Before running migrations try to attach to a distribution DB
			try {
				var conn:SQLConnection = dbManager.sqlConnection;
				var distDB:File = File.applicationDirectory.resolvePath("db/aercalc.sqlite");
				conn.attach("distributionDB",distDB);
			}
			catch(error:Error){
				var msg:String = "Couldn't attach to distribution db";
				Logger.error(msg, this);
				return false;
			}
			
            //Perform all migrations with version greater than installedDBVersion
            var numMigrations:int = _migrationsArr.length;
            for (var migrationIndex:int=0;migrationIndex<numMigrations;migrationIndex++)
            {
                var migration:BaseMigration = _migrationsArr[migrationIndex] as BaseMigration;
                migration.migrationManager = this;

                if (migration.version > installedDBVersion)
                {
                    Logger.debug("BaseMigration " + migration.version + " description : " + migration.description, this);
                    try
                    {
                        if (migration.useTransactions)
                        {
                            dbManager.sqlConnection.begin();
                        }
                        migration.migrate(dbManager);
                        dbManager.setDBVersion(migration.version);
                        if (migration.useTransactions)
                        {
                            dbManager.sqlConnection.commit();
                        }
                        Logger.debug("Database migrated to version " + migration.version);
                    }
                    catch(err:Error)
                    {
                        //This is bad
                        if (migration.useTransactions)
                        {
                            dbManager.sqlConnection.rollback();
                        }
                        Logger.error("MIGRATION ERROR!!!! Migration " + migration.version + " failed. Error:" + err);
                        return false;
                    }
                }
            }

        }
        else
        {
            Logger.debug("current DB Version is not less than latestVersion. Not running migrations.", this);
        }
        return true;

    }
}
}
