package gov.lbl.aercalc.events
{
	import flash.events.Event;
	
	public class SettingsEvent extends Event
	{
		public static const SETTINGS_CHANGED:String = "settingsChanged";
		
		public function SettingsEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}