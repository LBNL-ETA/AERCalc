package gov.lbl.aercalc.events
{
	
	import flash.events.Event;
	import flash.filesystem.File;
	
	import mx.collections.ArrayCollection;
	
	public class EnergyPlusEvent extends Event
	{
		public static const RUN_EPLUS_COMPLETE:String = "runEnergyPlusComplete"		
		public static const RUN_EPLUS_FAILED:String = "runEnergyPlusFailed"
		public static const RUN_EPLUS_CANCELLED:String = "runEnergyPlusCanceled"
		
		public var success:Boolean; 
		public var energyPlusFiles:ArrayCollection;
		public var shadeType:String;
		
		public function EnergyPlusEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}