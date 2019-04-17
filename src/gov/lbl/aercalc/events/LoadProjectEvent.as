
package gov.lbl.aercalc.events {

import flash.events.Event;
import flash.filesystem.File;

import mx.collections.ArrayCollection;

public class LoadProjectEvent extends Event
{
    /* Load a new database*/
    public static const LOAD_PROJECT:String = "gov.lbnl.aercalc.load_project";

    public var targetProjectDirectory:File;
    public var dbFile:File;

    public function LoadProjectEvent(type:String, bubbles:Boolean = true, cancelable:Boolean = false)
    {
        super(type, bubbles, cancelable);
    }

    public override function clone():Event
    {
        var appEvent:LoadProjectEvent = new LoadProjectEvent(type);
        appEvent.targetProjectDirectory = targetProjectDirectory;
        appEvent.dbFile = dbFile;
        return  appEvent;
    }
}
}
