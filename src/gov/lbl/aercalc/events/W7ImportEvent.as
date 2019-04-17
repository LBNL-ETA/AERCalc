package gov.lbl.aercalc.events
{
import flash.events.Event;

import gov.lbl.aercalc.model.domain.WindowVO;

public class W7ImportEvent extends Event
{
    public static const W7_WINDOW_IMPORTED:String = "w7WindowImported";

    public var window:WindowVO;

    public function W7ImportEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false)
    {
        super(type, bubbles, cancelable);
    }
}
}