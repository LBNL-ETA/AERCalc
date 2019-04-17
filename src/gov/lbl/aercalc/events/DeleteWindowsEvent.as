
package gov.lbl.aercalc.events {

import flash.events.Event;

import gov.lbl.aercalc.model.domain.WindowVO;

import mx.collections.ArrayCollection;

public class DeleteWindowsEvent extends Event{

        public static const DELETE_WINDOWS:String = "deleteWindows";
        public static const DELETE_WINDOWS_ERROR:String = "deleteWindowsError";
        public static const DELETE_WINDOWS_COMPLETE:String = "deleteWindowsComplete";

        //Array of windowVOs that should be deleted
        public var selectedItems:Array;

        //Array of windowVO ids that were deleted.
        public var deletedWindowIDsArr:Array;

        //Id of first windowVOs that couldn't be deleted.
        public var deleteErrorWindowID:uint;

        public function DeleteWindowsEvent(type:String, bubbles:Boolean = true, cancelable:Boolean = false)
        {
            super(type, bubbles, cancelable);
        }

        public override function clone():Event
        {
            var appEvent:DeleteWindowsEvent = new DeleteWindowsEvent(type);
            appEvent.selectedItems = selectedItems;
            appEvent.deletedWindowIDsArr = deletedWindowIDsArr;
            appEvent.deleteErrorWindowID = deleteErrorWindowID;
            return  appEvent;
        }


}

}
