package gov.lbl.aercalc.controller
{

    import gov.lbl.aercalc.events.ApplicationEvent;
    import gov.lbl.aercalc.model.ImportModel;
    import gov.lbl.aercalc.model.SimulationModel;
    import gov.lbl.aercalc.view.dialogs.AboutWindow;
    import gov.lbl.aercalc.view.settings.PreferencesDialog;
    import org.swizframework.controller.AbstractController;

import spark.components.Alert;

public class DialogsController extends AbstractController
    {

        [Inject]
        public var simulationModel:SimulationModel;

        [Inject]
        public var importModel:ImportModel;

        public function DialogsController()
        {

        }

        [EventHandler("ApplicationEvent.SHOW_DIALOG")]
        public function showAppDialog(event:ApplicationEvent):void
        {

            if (simulationModel.simulationInProgress){
                Alert.show("Cannot change preferences while simulation is in progress", "Simulation In Progress.");
                return;
            }
            if (importModel.currentState!=""){
                Alert.show("Cannot change preferences while import is in progress", "Simulation In Progress.");
                return;
            }

            switch(event.dialogID)
            {
                case "preferences":
                    new PreferencesDialog().show();
                    break;

                case "about":
                    new AboutWindow().show();
                    break;
            }
        }

    }
}