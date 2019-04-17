package gov.lbl.aercalc.controller {

import flash.events.IEventDispatcher;
import flash.filesystem.File;

import gov.lbl.aercalc.business.FileManager;
import gov.lbl.aercalc.error.InvalidProjectDirectoryError;
import gov.lbl.aercalc.error.MissingBSDFDirectoryError;
import gov.lbl.aercalc.error.MissingSQLiteFileError;
import gov.lbl.aercalc.events.FileEvent;
import gov.lbl.aercalc.events.LoadProjectEvent;
import gov.lbl.aercalc.model.ImportModel;
import gov.lbl.aercalc.model.SimulationModel;
import gov.lbl.aercalc.util.Logger;

import spark.components.Alert;

public class FileController {

    /* This controller class manages the opening
       and saving of 'files'...which really means
       a AERCalc database. It also checks for
       and makes note of which, if any, helper
       .bsdf files are available, as each product
       row in a database should have a related bsdf file
       in a bsdf folder next to the .sqlite database.

       See the docs/ directory for more details.

     */

    [Inject]
    public var simulationModel:SimulationModel;

    [Inject]
    public var fileManager:FileManager;

    [Inject]
    public var importModel:ImportModel;

    [Dispatcher]
    public var dispatcher:IEventDispatcher;

    public function FileController() {
    }



    /* Save the current database and related BSDF files (the project)
     * into a new directory.
      * */
    public function onSaveAs(event:FileEvent):void {

        //Do context check to make sure we can open a new file
        if (importModel.isImportInProgress()){
            Alert.show("Cannot save project while import is in progress.", "Warning");
            return;
        }

        if (simulationModel.simulationInProgress){
            Alert.show("Cannot open new project while simulation is in progress.", "Warning");
            return;
        }

        // Allow user to select a directory to save to

    }


}
}
