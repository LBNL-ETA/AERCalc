package gov.lbl.aercalc.view.components
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;
	
	import mx.core.FlexGlobals;
	import mx.core.IFlexDisplayObject;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	
	[Event(name="close", type="mx.events.CloseEvent")]
	[Event(name="show", type="mx.events.FlexEvent")]
	public class PopupDisplay extends EventDispatcher
	{
		public function PopupDisplay()
		{
		}
		
		private var _popup:Class;
		
		public function get popup():Class
		{
			return _popup;
		}
		
		public function set popup(value:Class):void
		{
			_popup = value;
			FlexGlobals.topLevelApplication.callLater(commitProperties);
		}
		
		
		public var instance:IFlexDisplayObject;
		
		private var _display:Boolean = false;
		private var _proposedDisplay:Boolean = false;
		
		public var modal:Boolean = true;
		public var center:Boolean = false;
		
		public function get display():Boolean
		{
			return _proposedDisplay;
		}
		
		public function set display(value:Boolean):void
		{
			if(_proposedDisplay != value)
			{
				_proposedDisplay = value;
				FlexGlobals.topLevelApplication.callLater(commitProperties);
			}
		}
		
		
		protected function commitProperties():void
		{
			if (_display != _proposedDisplay)
			{
				if (_display && instance)
				{
					PopUpManager.removePopUp(instance);
				}
				_display = _proposedDisplay;
				if (_display && popup)
				{
					var init:Boolean = false;
					if (instance == null)
					{
						init = true;
						instance = new popup;
						instance.addEventListener(CloseEvent.CLOSE, dispatchEvent);
					}
					PopUpManager.addPopUp(instance, FlexGlobals.topLevelApplication as DisplayObject, modal);
					if (center == true)
						PopUpManager.centerPopUp(instance);
					else
					{
						var offset:Number = 20;
						var scene:DisplayObject = FlexGlobals.topLevelApplication as DisplayObject;
						if (init)
						{
							instance.x = scene.width - instance.width - offset;
							instance.y = offset;
						}
						else
						{
							var stageRect:Rectangle = new Rectangle(0, 0, scene.width, scene.height);
							var bounds:Rectangle = new Rectangle(instance.x, instance.y, instance.width, instance.height);
							if (bounds.left + offset > stageRect.right)
								instance.x = stageRect.right - bounds.width - offset;
							if (bounds.right - offset < stageRect.left)
								instance.x = offset;
							if (bounds.top + offset > stageRect.bottom)
								instance.y = stageRect.bottom - bounds.height - offset;
							if (bounds.bottom - offset < stageRect.top)
								instance.y = offset;
							if (instance.y  < 0)
								instance.y = 0;
						}
					}
					dispatchEvent(new FlexEvent(FlexEvent.SHOW));
				}
			}
		}
		
	}
}
