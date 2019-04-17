package gov.lbl.aercalc.controller
{
	
import flash.events.IEventDispatcher;
import gov.lbl.aercalc.constants.Commands;
import gov.lbl.aercalc.events.ApplicationEvent;
import gov.lbl.aercalc.events.ExportEvent;
import gov.lbl.aercalc.events.FileEvent;
import gov.lbl.aercalc.events.MenuEvent;
import gov.lbl.aercalc.events.WindowSelectionEvent;
import gov.lbl.aercalc.model.ApplicationModel;
import gov.lbl.aercalc.model.LibraryModel;
import gov.lbl.aercalc.model.MenuModel;
import gov.lbl.aercalc.model.settings.AppSettings;



public class MenuController
	{


		
		[Dispatcher]
		public var dispatcher:IEventDispatcher;
		
		[Inject]
		public var settings:AppSettings;

		[Inject]
		public var libraryModel:LibraryModel;

		[Inject]
		public var applicationModel:ApplicationModel;

		[Inject]
		public var menuModel:MenuModel;
		

		public function MenuController()
		{

		}


		[EventHandler(event="WindowSelectionEvent.WINDOWS_SELECTED")]
		public function onWindowsSelected(event:WindowSelectionEvent):void {
			var windowsAreSelected:Boolean = event.selectedItems && event.selectedItems.length > 0;
			menuModel.simulateSelectedEnabled = windowsAreSelected;
			menuModel.simulateAllEnabled = !windowsAreSelected;
		}


		[EventHandler(event="MenuEvent.MENU_COMMAND")]
		public function onMenuCommand(event:MenuEvent):void
		{
			var cmd:String = event.command;
			if (applicationModel.menuEnabled == false) return;

			switch (cmd)
			{
				case Commands.ABOUT:
					var aboutEvent:ApplicationEvent = new ApplicationEvent(ApplicationEvent.SHOW_DIALOG);
					aboutEvent.dialogID = "about";
					dispatcher.dispatchEvent(aboutEvent);
					break;

				case Commands.PREFERENCES:
					var prefEvent:ApplicationEvent = new ApplicationEvent(ApplicationEvent.SHOW_DIALOG);
					prefEvent.dialogID = "preferences";
					dispatcher.dispatchEvent(prefEvent);
					break;

				case Commands.EXPORT_WINDOWS:
					var exportEvent:ExportEvent = new ExportEvent(ExportEvent.ON_EXPORT_WINDOWS);
                    dispatcher.dispatchEvent(exportEvent);
                    break;

				case Commands.IMPORT_W7_WINDOWS:
					dispatcher.dispatchEvent(new ApplicationEvent(ApplicationEvent.SHOW_IMPORT_W7_WINDOWS_VIEW));
					break;

				case Commands.QUIT_APPLICATION:
					dispatcher.dispatchEvent(new ApplicationEvent(ApplicationEvent.QUIT));
					break;

				case Commands.FILE_OPEN:
					dispatcher.dispatchEvent(new ApplicationEvent(ApplicationEvent.ON_LOAD_PROJECT));
					break;

                case Commands.FILE_SAVE_AS:
                    dispatcher.dispatchEvent(new ApplicationEvent(ApplicationEvent.ON_PROJECT_SAVE_AS));
                    break;

			}
			
		}
		
	}
}