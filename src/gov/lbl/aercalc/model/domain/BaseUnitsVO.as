package gov.lbl.aercalc.model.domain
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import gov.lbl.aercalc.model.ApplicationModel;
	import gov.lbl.aercalc.util.Logger;
	
	public class BaseUnitsVO extends EventDispatcher
	{
		public function BaseUnitsVO()
		{
		}
		
		
		
		/** Gets the core SI value for an attribute */
		[Transient]
		public function getSIValue(propName:String):Number
		{
			if (this["_"+propName]!=null)
			{
				return this["_"+propName]
			}
			else
			{
				return 0				
				Logger.error("#AERCalcVO: setSIValue() can't get property : " + propName + " on class ")
			}
		}
		
		
		/** Sets the core SI value for an attribute */
		
		[Transient]
		public function setSIValue(propName:String, value:Number):void
		{
			
			if (this["_"+propName]!=null)
			{
				this["_"+propName]=value
				dispatchEvent(new Event("propertyChange"));
			}
			else
			{
				Logger.error("#AERCalcVO: setSIValue() can't set property : " + propName )
			}
		}
		
		
		
		[Transient]
		public function get currUnits():String
		{
			return ApplicationModel.currUnits //man what's the best thing to do here...I think hitting a static class property is quickest.
		}	
	}
}