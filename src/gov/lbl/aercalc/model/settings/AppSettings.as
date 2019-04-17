package gov.lbl.aercalc.model.settings
{
    import flash.events.IEventDispatcher;    
    import mx.logging.LogEventLevel;
	import mx.collections.ArrayList;
    
    [RemoteClass]
    [XmlClass(alias="settings")]
    public class AppSettings
    {
		[Bindable]
		[XmlElement]
		public var logEventLevel:int = LogEventLevel.DEBUG;

        /* Path to WINDOW7 database to use for imports */
        [Bindable]
        [XmlElement]
        public var lblWindowDBPath:String  = "";


        /* Date and time string for last calculation started by user */
        [Bindable]
        [XmlElement]
        public var lastCalculated:String  = "";


        /* Precision for reporting EPC and EPH. */
        [Bindable]
        [XmlElement]
        public var epPrecision:Number  = 0;

        /* Show the ID column in the grid */
        /* We may replace this later with a more
           general show/hide function for all columns...
          */

        [Bindable]
        [XmlElement]
        public var showIDColumn:Boolean  = false;
		
		[Bindable]
		[XmlElement]
		public var keepIntermediateFiles:Boolean  = false;

        [Dispatcher]
        public var dispatcher : IEventDispatcher;

        public function AppSettings()
        {
        }

      
    }
}
