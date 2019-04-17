package gov.lbl.aercalc.model {
import gov.lbl.aercalc.model.domain.WindowVO;
import mx.collections.ArrayList;
import gov.lbl.aercalc.view.dialogs.SimulationProgressDialog;

public class SimulationModel {

    // windowVO states: These are the states a windowVO can be in with regards to a simulation.
    public static const SIMULATION_STATUS_INPROGRESS:String = "simulationStatusInProgress";
    public static const SIMULATION_STATUS_COMPLETE:String = "simulationStatusComplete";
    public static const SIMULATION_STATUS_FAILED:String = "simulationStatusFailed";

    // temporary array to hold user selected window objects that should be simulated.
    public var selectedWindowsAL:ArrayList = new ArrayList;

    // What does this flag do?
    public var doWarnings:Boolean = true;

    // Indicates if entire simulation process is underway or not
    // Other controllers and PMs might want to know this before trying
    // something (e.g. a delete)
    public var simulationInProgress:Boolean = false;

    // Index of current window being simulated
    public var currWindowIndex:int = 0;

    // Actual VO of window being simulated
    public var currSimulationWindow:WindowVO;

    // Progress dialog for simulation process
    public var progressDialog:SimulationProgressDialog = new SimulationProgressDialog();

    public function SimulationModel() {
    }

    public function getNumWindows():int {
        return selectedWindowsAL.length;
    }
}
}