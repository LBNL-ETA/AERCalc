package gov.lbl.aercalc.events
{
import flash.events.Event;
import flash.filesystem.File;

public class DBEvent extends Event
{
    public static const DB_OPEN_COMPLETE:String = "gov.lbl.aercalc.dbEvent.db_open_complete";
    public static const DB_OPEN_FAILED:String = "gov.lbl.aercalc.dbEvent.db_open_failed";

    public var msg:String = "";

    public function DBEvent(type : String, bubbles : Boolean = true, cancelable : Boolean = false)
    {
        super(type, bubbles, cancelable);
    }
}
}


