package gov.lbl.aercalc.view.components.menu
{
    import flash.events.ContextMenuEvent;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IEventDispatcher;
    import flash.events.MouseEvent;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;

    import mx.collections.IList;
    import mx.events.CollectionEvent;
    import mx.events.CollectionEventKind;
    import mx.events.FlexNativeMenuEvent;
    import mx.events.PropertyChangeEvent;

    [Event(name="itemClick", type="mx.events.FlexNativeMenuEvent")]
    public class DataContextMenu extends EventDispatcher
    {
        public function DataContextMenu()
        {
        }

        private var _contextMenu:ContextMenu = new ContextMenu();

        public function get contextMenu():ContextMenu
        {
            return _contextMenu;
        }

        private var _dataProvider:IList;

        public function get dataProvider():IList
        {
            return _dataProvider;
        }

        public function set dataProvider(value:IList):void
        {
            if (_dataProvider != value)
            {
                _contextMenu.removeAllItems();
                if (_dataProvider)
                {
                    _dataProvider.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onChange);
                }
                _dataProvider = value;
                if (_dataProvider)
                {
                    addItems(_dataProvider.toArray(), 0);
                    _dataProvider.addEventListener(CollectionEvent.COLLECTION_CHANGE, onChange);
                }
            }
        }

        private function onChange(event:CollectionEvent):void
        {
            switch (event.kind)
            {
                case CollectionEventKind.ADD:
                    addItems(event.items, event.location);
                    break;
                case CollectionEventKind.UPDATE:
                    updateItems(event.items);
                    break;
                default:
                    throw new Error("Unhandled collection change event.");
            }
        }

        private function addItems(items:Array, index:int):void
        {
            var showSeparator:Boolean = false;
            for (var i:int = 0; i < items.length; i++)
            {
                var data:Object = items[i];
                var isSeparator:Boolean = data.type == "separator";
                var contextItem:ContextMenuItem = new ContextMenuItem(data.label, showSeparator, data.enabled);
                contextItem.visible = data.visible && !isSeparator;
                contextItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onContextMenuItem, false, 0, true);
                _contextMenu.addItemAt(contextItem, index + i);
                showSeparator = isSeparator;
            }
        }

        private function onContextMenuItem(event:ContextMenuEvent):void
        {
            var target:ContextMenuItem = event.target as ContextMenuItem;
            var index:int = _contextMenu.getItemIndex(target);
            var data:Object = _dataProvider.getItemAt(index);
            var menuEvent:FlexNativeMenuEvent =
                    new FlexNativeMenuEvent(FlexNativeMenuEvent.ITEM_CLICK, false, false, _contextMenu, target, data, data.label, index);
            dispatchEvent(menuEvent);

            if(data is IEventDispatcher)
                (data as IEventDispatcher).dispatchEvent(new Event(MouseEvent.CLICK));
        }


        private function updateItems(items:Array):void
        {
            for each(var event:PropertyChangeEvent in items)
            {
                var data:Object = event.target;
                var isSeparator:Boolean = data.type == "separator";
                var index:int = _dataProvider.getItemIndex(data);
                var contextItem:ContextMenuItem = _contextMenu.getItemAt(index) as ContextMenuItem;
                contextItem.label = data.label;
                contextItem.enabled = data.enabled;
                contextItem.visible = data.visible && !isSeparator;
            }
        }
    }
}