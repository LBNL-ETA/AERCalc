package gov.lbl.aercalc.events
{
	import flash.events.Event;


	public class SimulationErrorEvent extends Event
	{
		public static const SIMULATION_ERROR:String ="energyPlusSimulationError"
		
		public var errorMessage:String
		
		public function SimulationErrorEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}