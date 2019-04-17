package gov.lbl.aercalc.events
{
import flash.events.Event;
import flash.filesystem.File;

public class FileEvent extends Event
{

    public static const PROJECT_SAVE_AS_DIRECTORY_SELECTED:String = "gov.lbl.aercalc.fileManager.project_save_as_directory_selected";
    public static const INVALID_PROJECT_SAVE_AS_DIRECTORY_SELECTED:String = "gov.lbl.aercalc.fileManager.invalid_project_save_as_directory_selected";

    public static const PROJECT_DIRECTORY_OPENED:String = "gov.lbl.aercalc.fileManager.project_directory_opened";
    public static const INVALID_PROJECT_DIRECTORY:String = "gov.lbl.aercalc.fileManager.invalid_project_directory";

    public var targetProjectDirectory:File;
    public var targetDBFile:File;


    public var msg:String = "";

    public function FileEvent(type : String, bubbles : Boolean = true, cancelable : Boolean = false)
    {
        super(type, bubbles, cancelable);
    }
}
}


