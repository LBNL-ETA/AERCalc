package gov.lbl.aercalc.events
{
import flash.events.Event;

public class PrecisionEvent extends Event
{
    public static const PRECISION_CHANGED:String = "precisionChanged";

    public var precision:uint;

    public function PrecisionEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false)
    {
        super(type, bubbles, cancelable);
    }
}
}