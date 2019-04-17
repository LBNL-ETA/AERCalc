package gov.lbl.aercalc.view.components.menu
{
    import gov.lbl.aercalc.util.CapabilitiesUtils;
    
    import flash.display.NativeMenuItem;
    import flash.events.IEventDispatcher;
    import flash.ui.Keyboard;
    import flash.utils.Dictionary;
    
    import mx.collections.IList;
    import mx.controls.FlexNativeMenu;
    import mx.events.CollectionEvent;
    import mx.events.CollectionEventKind;
    import mx.events.PropertyChangeEvent;

    public class DataNativeMenu extends FlexNativeMenu
    {
        public function DataNativeMenu()
        {
            keyEquivalentField = "key";
            keyEquivalentModifiersFunction = keyEquivalentModifiers;

            isWin = CapabilitiesUtils.isWindows;
            isMac = CapabilitiesUtils.isMac;
        }

        private var isWin:Boolean = false;
        private var isMac:Boolean = false;

        protected function keyEquivalentModifiers(item:Object):Array
        {
            var result:Array = new Array();

            var keyEquivField:String = keyEquivalentField;
            var altKeyField:String;
            var controlKeyField:String;
            var shiftKeyField:String;
            if (item is XML)
            {
                altKeyField = "@altKey";
                controlKeyField = "@controlKey";
                shiftKeyField = "@shiftKey";
            }
            else if (item is Object)
            {
                altKeyField = "altKey";
                controlKeyField = "controlKey";
                shiftKeyField = "shiftKey";
            }

            if (item[keyEquivField] == null || item[keyEquivField].length == 0)
            {
                return result;
            }

            if (item[altKeyField] != null && item[altKeyField] == true)
            {
                //if (isWin)
                {
                    result.push(Keyboard.ALTERNATE);
                }
            }

            var val:Boolean = false
            val = item[controlKeyField]

            if (item[controlKeyField] != null && item[controlKeyField] == true)
            {
                if (isMac)
                {
                    result.push(Keyboard.COMMAND);
                }
                else
                {
                    result.push(Keyboard.CONTROL);
                }
            }

            if (item[shiftKeyField] != null && item[shiftKeyField] == true)
            {
                result.push(Keyboard.SHIFT);
            }

            return result;
        }


        private var doListen:Boolean = true;

        protected override function commitProperties():void
        {
            super.commitProperties();
            if (dataProvider is IList)
            {
                dataToItemsMap = new Dictionary();
                var list:IList = dataProvider as IList;
                if(list is IEventDispatcher)
                    (list as IEventDispatcher).addEventListener(CollectionEvent.COLLECTION_CHANGE, onRootCollectionChange);
                for (var i:int = 0; i < list.length; i++)
                {
                    var child:Object = list.getItemAt(i);
                    var childMenuItem:NativeMenuItem = nativeMenu.items[i];
                    listenForMenuChanges(childMenuItem, child, doListen);
                }
                doListen = false;
            }
        }

        private function onRootCollectionChange(event:CollectionEvent):void
        {
            //HACK - Force reset because FlexNativeMenu does not listen for Replace
            if(event.kind == CollectionEventKind.REPLACE)
            {
                var resetEvent:CollectionEvent = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE, false, false, CollectionEventKind.RESET);
                (event.target as IEventDispatcher).dispatchEvent(resetEvent);
            }
        }

        private var dataToItemsMap:Dictionary;

        public function listenForMenuChanges(item:NativeMenuItem, data:Object, listen:Boolean = true):void
        {
            if (data is IEventDispatcher && listen)
            {
                (data as IEventDispatcher).addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, onPropertyChange, false, 0, true);
            }
            dataToItemsMap[data] = item;
            var children:IList = dataDescriptor.getChildren(data) as IList;
            if (children && children.length)
            {
                for (var i:int = 0; i < children.length; i++)
                {
                    var child:Object = children.getItemAt(i);
                    var childMenuItem:NativeMenuItem = item.submenu.items[i];
                    listenForMenuChanges(childMenuItem, child);
                }
            }
        }

        private function onPropertyChange(event:PropertyChangeEvent):void
        {
            var data:Object = event.target;
            var menuItem:NativeMenuItem = dataToItemsMap[data];
            if (menuItem && menuItem.enabled != data.enabled)
            {
                menuItem.enabled = data.enabled;
            }
            if(menuItem && menuItem.checked != data.toggled)
            {
                menuItem.checked = data.toggled;
            }
            //dataProvider.dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE, false, false, CollectionEventKind.RESET));
        }

    }
}