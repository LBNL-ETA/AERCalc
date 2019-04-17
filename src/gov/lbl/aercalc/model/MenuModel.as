package gov.lbl.aercalc.model
{
	import mx.collections.ArrayCollection;
	import mx.events.PropertyChangeEvent;
	
	public class MenuModel
	{
		public function MenuModel()
		{
		}
		
		[Bindable]
		public var hasOpenProject:Boolean = false;
		
		[Bindable]
		public var menuEnabled : Boolean = true;

		[Bindable]
		public var simulateAllEnabled : Boolean = true;

		[Bindable]
		public var simulateSelectedEnabled : Boolean = true;
			
		private var _mainMenu:ArrayCollection;
		public function set mainMenu(value:ArrayCollection):void
		{
			_mainMenu = value;
		}
		public function get mainMenu():ArrayCollection
		{
			return _mainMenu;
		}
		
	}
}


