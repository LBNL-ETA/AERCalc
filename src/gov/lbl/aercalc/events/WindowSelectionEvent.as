package gov.lbl.aercalc.events
{
import flash.events.Event;

public class WindowSelectionEvent extends Event {

    public static const WINDOWS_SELECTED:String = "windowsSelected";

    public var selectedItems:Array;

    public function WindowSelectionEvent(type:String, bubbles:Boolean = true, cancelable:Boolean = false) {
        super(type, bubbles, cancelable);
    }

    public override function clone():Event {
        var evt:WindowSelectionEvent = new WindowSelectionEvent(type);
        evt.selectedItems = selectedItems;
        return evt;
    }
}
}


