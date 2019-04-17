package gov.lbl.aercalc.controller {

import flash.events.IEventDispatcher;
import flash.events.TimerEvent;
import flash.filesystem.File;
import flash.utils.Timer;

import gov.lbl.aercalc.business.DBManager;
import gov.lbl.aercalc.business.EPlusSimulationDelegate;
import gov.lbl.aercalc.business.ESCalcDelegate;
import gov.lbl.aercalc.business.ESCalcResultsLoader;
import gov.lbl.aercalc.error.FileMissingError;
import gov.lbl.aercalc.error.SimulationError;
import gov.lbl.aercalc.error.WindowValidationError;
import gov.lbl.aercalc.events.ApplicationEvent;
import gov.lbl.aercalc.events.SimulationErrorEvent;
import gov.lbl.aercalc.events.SimulationEvent;
import gov.lbl.aercalc.model.ApplicationModel;
import gov.lbl.aercalc.model.LibraryModel;
import gov.lbl.aercalc.model.SimulationModel;
import gov.lbl.aercalc.model.domain.WindowVO;
import gov.lbl.aercalc.util.AboutInfo;
import gov.lbl.aercalc.util.Logger;
import gov.lbl.aercalc.view.dialogs.SimulationProgressDialog;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.events.DynamicEvent;


public class SimulationController {
	
	public static const CALC_FAILED:String = "calculationProcessFailed";
	public static const CALC_FINISHED:String = "calculationProcessFinished";

    [Inject]
    public var libraryModel:LibraryModel;

    [Inject]
    public var simulationModel:SimulationModel;

    [Dispatcher]
    public var dispatcher:IEventDispatcher;
	
	[Inject]
	public var esCalcDelegate:ESCalcDelegate;
	
	[Inject]
	public var ePlusSimulationDelegate:EPlusSimulationDelegate;
	
	[Inject]
	public var eSCalcResultsLoader:ESCalcResultsLoader;	

    [Inject]
    public var dbManager:DBManager;


    public function SimulationController() {
    }


    [PostConstruct]
    public function onPostConstruct():void {
		ePlusSimulationDelegate.addEventListener(EPlusSimulationDelegate.RUN_EPLUS_FINISHED, onEnergyPlusFinished);
		ePlusSimulationDelegate.addEventListener(EPlusSimulationDelegate.RUN_EPLUS_FAILED, onEnergyPlusFailed);
		esCalcDelegate.addEventListener(ESCalcDelegate.RUN_ESCALC_FINISHED, onESCalcFinished);
		esCalcDelegate.addEventListener(ESCalcDelegate.RUN_ESCALC_FAILED, onESCalcFailed);
    }
	
	
	protected function cancelSimulation():void
	{
		ePlusSimulationDelegate.cancel();
		esCalcDelegate.cancel();
		eSCalcResultsLoader.cancel();
        simulationModel.simulationInProgress = false;
		if(simulationModel.progressDialog.progressBar)
		{
			simulationModel.progressDialog.closeDialog();
		}
	}

	
    public function onUserCancel():void {
        //handle user cancel of process
        cancelSimulation();
    }
	

    /*  Begin the process of simulating all selected windows 
	    Other methods in this class will handle iterating through
		each window and reporting on async events or errors.	
	*/
    [EventHandler(event="SimulationEvent.START_SIMULATION")]
    public function startSimulation(event:SimulationEvent):void {

		var dialog:SimulationProgressDialog = simulationModel.progressDialog;
		dialog.setOnCancelCallback(onUserCancel);
        simulationModel.simulationInProgress = true;
        simulationModel.selectedWindowsAL.removeAll();

        //only worry about windows that are 'parent' windows
        var selectedItems:Array = event.selectedItems;
		
		//ADG respects which way a selection is made, but orders items backwards.
		//So we reverse it here.
		selectedItems.reverse();
		
        for (var index:uint=0;index<selectedItems.length;index++){
			var selectedWindow:WindowVO = selectedItems[index];
            if(selectedWindow.isChild()==false){
				selectedWindow.epc = 0;
				selectedWindow.eph = 0;
                simulationModel.selectedWindowsAL.addItem(selectedWindow);
            }
        }
		
		
        simulationModel.currWindowIndex = 0;
        simulationModel.currSimulationWindow = simulationModel.selectedWindowsAL.getItemAt(0) as WindowVO;
        simulationModel.currSimulationWindow.simulationStatus = SimulationModel.SIMULATION_STATUS_INPROGRESS;

		Logger.debug("Starting simulation for window id: " + simulationModel.currSimulationWindow.id + " name: " + simulationModel.currSimulationWindow.name, this);
		
        // Refresh the library's AC, since it's tied to view
        libraryModel.windowsAC.refresh();

        simulationModel.progressDialog.show();
        simulationModel.progressDialog.initProgress(0, 10);

        //wait a sec for the dialog to show before starting simulation
        var t:Timer = new Timer(300,0);
        t.addEventListener(TimerEvent.TIMER, beginSimulationAfterDelay);
        t.start();

    }

	
	/* Validates the window to be simulated and then starts the E+ simulation */
    private function beginSimulationAfterDelay(event:TimerEvent):void{
        var t:Timer = event.target as Timer;
        t.stop();
        t.removeEventListener(TimerEvent.TIMER, beginSimulationAfterDelay);
		doNextSimulation(true);
    }

	
    [EventHandler("SimulationEvent.SIMULATION_STATUS")]
    public function onSimulationStatus(event:SimulationEvent):void {
        simulationModel.progressDialog.setThirdPartyAppStatusMessage(event.statusMessage)
    }
	
	
	/* This method handles errors arriving from the async portion
	   of the simulation process */
	[EventHandler("SimulationErrorEvent.SIMULATION_ERROR")]
	public function onSimulationError(event:SimulationErrorEvent):void {
		Alert.show(event.errorMessage,"Simulation Error");
		Logger.error("Simulation error: " + event.errorMessage, this);
		cancelSimulation();
		return;
	}

	
	/* Try to gracefully stop anything running when user closes app */
    [EventHandler("ApplicationEvent.QUITTING")]
    public function onQuitting(event:ApplicationEvent):void {
		cancelSimulation();
    }

	
	/* Simulate the next window in the sequence */
    protected function doNextSimulation(isFirstIteration:Boolean=false):void {
		
		if(!isFirstIteration){
			simulationModel.currWindowIndex++;
		}
		
        if (simulationModel.currWindowIndex >= simulationModel.getNumWindows()) {
            allSimulationsComplete();
			return;
        }
		
		
        simulationModel.currSimulationWindow = simulationModel.selectedWindowsAL.getItemAt(simulationModel.currWindowIndex) as WindowVO;
		Logger.debug("Starting EPlus simulation for window id: " + simulationModel.currSimulationWindow.id + " name: " + simulationModel.currSimulationWindow.name);
		simulationModel.progressDialog.setProgress(simulationModel.currWindowIndex, simulationModel.getNumWindows());
		
		try{
			validateWindowForSimulation(simulationModel.currSimulationWindow);
		}
		catch(error:WindowValidationError){				
			Logger.error("Invalid scenario. " + error.message,this);
			Alert.show(error.message,"Invalid Scenario");
			cancelSimulation();
			return;
		}
		catch(error:Error){
			Logger.error("Error: " + error.message,this);
			Alert.show(error.message,"Error");
			cancelSimulation();
			return;
		}
			
		//window is valid for simulation. Try starting EPlus simulation and catch and report any errors
		Logger.debug("window " + simulationModel.currSimulationWindow.name + " is valid for simulation. Starting EPlus simulation...", this);
		simulationModel.progressDialog.setStatusMessage("Running Simulation " + (simulationModel.currWindowIndex + 1) + "/" + simulationModel.getNumWindows() + File.lineEnding + simulationModel.currSimulationWindow.name);
		var errorMsg:String = null;
		try {
			ePlusSimulationDelegate.init();
			ePlusSimulationDelegate.runEnergyPlus(simulationModel.currSimulationWindow);
		}
		catch(error:FileMissingError){
			errorMsg = "Couldn't run simulation because a required file is missing. " + error.message;
		}
		catch(error:SimulationError){
			errorMsg = "Error encountered when starting the EnergyPlus simulation. " + error.message;
		}
		catch(error:Error)
		{
			//catchall error. We're not sure what failed in this one...
			errorMsg = "Error running simulation. " + error.errorID + " : " + error.message;
		}

		if (errorMsg){
            Alert.show(errorMsg,"Simulation Error");
            cancelSimulation();
			return;
		}
		
		// At this point the simulation process is async, so watch
		// for events and error events in listener methods defined below...
			
    }

	
	/* All windows have been completed */
	protected function allSimulationsComplete():void {
		simulationModel.selectedWindowsAL.removeAll();
		simulationModel.currWindowIndex = 0;
		simulationModel.progressDialog.closeDialog();
		var msg:DynamicEvent = new DynamicEvent(CALC_FINISHED, true);
		simulationModel.simulationInProgress = false;
		dispatcher.dispatchEvent(msg);
	}
	
    protected function onSingleSimulationComplete():void {
        simulationModel.currSimulationWindow.simulationStatus = SimulationModel.SIMULATION_STATUS_COMPLETE;

		//remember the version of helper apps used for simulation
        var vo:WindowVO = simulationModel.currSimulationWindow;
        vo.AERCalcVersion = AboutInfo.applicationVersion;
        vo.EPlusVersion = ApplicationModel.VERSION_ENERGYPLUS;
        vo.ESCalcVersion = ApplicationModel.VERSION_ESCALC;
		if (vo.isParent){
            for(var index:uint=0;index<vo.children.length;index++){
                var childVO:WindowVO = vo.children[index] as WindowVO;
                childVO.AERCalcVersion = AboutInfo.applicationVersion;
                childVO.EPlusVersion = ApplicationModel.VERSION_ENERGYPLUS;
                childVO.ESCalcVersion = ApplicationModel.VERSION_ESCALC;
                dbManager.save(childVO);
            }
		}


        dbManager.save(simulationModel.currSimulationWindow);
        libraryModel.windowsAC.refresh();
        doNextSimulation();
    }

    protected function onSingleSimulationFailed(errorMsg:String):void {
		
		//TODO: Show errors nicely in popup after simulations complete
		
		errorMsg = "Window : " + simulationModel.currSimulationWindow.name + " \n\nError : " + errorMsg;
		
		Alert.show(errorMsg, "Simulation Error");
		
        simulationModel.currSimulationWindow.simulationStatus = SimulationModel.SIMULATION_STATUS_FAILED;
        libraryModel.windowsAC.refresh();
        doNextSimulation();
    }
	

	/* ENERGYPLUS LISTENERS */
	
	protected function onEnergyPlusFinished(event:DynamicEvent):void
	{
		var energyPlusFiles:ArrayCollection = event.energyPlusFiles;
		var shadeType:String = event.shadeType;

		Logger.debug("running ESCalc", this);
		
		try
		{				
			esCalcDelegate.init();
			esCalcDelegate.calc(energyPlusFiles, shadeType);
		}
		catch(error:Error)
		{
			Alert.show("There was an error when trying to run ESCalc: " + error.message, "Error")
		}			
	}
	
	protected function onEnergyPlusFailed(event:DynamicEvent):void {
		var errorMsg:String = event.error;
		onSingleSimulationFailed(errorMsg);
	}
	
	/*  Validate that the windowVO is defined correctly and all necessary files exist.
		If the method returns without error the window is valid for simulation.

		TODO: Add more checks!

	*/
	protected function validateWindowForSimulation(wVO:WindowVO):void
	{
		Logger.debug("Validating window for simulation.", this);
		if (!wVO) {
            throw new WindowValidationError("Window was null");
        }
		var numChildWindows:uint = wVO.numChildren();
		if(wVO.isParent)
		{
			// Checks to do if window is a parent
			if (numChildWindows != 4){
            	var msg:String = "Window \"" + wVO.name + "\" has an attachment with 2 degrees of freedom and requires exactly 4 children.  Found: " + numChildWindows;
            	throw new WindowValidationError(msg);
			}
			for (var childIndex:uint=0; childIndex<4; childIndex++){
                validateWindowDimensions(wVO.children[childIndex]);
			}
		} else {
			// Checks to do if window is no parent or child
            validateWindowDimensions(wVO);
		}
	}

	protected function validateWindowDimensions(wVO:WindowVO):void {
        if (wVO.width<=0){
            throw new WindowValidationError("Window " + wVO.name + " has invalid width: " + wVO.width);
        }

        if (wVO.height<=0){
            throw new WindowValidationError("Window " + wVO.name + " has invalid height: " + wVO.height);
        }

        if (wVO.UvalWinter <=0){
            throw new WindowValidationError("Window " + wVO.name + " has invalid UVal: " + wVO.UvalWinter);
        }

        if (!wVO.name || wVO.name==""){
            throw new WindowValidationError("Window " + wVO.id + " is missing name");
        }
	}
	
	/* ESCALC LISTENERS */
	
	protected function onESCalcFinished(event:DynamicEvent):void
	{
		var hotResultsPath:String = event.hotResultsPath;
		var coldResultsPath:String = event.coldResultsPath;
		
		Logger.debug("running ESCalcResultsLoader", this);
		
		try
		{
			eSCalcResultsLoader.init();
			var eph:Number = eSCalcResultsLoader.loadColdClimateResults(coldResultsPath);
			var epc:Number = eSCalcResultsLoader.loadHotClimateResults(hotResultsPath);
			simulationModel.currSimulationWindow.epc = epc;
			simulationModel.currSimulationWindow.eph = eph;
			onSingleSimulationComplete();
			
		}
		catch(error:Error)
		{
			Alert.show("There was an error when trying to run ESCalc: " + error.message, "Error")
		}			
	}
	
	protected function onESCalcFailed(event:DynamicEvent):void {
		var errorMsg:String = event.error;
		onSingleSimulationFailed(errorMsg);
	}
	


}
}