package gov.lbl.aercalc.events
{
import flash.events.Event;

public class UnitsEvent extends Event
{
    public static const UNITS_CHANGED:String = "unitsChanged";

    public var units:String;

    public function UnitsEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false)
    {
        super(type, bubbles, cancelable);
    }
}
}