package gov.lbl.aercalc.view.model {

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.ContextMenuEvent;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IEventDispatcher;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.ui.ContextMenu;
import flash.ui.ContextMenuItem;
import flash.ui.Keyboard;

import gov.lbl.aercalc.model.ApplicationModel;

import mx.collections.ArrayCollection;
import mx.controls.AdvancedDataGrid;
import mx.controls.advancedDataGridClasses.AdvancedDataGridColumn;
import mx.core.FlexGlobals;
import mx.events.AdvancedDataGridEvent;
import mx.events.CloseEvent;
import mx.events.ListEvent;

import spark.components.Alert;
import spark.events.GridItemEditorEvent;

import gov.lbl.aercalc.constants.Commands;
import gov.lbl.aercalc.controller.ExportController;
import gov.lbl.aercalc.controller.LibraryController;
import gov.lbl.aercalc.events.ApplicationEvent;
import gov.lbl.aercalc.events.DeleteWindowsEvent;
import gov.lbl.aercalc.events.ExportEvent;
import gov.lbl.aercalc.events.MenuEvent;
import gov.lbl.aercalc.events.PrecisionEvent;
import gov.lbl.aercalc.events.SimulationEvent;
import gov.lbl.aercalc.events.UnitsEvent;
import gov.lbl.aercalc.events.WindowSelectionEvent;
import gov.lbl.aercalc.model.LibraryModel;
import gov.lbl.aercalc.model.SimulationModel;
import gov.lbl.aercalc.model.domain.WindowVO;
import gov.lbl.aercalc.model.settings.SettingsModel;
import gov.lbl.aercalc.model.settings.VariableSettingsModel;
import gov.lbl.aercalc.util.Logger;
import gov.lbl.aercalc.util.Utils;


public class WindowListViewPM extends EventDispatcher {

	public static const HEADERS_UPDATED:String = "WindowListViewPM.headersUpdated";
	
    [Inject]
    public var settings:SettingsModel;

    [Inject]
    public var varSettings:VariableSettingsModel;

    [Inject]
    public var simulationModel:SimulationModel;
	
	[Inject]
	public var libraryController:LibraryController;

    [Inject]
    public var exportController:ExportController;

    [Bindable]
    public var currentState:String = "default";

    [Inject("libraryModel.windowsAC", bind="true")]
    [Bindable]
    public var windowsAC:ArrayCollection;

    [Inject("settingsModel.appSettings.lastCalculated", bind="true")]
    [Bindable]
    public var lastCalculated:String = "";

    [Bindable]
    public var uFactorHeader:String = "U-factor";

	[Bindable]
	public var airInfiltrationHeader:String = "";
	
	
    [Dispatcher]
    public var dispatcher:IEventDispatcher;
	
	
	[Embed('/assets/img/icons/vb-small.png')]
	public var windowIcon:Class;
	

    protected var selectedItems:Array;
	
	private var cmiSimulate:ContextMenuItem = new ContextMenuItem( "Simulate" );
	private var cmiDelete:ContextMenuItem = new ContextMenuItem( "Delete", true );
	private var cm:ContextMenu = new ContextMenu();


    public function WindowListViewPM() {
    }

    [EventHandler(event="UnitsEvent.UNITS_CHANGED")]
    public function onUnitsChange(event:UnitsEvent):void {
        formatHeaders();
		this.dispatchEvent(new Event(WindowListViewPM.HEADERS_UPDATED));
    }

    /* Listen directly for menu commands. At the moment,
    *  we handle SELECT_ALL and DESELCT_ALL directly in the view,
    *  since those processes need to pass some ADG properties to PM
    *  in order to complete. All other events should be handled here.*/
    [EventHandler(event="MenuEvent.MENU_COMMAND")]
    public function onMenuCommand(event:MenuEvent):void {
        //select all and deselet all are handled directly by the view
        switch (event.command){
            case Commands.DELETE_SELECTED_WINDOWS:
                deleteSelectedWindows();
                break;

        }
    }


    /* Export all visible rows. Don't export child rows if
       parent is collapsed.

       @param openNodes     an object with each open node set as a property. This is
                            generated via.openNodes property of IHierarchicalCollectionView,
                            which ADG implements.
     */
    public function doExportWindows(openNodes:Object):void {

        if (openNodes){
            try {
                // Update model to include which parent rows are showing child rows.
                var numWindows:uint = windowsAC.length;

                //Set all windows to closed and then set windows in openNodes to open
                for (var winIndex:uint = 0; winIndex < numWindows; winIndex++ ){
                    windowsAC[winIndex].isOpen = false;
                }
                for each (var obj:Object in openNodes){
                    obj.isOpen = true;
                }
            } catch (error:Error){
                // We just silently fail here. Not big enough error to ruin user's workflow.
                Logger.error("Couldn't set 'isOpen' property on one or more rows during export. Exception: " + error.toString());
            }
        }

        dispatcher.dispatchEvent(new ExportEvent(ExportEvent.DO_EXPORT_WINDOWS, true));

    }

    [EventHandler(event="PrecisionEvent.PRECISION_CHANGED")]
    public function onPrecisionChanged(event:PrecisionEvent):void {
        this.windowsAC.refresh();
    }
    [EventHandler(event="DeleteWindowsEvent.DELETE_WINDOWS_ERROR")]
    public function onDeleteError(event:DeleteWindowsEvent):void {
        Alert.show("Couldn't delete windows. Error deleting window id " + event.deleteErrorWindowID + ". See log for details.");
    }


    [PostConstruct]
    public function onPostConstruct():void {
    }

    /* Make sure we capture which items are selected if user
       is using arrow keys and shift to select rows
     */
    public function onDGKeyUp(event:KeyboardEvent, selectedItems:Array):void {
        if (event.shiftKey && event.keyCode == Keyboard.UP || event.keyCode == Keyboard.DOWN){
            onDGSelectedItemsChanged(selectedItems);
        }
    }

    public function onDGSelectedItemsChanged(selectedItems:Array):void {
        Logger.debug("onDGSelectedItems()",this);
        this.selectedItems = selectedItems;
        var evt:WindowSelectionEvent = new WindowSelectionEvent(WindowSelectionEvent.WINDOWS_SELECTED);
        evt.selectedItems = selectedItems;
        dispatcher.dispatchEvent(evt);
    }


    public function onRunSimulation(evt:Event):void {

        var numRows:uint = this.selectedItems.length;
        if (numRows == 0) {
            Alert.show("No windows selected");
            return;
        }

        //build an index of parent IDs for following check
        var numOldWINDOWVersionIDs:uint = 0;
        var parentIDsArray:Array = [];
        for (var index:uint = 0; index < numRows; index++) {
            var windowVO:WindowVO = this.selectedItems[index] as WindowVO;
            if (!windowVO.isParent && !windowVO.hasBSDF) {
                Logger.warn("onRunSimulation() Couldn't run simulation. At least one window missing BSDF file. Window: " + windowVO.id + " : " + windowVO.name, this);
                Alert.show("One or more of the selected windows are missing BSDF files. Please re-import each window missing a BSDF file before running a simulation.", "BSDF File Missing");
                return;
            }
            if (!windowVO.isParent && Utils.compareVersions(ApplicationModel.VERSION_WINDOW, windowVO.WINDOWVersion) == Utils.FIRST_ARG_HIGHER) {
                numOldWINDOWVersionIDs++
            }
            if (windowVO.isParent) {
                parentIDsArray.push(windowVO.id);
            }
        }

        //make sure all selected child windows
        //have a selected parent
        for (index = 0; index < numRows; index++) {
            windowVO = this.selectedItems[index] as WindowVO;
            if (windowVO.isChild() && parentIDsArray.indexOf(windowVO.parent_id) < 0) {
                Alert.show("You have selected child Product rows without selecting the related parent row.");
                return;
            }
        }

        if (numOldWINDOWVersionIDs>0){
            var msg:String =    "Note that one or more products selected were imported from older versions of WINDOW. " +
                                "You should re-import these products before simulating. " +
                                "Are you sure you want to continue the simulation?";
            Alert.show(msg, "Warning", Alert.YES | Alert.CANCEL, FlexGlobals.topLevelApplication as Sprite, onConfirmSimulation);
        } else {
            doRunSimulation();
        }
    }

    private function onConfirmSimulation(event:CloseEvent):void {
        if (event.detail == Alert.YES){
            doRunSimulation();
        }
    }

    private function doRunSimulation():void {
        //capture time of most recent sim
        settings.appSettings.lastCalculated = Utils.getCurrentDateTime();

        var event:SimulationEvent = new SimulationEvent(SimulationEvent.START_SIMULATION, true);
        event.selectedItems = this.selectedItems;
        dispatcher.dispatchEvent(event);
    }


    public function onImport():void {
        dispatcher.dispatchEvent(new ApplicationEvent(ApplicationEvent.SHOW_IMPORT_W7_WINDOWS_VIEW, true));
    }


    public function onDeleteWindows(event:Event):void {
        if (!this.selectedItems || this.selectedItems.length == 0) {
            Alert.show("No windows selected");
            return;
        }
        deleteSelectedWindows();
    }


    public function formatHeaders():void {
        uFactorHeader = "U-factor (" + varSettings.getUnits("UvalWinter") + " )";
		airInfiltrationHeader = "AL (" + varSettings.getUnits("Infiltration") + " )";
    }
	
	
	/* 	
	This function formats labels so the relevant 
	columns are blank if the row is a parent.
	*/
	public function windowValueLabelFunction(item:Object, column:AdvancedDataGridColumn):String {
		
		if (item.isParent == false){
			switch(column.dataField){
				case "UvalWinter":
				case "Tvis":
				case "SHGC":
					return Utils.basicFormatter.format(item[column.dataField]);
				case "airInfiltration":
					return Utils.infiltrationFormatter.format(item[column.dataField]);
			}
		}
		
		return "";
	}

	
	// Callback to define which icons to show in grid
	public function myIconFunc(item:Object, depth:int):Class {
		if(depth == 1 && item.isParent)
			// If this is the top-level of the tree, return the icon.
			return windowIcon;
		else
			// If this is any other level, return null.
			return null;
	}

	
	public function createGridContextMenu(adg:AdvancedDataGrid):void {
		//create context menu
		cm.addItem( cmiSimulate );
		cm.addItem( cmiDelete );
		
		cmiSimulate.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, onRunSimulation );
		cmiDelete.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, onDeleteWindows );
		
		adg.contextMenu = cm;
	}


	public function onSelectAll(adg:AdvancedDataGrid):void {
		var arr:Array = [];
		var len:uint = this.windowsAC.length;
		for(var a:uint=0;a<len;a++){  
			arr.push(a);  
		}  
		adg.selectedIndices = arr;
        this.selectedItems = adg.selectedItems;
	}

	
	public function onDeselectAll(adg:AdvancedDataGrid):void {
		adg.selectedIndex = -1;
        this.selectedItems = [];
	}


	/* TODO: Any row-level styling we need in the ADG */
	public function formatGridRow(data:Object, column:AdvancedDataGridColumn):Object {
		
		return null;
	}
	

	public function epLabelFunction(item:Object, column:AdvancedDataGridColumn):String{
        var value:Number = item[column.dataField];
        if (value==0){
            return "";
        }
		return Utils.normalizeEPValue(value);
	}


	/* We need this so we can add isParent to the first row (so we can sort the column)
	but we don't want to actually show the value */
	public function blankLabelFunction(item:Object, column:AdvancedDataGridColumn):String{
		return "";
	}
	
	
	
	
	

    private function deleteSelectedWindows():void {

        if (this.selectedItems.length < 1) {
            Alert.show("No windows selected", "", Alert.OK);
            return;
        }

        // The user could probably not get to this state but do a check just to make sure
        if (simulationModel.simulationInProgress) {
            Alert.show("You can't delete a window while a simulation is in progress", "Not Allowed", Alert.OK);
            return;
        }

        var numWindows:uint = this.selectedItems.length;
        if (numWindows>1){
            var msg:String = "Delete the " + numWindows + " selected rows?"
        } else {
            msg = "Delete the selected row?"
        }

        Alert.show(msg, "Confirm Delete", Alert.YES | Alert.CANCEL, null, onConfirmDelete);
    }

    private function onConfirmDelete(event:CloseEvent):void {
        if (event.detail == Alert.YES) {
            var evt:DeleteWindowsEvent = new DeleteWindowsEvent(DeleteWindowsEvent.DELETE_WINDOWS, true);
            evt.selectedItems = this.selectedItems;
            dispatcher.dispatchEvent(evt);
        }
    }

	
    public function onUserChangeFinished(adg:AdvancedDataGrid, event:AdvancedDataGridEvent, selectedItem:Object):void {
        // User is changing core values so clear out computed values for target windowVO
        // at the moment, *any* user input should cause EPC and EPH to be cleared out,
		// unless the user changes the values but then sets back before focusing out.
        Logger.debug("event.reason: " + event.reason);
        Logger.debug("field: " + field);
		var vo:WindowVO = event.itemRenderer.data as WindowVO;
		var field:String = event.dataField;
		/*
        if (event.reason=="other"){
			return;
		}
		*/

		if (field==null || field==""){
			return;
		}

		if (field=="userID" ){
			//make sure userID doesn't exist already
			var prevUserID:String = vo[field];
			var newUserID:String = event.currentTarget.itemEditorInstance.text;
			if (prevUserID==newUserID){
				return;
			}

			if (newUserID==""){
				vo.userID="";
			} else {
				if (newUserID!=null && newUserID!=""){
					if (checkWindowForSameUserID(this.windowsAC.source, vo.id, newUserID)){
						Alert.show("That user ID already exists. Please choose something unique.");
						vo.userID = prevUserID;
						event.currentTarget.itemEditorInstance.text = prevUserID;
						event.preventDefault();
						return;
					}
				}
			}
			vo.userID = newUserID;
			libraryController.saveWindow(vo);
			//event.stopPropagation();
			return;
		}
		
		//At the moment, the only editable field outside of userID is air infiltration
		//So the following should never be true, but just in case...
		if (field != "airInfiltration"){
			return;
		}
		
		//If the user edited an 'invalidating' field, remove epc and eph values
		var prevValue:String = Utils.infiltrationFormatter.format(vo[field]);
		var newValue:String = Utils.infiltrationFormatter.format(Number(event.currentTarget.itemEditorInstance.text));
		
		if (prevValue != newValue){
			vo.epc = 0;
			vo.eph = 0;
		}
		
		libraryController.saveWindow(vo);
       
    }
	
	
	private function maintainEdit(adg:AdvancedDataGrid, colIndex:int,rowIndex:int):void {
		var editCell:Object = {columnIndex:colIndex, rowIndex:rowIndex};
		adg.editedItemPosition = editCell;
	}


	
	protected function checkWindowForSameUserID(windowsArr:Array, windowID:int, newUserID:String):Boolean{
		for each(var windowVO:WindowVO in windowsArr){
			if (windowVO.children && windowVO.children.length>0){
				if(checkWindowForSameUserID(windowVO.children, windowID, newUserID)){
					return true;
				}
			}
			if (windowVO.userID == newUserID && windowVO.id != windowID){
				return true;
			}
		}
		return false;
	}
	
	
	public function disallowParentRowEdits(event:AdvancedDataGridEvent):void{
		if (event.itemRenderer.data && event.itemRenderer.data.isParent){
            var clickedCol:AdvancedDataGridColumn = AdvancedDataGridColumn(event.currentTarget.columns[event.columnIndex]);
            if (clickedCol.dataField!="userID"){
                event.preventDefault();
            }

		}
	}
	
}
}
