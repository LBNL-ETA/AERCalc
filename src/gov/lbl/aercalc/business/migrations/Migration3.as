package gov.lbl.aercalc.business.migrations
{
import gov.lbl.aercalc.business.DBManager;
import gov.lbl.aercalc.util.Logger;

import flash.data.SQLStatement;

public class Migration3 extends BaseMigration
{

    /* This migration updates the window table to include a column
       for storing a "user ID" for each row. Different users
       may use this for different things, so the only constraint is
       to make sure it's unique.
     */

    public function Migration3()
    {
        version = 3;
        description =  "Add column for user ID, shading system manufacturer, and W7 database version.";
        userNote = description;
    }

    override public function migrate(db:DBManager):void
    {
        super.migrate(db);

        var c:SQLStatement = new SQLStatement();
        c.sqlConnection = db.sqlConnection;

        Logger.debug("Adding a 'userID' column.",this);
        c.text = "ALTER TABLE windows ADD COLUMN 'userID' Text;";
        c.execute();

        Logger.debug("Adding a unique constraint to userID", this);
        c.text = "CREATE UNIQUE INDEX windows_userID ON windows(userID);"

        Logger.debug("Adding a shadingSystemManufacturer column", this);
        c.text = "ALTER TABLE windows ADD COLUMN 'shadingSystemManufacturer' Text;";
        c.execute();

        Logger.debug("Adding W7 Shading System ID column ", this);
        c.text = "ALTER TABLE windows ADD COLUMN 'W7ShdSysID' Text;";
        c.execute();

        Logger.debug("Adding CGDB Version column ", this);
        c.text = "ALTER TABLE windows ADD COLUMN 'cgdbVersion' Text;";
        c.execute();

        // These columns help us track versions of helper files
        // used to import or simulate products

        Logger.debug("Adding AERCalcVersion to track AERCalc version used for simulation", this);
        c.text = "ALTER TABLE windows ADD COLUMN 'AERCalcVersion' Text;";
        c.execute();

        Logger.debug("Adding EPlusVersion to track EnergyPlus version used for simulation", this);
        c.text = "ALTER TABLE windows ADD COLUMN 'EPlusVersion' Text;";
        c.execute();

        Logger.debug("Adding ESCalcVerion to track ESCalcVerion version used for simulation", this);
        c.text = "ALTER TABLE windows ADD COLUMN 'ESCalcVerion' Text;";
        c.execute();

        Logger.debug("Adding WINDOWVersion to track w7 version info used for import", this);
        c.text = "ALTER TABLE windows ADD COLUMN 'WINDOWVersion' Text;";
        c.execute();


    }


}
}