package gov.lbl.aercalc.business.migrations
{
import gov.lbl.aercalc.business.MigrationManager;
import gov.lbl.aercalc.business.DBManager;
import gov.lbl.aercalc.util.Logger;

import flash.data.SQLConnection;
import flash.data.SQLStatement;

public class BaseMigration
{

    /*
        Base class for Migrations. Each subclass should
        describe one migration that has to be applied to
        the database to change it's schema to reflect
        the version set in this class.
     */

    public var migrationManager:MigrationManager;

    protected var _version:Number = 0;
    protected var _description:String =  "";
    protected var _userNote:String = "";
    protected var _useTransactions:Boolean = true;

    public function BaseMigration()
    {
    }


    /* If true, use transactions when making changes to db */
    public function get useTransactions():Boolean
    {
        return _useTransactions
    }
    public function set useTransactions(value:Boolean):void
    {
        _useTransactions = value
    }


    /* The version this migration moves the database to */
    public function get version():Number
    {
        return _version
    }
    public function set version(value:Number):void
    {
        _version = value
    }

    /* A basic description of what this migration does */
    public function get description():String
    {
        return _description
    }
    public function set description(value:String):void
    {
        _description = value
    }

    /* A note to display to the end user via the UI */
    public function get userNote():String
    {
        return _userNote
    }
    public function set userNote(value:String):void
    {
        _userNote = value
    }

    /* Base function to run migration */
    public function migrate(db:DBManager):void
    {
        Logger.debug("Beginning migration " + _version, this);

    }

}
}