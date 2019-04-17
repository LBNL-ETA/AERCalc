
package gov.lbl.aercalc.events {

    import flash.events.Event;

    public class ApplicationEvent extends Event
    {

        public static const QUIT:String = "gov.lbl.aercalc.application.quitApplication";

        //Quitting is launched by the application controller just before it quites the app.
        public static const QUITTING:String = "gov.lbl.aercalc.application.quittingApplication";

        public static const SHOW_DIALOG:String = "gov.lbl.aercalc.application.show_dialog";

        public static const SHOW_IMPORT_W7_WINDOWS_VIEW:String = "gov.lbl.aercalc.application.show_import_w7_windows_view";

        public static const ON_LOAD_PROJECT:String =  "gov.lbl.aercalc.application.on_load_project";
        public static const LOADING_PROJECT:String = "gov.lbl.aercalc.application.loading_project";
        public static const PROJECT_LOADED:String = "gov.lbl.aercalc.application.project_loaded";
        public static const PROJECT_LOAD_FAILED:String = "gov.lbl.aercalc.application.project_load_failed";

        public static const ON_PROJECT_SAVE_AS:String =  "gov.lbl.aercalc.application.on_project_save_as";
        public static const PROJECT_SAVING_AS:String = "gov.lbl.aercalc.application.saving_project_as";
        public static const PROJECT_SAVED_AS:String = "gov.lbl.aercalc.application.project_saved_as";
        public static const PROJECT_SAVE_AS_FAILED:String = "gov.lbl.aercalc.application.project_save_as_failed";


        public var msg:String;
        public var dialogID:String;

        public function ApplicationEvent(type:String, bubbles:Boolean = true, cancelable:Boolean = false)
        {
            super(type, bubbles, cancelable);
        }

        public override function clone():Event
        {
            var appEvent:ApplicationEvent = new ApplicationEvent(type);
            appEvent.dialogID = dialogID;
            return  appEvent;
        }
    }
}
