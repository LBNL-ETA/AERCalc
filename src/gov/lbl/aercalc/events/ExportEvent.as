package gov.lbl.aercalc.events {

import flash.events.Event;

import mx.collections.ArrayCollection;

public class ExportEvent extends Event
{
    /* User requested window export */
    public static const ON_EXPORT_WINDOWS:String = "gov.lbnl.aercalc.on_export_windows";

    /* Start actual export process (data has been arranged by PM) */
    public static const DO_EXPORT_WINDOWS:String = "gov.lbnl.aercalc.do_export_windows";

    /* Export has been completed and file saved and closed. */
    public static const EXPORT_WINDOWS_COMPLETE:String = "gov.lbnl.aercalc.export_windows_complete";

    public var exportRows:ArrayCollection;

    public function ExportEvent(type:String, bubbles:Boolean = true, cancelable:Boolean = false)
    {
        super(type, bubbles, cancelable);
    }

    public override function clone():Event
    {
        var appEvent:ExportEvent = new ExportEvent(type);
        appEvent.exportRows = exportRows;
        return  appEvent;
    }
}
}
