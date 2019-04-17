package gov.lbl.aercalc.business.migrations
{
import gov.lbl.aercalc.business.DBManager;
import gov.lbl.aercalc.util.Logger;

import flash.data.SQLStatement;

public class Migration2 extends BaseMigration
{

    /* This migration updates the window table to include a column
       for storing the origin of the W7 database a window is imported from.
     */

    public function Migration2()
    {
        version = 2;
        description =  "Add column for origin of W7 DB import."
        userNote = description;
    }

    override public function migrate(db:DBManager):void
    {
        super.migrate(db)

        var c:SQLStatement = new SQLStatement();
        c.sqlConnection = db.sqlConnection;

        Logger.debug("updating window table",this)
        c.text = "ALTER TABLE main.windows ADD COLUMN 'WINDOWOriginDB' Text;";
        c.execute();
    }


}
}