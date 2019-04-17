package gov.lbl.aercalc.events
{
	import flash.events.Event;
	
	public class MenuEvent extends Event
	{
		public static const MENU_COMMAND : String = "menuCommand";
		public static const MENU_ENABLED : String = "menuEnabled";

		public var command : String;
		public var prop : String; 				//extra information about command type
		public var enabled : Boolean = true;
		
		public function MenuEvent(type : String, bubbles : Boolean = true, cancelable : Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}


