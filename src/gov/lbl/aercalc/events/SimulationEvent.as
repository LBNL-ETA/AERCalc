package gov.lbl.aercalc.events
{
    import flash.events.Event;

    public class SimulationEvent extends Event
    {
        public static const START_SIMULATION:String = "startSimulation";
        public static const STOP_SIMULATION:String = "stopSimulation";
		public static const SIMULATION_COMPLETE:String = "simulationComplete";
        public static const SIMULATION_STATUS:String = "simulationStatus";

        public var selectedItems:Array;
        public var statusMessage:String;

        public function SimulationEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false)
        {
            super(type, bubbles, cancelable);
        }
    }
}