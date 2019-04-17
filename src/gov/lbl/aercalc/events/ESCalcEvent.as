package gov.lbl.aercalc.events
{
	
	import flash.events.Event;
	import flash.filesystem.File;
	
	import mx.collections.ArrayCollection;
	
	public class ESCalcEvent extends Event
	{
		public static const RUN_ESCALC:String = "runESCalc"
		public static const RUN_ESCALC_COMPLETE:String = "runESCalcComplete"		
		public static const RUN_ESCALC_FAILED:String = "runESCalcFailed"
		public static const RUN_ESCALC_CANCELLED:String = "runESCalcCanceled"
		
		public var success:Boolean 
		public var hotOutputFile:File;
		public var coldOutputFile:File;		

		
		public function ESCalcEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}