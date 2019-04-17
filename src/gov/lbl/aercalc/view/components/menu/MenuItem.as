package gov.lbl.aercalc.view.components.menu
{
    [DefaultProperty("children")]
    [Event(name="click", type="flash.events.Event")]
    public class MenuItem
    {
		public var menuID:String = ""; 	//use this to identify nodes for menu items that change, e.g. recent document
		public var prop:String = ""; 	//use this to send a property for a command, e.g. recent document index

        [Bindable]
        public var label:String;

        private var _children:Array;

        [Bindable]
        public var enabled:Boolean = true;

        [Bindable]
        public var visible:Boolean = true;

        [Bindable]
        public var toggled:Boolean = false;

        public var type:String;
        public var command:String;
        public var key:String;
        public var controlKey:Boolean = true;
        public var cmdKey:Boolean = false;
        public var altKey:Boolean = false;
        public var shiftKey:Boolean = false;

        public function get children():Array
        {
            return _children;
        }

        public function set children(value:Array):void
        {
            _children = value;
        }

    }
}