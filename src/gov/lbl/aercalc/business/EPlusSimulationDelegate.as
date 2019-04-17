package gov.lbl.aercalc.business
{
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import flashx.textLayout.formats.Float;
	
	import gov.lbl.aercalc.error.FileMissingError;
	import gov.lbl.aercalc.error.SimulationError;
	import gov.lbl.aercalc.events.EnergyPlusEvent;
	import gov.lbl.aercalc.events.SimulationErrorEvent;
	import gov.lbl.aercalc.events.SimulationEvent;
	import gov.lbl.aercalc.model.ApplicationModel;
	import gov.lbl.aercalc.model.LibraryModel;
	import gov.lbl.aercalc.model.SimulationModel;
	import gov.lbl.aercalc.model.domain.WindowVO;
	import gov.lbl.aercalc.util.Logger;
	import gov.lbl.aercalc.util.Utils;
	
	import mx.collections.ArrayCollection;
	import mx.core.RuntimeDPIProvider;
	import mx.events.DynamicEvent;
	
	/** Creates data for EnergyPlus runs, manages run process and saves results into .inc files. 
	 * 
	 * 
	 * 
	 * */
	
	public class EPlusSimulationDelegate extends EventDispatcher
	{
		public static const RUN_EPLUS_FAILED:String = "EnergyPlusFailed";
		public static const RUN_EPLUS_FINISHED:String = "EnergyCalcFinished";
		
		protected var _baselineIncFile:File
		
		protected var _energyPlusExecutable:String = "EnergyPlus.exe";
		protected var _multipleEnergyPlusRunsExecutable:String = "RunEPlus.exe";
		protected var _readVarsESOExecutable:String = "ReadVarsESO.exe";
			
		protected var _energyPlusDir:File = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.ENERGY_PLUS_SUBDIR);
		protected var _resultsDir:File
		protected var _inputDir:File
		
		protected var _energyPlusProcess:NativeProcess;
		
		protected var _window:WindowVO;
		protected var _idfFilesToRun:Array;
		
		
		protected var _minneapolisWeatherDdyFName:String = "USA_MN_Minneapolis-St.Paul.Intl.AP.726580_TMY3.ddy";
		protected var _minneapolisWeatherEpwFName:String = "USA_MN_Minneapolis-St.Paul.Intl.AP.726580_TMY3.epw";
		protected var _houstonWeatherDdyFName:String = "USA_TX_Houston-Bush.Intercontinental.AP.722430_TMY3.ddy";
		protected var _houstonWeatherEpwFName:String = "USA_TX_Houston-Bush.Intercontinental.AP.722430_TMY3.epw";
		protected var _curIdfFile:String;
		protected var _shadeType:String;
		protected var _totalNumberOfRuns:int;
		protected var _curRunIndex:int;
		
		public var _ePlusOutputFiles:ArrayCollection = new ArrayCollection();
		
		
		[Inject]
		public var applicationModel:ApplicationModel;
		
		[Inject]
		public var simulationModel:SimulationModel;

		[Inject]
		public var libraryModel:LibraryModel;
		
		[Inject]
		public var infiltrationCalcs:InfiltrationCalcs;
		
		[Dispatcher]
		public var dispatcher:IEventDispatcher;
		
		
		[PostConstruct]
		public function init():void
		{
			_energyPlusProcess = new NativeProcess();
			_curRunIndex = 0;			
		}
		
		public function copyWeatherFile(city:String):void
		{
			if(city.toUpperCase() == "HOUSTON")
			{
				var epwFileName:String = _houstonWeatherEpwFName;
			}
			else if(city.toUpperCase() == "MINNEAPOLIS")
			{
                epwFileName = _minneapolisWeatherEpwFName;
			}

            var epw:File = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.ENERGY_PLUS_WEATHER_DIR + epwFileName);
			if (!epw.exists){
				throw new Error("Can't find EPW weather file: " + epw.nativePath);
			}
 
			var inputWeatherFile:File = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.ENERGY_PLUS_SUBDIR + "in.epw");
			if(inputWeatherFile.exists)
			{
				inputWeatherFile.deleteFile();
			}
			epw.copyTo(inputWeatherFile);
		}
	
		public function createAirInfiltrationFile(baseline:File, windowName:String, city:String, shadeAirLeakage:Number, halfShaded:Boolean):File
		{
			if(city.toLowerCase() == "houston")
			{
				var airLeakage:Number = infiltrationCalcs.calc_ELA_HWA_cooling(shadeAirLeakage);
			}
			else if(city.toLowerCase() == "minneapolis")
			{
				airLeakage =  infiltrationCalcs.calc_ELA_HWA_heating(shadeAirLeakage);
			}
			else
			{
				throw new Error(city + " is not a valid option.  Current supported cities are Houston and Minneapolis.");
			}						
						
			if(halfShaded)
			{
				//if it is half shaded use the undedited baseline values.
				return baseline;
			}
			
			//read in file contents
			var fileStream:FileStream = new FileStream();
			fileStream.open(baseline, FileMode.READ);
			var result:String = fileStream.readUTFBytes(fileStream.bytesAvailable);
			fileStream.close();
			var resultLines:Array = result.split("\n");
			
			var isEffectiveLeakageSection:Boolean = false;
			var isCorrectZone:Boolean = false;
			
			for(var i:int = 0; i < resultLines.length; ++i)
			{			
				if(resultLines[i].indexOf("ZoneInfiltration:EffectiveLeakageArea") > -1) //if we are starting the appropriate section of ZoneInfiltration:EffectiveLeakageArea
				{
					isEffectiveLeakageSection = true;									
				}
				
				if(isEffectiveLeakageSection && resultLines[i].indexOf("Living_ShermanGrimsrud_unit1") > -1)
				{			
					isCorrectZone = true;
				}

				if(isCorrectZone && resultLines[i].indexOf("Effective Air Leakage Area") > -1)
				{
					resultLines[i] = "    " + airLeakage.toString() + ",                    !- Effective Air Leakage Area {cm2}"
					isEffectiveLeakageSection = false;
					isCorrectZone = false;
					break;
				}
			}
			fileStream.open(baseline, FileMode.WRITE);
			fileStream.writeUTFBytes(resultLines.join("\n"));
			fileStream.close();
			
			return baseline
		}
		
		public function createFullyShadedBaseline(baseline:File, windowName:String, city:String, baselineType:String):File
		{					
			var destPath:String = ApplicationModel.ENERGY_PLUS_INC_DIR + windowName + "_" + city + "_fully_shaded_baseline_" + baselineType + ".idf";			
			destPath = Utils.makeUsableAsAFilename(destPath);
			var _incFile:File = ApplicationModel.baseStorageDir.resolvePath(destPath);
			if(_incFile.exists)
			{
				_incFile.deleteFile();
			}
			baseline.copyTo(_incFile);
			
			windowName = Utils.makeUsableAsAnEPlusField(windowName)
			
			//read in file contents
			var fileStream:FileStream = new FileStream()
			fileStream.open(_incFile, FileMode.READ)
			var result:String = fileStream.readUTFBytes(fileStream.bytesAvailable)
			fileStream.close()
			
			var defaultWindowPattern:RegExp = /AERC_Baseline_._GlzSys_DoubleClear,.*!- Construction Name/g;
			result = result.replace(defaultWindowPattern, windowName + ",    !- Construction Name")
				
			var defaultFramePattern:RegExp = /AERC_Baseline_._Frame,.*!- Frame and Divider Name/g;
			result = result.replace(defaultFramePattern, windowName + "-Frame,    !- Frame and Divider Name")
			
			fileStream.open(_incFile, FileMode.WRITE);
			fileStream.writeUTFBytes(result)
			fileStream.close();
			
			return _incFile;
		}
		
		public function createHalfShadedBaseline(baseline:File, windowName:String, city:String, baselineType:String):File
		{	
			var _incFile:File = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.ENERGY_PLUS_INC_DIR + Utils.makeUsableAsAFilename(windowName) + "_" + city + "_half_shaded_baseline_" + baselineType + ".idf");
			if(_incFile.exists)
			{
				_incFile.deleteFile();
			}
			
			windowName = Utils.makeUsableAsAnEPlusField(windowName)
			
			baseline.copyTo(_incFile);
			
			//read in file contents
			var fileStream:FileStream = new FileStream();
			fileStream.open(_incFile, FileMode.READ);
			var result:String = fileStream.readUTFBytes(fileStream.bytesAvailable);
			fileStream.close();
				
			var resultLines:Array = result.split("\n");
			
			var inSuraceSection:Boolean = false;
			var isTopSection:Boolean = false;
			
			for(var i:int = 0; i < resultLines.length; ++i)
			{
				if(resultLines[i].indexOf("FenestrationSurface:Detailed") != -1)
				{
					inSuraceSection = true;
					if(resultLines[i+1].indexOf("_Top") != -1)
					{
						isTopSection = true;
					}
				}
				
				var baselineGlySysName:String = "AERC_Baseline_" + baselineType + "_GlzSys_DoubleClear";
				if(isTopSection && resultLines[i].indexOf(baselineGlySysName) != -1)
				{
					resultLines[i] = resultLines[i].replace(baselineGlySysName, windowName);					
				}	
				
				var baselineFrameName:String = "AERC_Baseline_" + baselineType + "_Frame";
				if(isTopSection && resultLines[i].indexOf(baselineFrameName) != -1)
				{
					resultLines[i] = resultLines[i].replace(baselineFrameName, windowName + "-Frame");
					inSuraceSection = false;
					isTopSection = false;
				}
				
			}
			
			fileStream.open(_incFile, FileMode.WRITE);
			fileStream.writeUTFBytes(resultLines.join("\n"));
			fileStream.close();
			return _incFile;
		}
		
		public function prependTextToFile(f:File, text:String):File
		{
			var fileStream:FileStream = new FileStream();
			fileStream.open(f, FileMode.READ);
			var result:String = fileStream.readUTFBytes(fileStream.bytesAvailable);
			fileStream.close();
			
			result = text + "\n" + result;
			
			fileStream.open(f, FileMode.WRITE);
			fileStream.writeUTFBytes(result);
			fileStream.close();
			return f;
		}
		
		public function combineFiles(files:ArrayCollection, outputFile:String, prependText:String):File
		{
			var totalContents:String = prependText + "\n";
			var stream:FileStream = new FileStream();
			
			for each(var f:File in files)
			{
				try{
					stream.open(f, FileMode.READ);
					totalContents += stream.readUTFBytes(stream.bytesAvailable);
					stream.close();
				}
				catch(error:Error){
					var msg:String = "Couldn't read file : " + f.nativePath;
					Logger.error(msg, this);
					throw new Error(msg);
				}
				
			}
			
			var outfile:File = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.ENERGY_PLUS_INPUT_DIR + outputFile);
			if(outfile.exists)
			{
				outfile.deleteFile()
			}
			
			
			try{
				stream.open(outfile, FileMode.WRITE);
				stream.writeUTFBytes(totalContents);
				stream.close();
			}
			catch(error:Error){
				msg = "Couldn't write to output file : " + outfile.nativePath;
				Logger.error(msg, this);
				throw new Error(msg);
			}
			
			return outfile;
		}
		
		public function createIdf(wVO:WindowVO, city:String, halfShaded:Boolean, baselineType:String):File
		{
			var baseline:File = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.ENERGY_PLUS_INC_DIR + city + "/" + city + "_Baseline_" + baselineType + ".idf");
			if (!baseline.exists){
				var msg:String = "Missing baseline file: " + baseline.nativePath;
				throw new FileMissingError(msg);
			}
			
			var idf:File;
			
			if(halfShaded)
			{
				idf = createHalfShadedBaseline(baseline, wVO.name, city, baselineType);
			}
			else
			{
				idf = createFullyShadedBaseline(baseline, wVO.name, city, baselineType);	
			}

			var airInfiltration:File = createAirInfiltrationFile(idf, wVO.name, city, wVO.airInfiltration, halfShaded);			
			var bsdfName:String = Utils.makeUsableAsAFilename(wVO.name) + "_bsdf.idf";
			var projectBSDFDir:File = applicationModel.getCurrentProjectBSDFDir();
			var w7IdfFile:File = projectBSDFDir.resolvePath(bsdfName);
			if (!w7IdfFile.exists){
				msg = "Missing idf file: " + w7IdfFile.nativePath;
				throw new FileMissingError(msg);
			}
			var files:ArrayCollection = new ArrayCollection();
			files.addItem(idf);
			files.addItem(w7IdfFile);
			
			var fileEnding:String = "_fully_shaded.idf";
			if(halfShaded)
			{
				fileEnding = "_half_shaded.idf";
			}
			
			var appXML:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var air:Namespace = appXML.namespaceDeclarations()[0];
			var createdByText:String = "!- Created by AERCalc v" + appXML.air::versionNumber + "\n";
			idf = combineFiles(files, Utils.makeUsableAsAFilename(wVO.name) + "_" + city + fileEnding, createdByText);
				
			return idf;
		}
		
		public function createHalfShadedIdf(wVO:WindowVO, city:String, baselineType:String):File
		{
			return createIdf(wVO, city, true, baselineType);
		}
		
		public function createFullyShadedIdf(wVO:WindowVO, city:String, baselineType:String):File
		{
			return createIdf(wVO, city, false, baselineType);
		}
		
		public function createRollerShadesFiles(wVO:WindowVO, baselineType:String):ArrayCollection
		{
			var houston_full:File = createFullyShadedIdf(wVO, "Houston", baselineType);
			var minneapolis_full:File = createFullyShadedIdf(wVO, "Minneapolis", baselineType);
			var houston_half:File = createHalfShadedIdf(wVO, "Houston", baselineType);
			var minneapolis_half:File = createHalfShadedIdf(wVO, "Minneapolis", baselineType);
			
			var ac:ArrayCollection = new ArrayCollection();
			ac.addItem(houston_full);
			ac.addItem(minneapolis_full);
			ac.addItem(houston_half);
			ac.addItem(minneapolis_half);
			return ac;
		}
			   
		public function createCellularShadesFiles(wVO:WindowVO, baselineType:String):ArrayCollection
		{
			var houston_full:File = createFullyShadedIdf(wVO, "Houston", baselineType);
			var minneapolis_full:File = createFullyShadedIdf(wVO, "Minneapolis", baselineType);
			var houston_half:File = createHalfShadedIdf(wVO, "Houston", baselineType);
			var minneapolis_half:File = createHalfShadedIdf(wVO, "Minneapolis", baselineType);
			
			var ac:ArrayCollection = new ArrayCollection();
			ac.addItem(houston_full);
			ac.addItem(minneapolis_full);
			ac.addItem(houston_half);
			ac.addItem(minneapolis_half);
			return ac;
		}
		
		public function createSolarScreensFiles(wVO:WindowVO, baselineType:String):ArrayCollection
		{
			var houston_full:File = createFullyShadedIdf(wVO, "Houston", baselineType);
			var minneapolis_full:File = createFullyShadedIdf(wVO, "Minneapolis", baselineType);
			
			var ac:ArrayCollection = new ArrayCollection();
			ac.addItem(houston_full);
			ac.addItem(minneapolis_full);
			return ac;
		}
	
		public function createAppliedFilmsFiles(wVO:WindowVO, baselineType:String):ArrayCollection
		{
			var houston_full:File = createFullyShadedIdf(wVO, "Houston", baselineType);
			var minneapolis_full:File = createFullyShadedIdf(wVO, "Minneapolis", baselineType);
			
			var ac:ArrayCollection = new ArrayCollection();
			ac.addItem(houston_full);
			ac.addItem(minneapolis_full);
			return ac;
		}
		
		public function createVenetianBlindsFiles(windowList:ArrayCollection, baselineType:String):ArrayCollection
		{
			var ac:ArrayCollection = new ArrayCollection();
			
			for each(var wVO:WindowVO in windowList)
			{
				ac.addItem(createFullyShadedIdf(wVO, "Houston", baselineType));
				ac.addItem(createFullyShadedIdf(wVO, "Minneapolis", baselineType));
				
				// Get if it is not a zero slat angle case by checking to make sure the shading system type doesn't have VB0 or VL0 in it  
				var isNotZeroAngle:Boolean = (wVO.shadingSystemType.toUpperCase().indexOf("VB0") == -1) && (wVO.shadingSystemType.toUpperCase().indexOf("VL0") == -1); 
				
				if(isNotZeroAngle) //Only make half-deployed runs for non-0-angle cases
				{
					ac.addItem(createHalfShadedIdf(wVO, "Houston", baselineType));
					ac.addItem(createHalfShadedIdf(wVO, "Minneapolis", baselineType));
				}
			}
			
			return ac;
		}	
		
		public function createVerticalBlindsFiles(windowList:ArrayCollection, baselineType:String):ArrayCollection
		{
			return createVenetianBlindsFiles(windowList, baselineType);
		}
		
		public function createWindowPanelsFiles(wVO:WindowVO, baselineType:String):ArrayCollection
		{
			var houston_full:File = createFullyShadedIdf(wVO, "Houston", baselineType);
			var minneapolis_full:File = createFullyShadedIdf(wVO, "Minneapolis", baselineType);
			
			var ac:ArrayCollection = new ArrayCollection();
			ac.addItem(houston_full);
			ac.addItem(minneapolis_full);
			return ac;
		}
		
		public function createPleatedShadesFiles(wVO:WindowVO, baselineType:String):ArrayCollection
		{
			var houston_full:File = createFullyShadedIdf(wVO, "Houston", baselineType);
			var minneapolis_full:File = createFullyShadedIdf(wVO, "Minneapolis", baselineType);
			var houston_half:File = createHalfShadedIdf(wVO, "Houston", baselineType);
			var minneapolis_half:File = createHalfShadedIdf(wVO, "Minneapolis", baselineType);
			
			var ac:ArrayCollection = new ArrayCollection();
			ac.addItem(houston_full);
			ac.addItem(minneapolis_full);
			ac.addItem(houston_half);
			ac.addItem(minneapolis_half);
			return ac;
		}
		
	
		public function createEPlusFiles(window:WindowVO, baselineType:String):ArrayCollection
		{
			var windowList:ArrayCollection = new ArrayCollection();
			if(window.isParent)
			{
				//lookup children VOs
				for each(var childVO:WindowVO in window.children)
				{
					windowList.addItem(childVO);
				}
			}
			else
			{
				windowList.addItem(window);
			}
			
			_shadeType = windowList[0].shadingSystemType.toUpperCase();
			if (!_shadeType){
				throw new SimulationError("The window " + windowList[0] + " has a null shadeType.");
			}
			
			//["VB0", "VB45", "VB90", "VB-45", "WS", "CS", "PS", "RS", "SS", "WP"];
			switch (_shadeType){
				
				case "AF":
					return createAppliedFilmsFiles(windowList[0], baselineType);
				
				case "CS":
					return createCellularShadesFiles(windowList[0], baselineType);	

				case "PS":
					return createPleatedShadesFiles(windowList[0], baselineType);
				
				case "RS":
					return createRollerShadesFiles(windowList[0], baselineType);	
				
				case "SS":
					return createSolarScreensFiles(windowList[0], baselineType);	
				
				case "WP":
					return createWindowPanelsFiles(windowList[0], baselineType);
			}
			
			if(_shadeType.indexOf("VB") > -1)
			{
				return createVenetianBlindsFiles(windowList, baselineType);
			}
			
			if(_shadeType.indexOf("VL") > -1)
			{
				return createVerticalBlindsFiles(windowList, baselineType);
			}
			
			throw new Error("Unrecognized shadeType. Don't know how to create EnergyPlus shade files for shadeType: " + _shadeType);			
		}
		
		public function cancel():void
		{
			if (_energyPlusProcess && _energyPlusProcess.running)				
			{
				_energyPlusProcess.standardInput.writeUTFBytes("Exit\n");
			}			
			removeAllProcessEventListeners();		
		}
		
		/* *************************** */
		/*  ENERGY PLUS PROCESS        */
		/* *************************** */
		public function runEnergyPlus(window:WindowVO):void
		{	
			_window = window;			
			_idfFilesToRun = createEPlusFiles(window, "B").source;
			_ePlusOutputFiles = new ArrayCollection();
			
			_totalNumberOfRuns = _idfFilesToRun.length;
			_runSimultaniousEnergyPlus(_idfFilesToRun);
		}
		
		protected function _getWeatherFileForIdf(idfFile:File):File
		{
			var isHouston:Boolean = idfFile.nativePath.toUpperCase().indexOf("HOUSTON") > -1;			
			if(isHouston)
			{
				var epwFileName:String = _houstonWeatherEpwFName;
			}
			else
			{
				epwFileName = _minneapolisWeatherEpwFName;
			}
			
			var epw:File = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.ENERGY_PLUS_WEATHER_DIR + epwFileName);
			return epw;
		}
		
		function orderByName(a, b):int
		{
			var name1 = a.name;
			var name2 = b.name;
			if (name1 < name2){
				return -1;
			}
			else if(name1 > name2){
				return 1;
			}
			else{
				return 0;
			}
		}
		
		protected function _createSimultaniousEnergyPlusInputFile(idfFilesToRun:Array):File
		{
			var f:File = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.ENERGY_PLUS_INPUT_DIR + Utils.makeUsableAsAFilename(_window.name) + ".csv");			
			var stream:FileStream = new FileStream();
			stream.open(f, FileMode.WRITE);
			var sortedIdfFiles:Array = idfFilesToRun;
			sortedIdfFiles.sort(orderByName);
			for each(var idfFile:File in sortedIdfFiles)
			{
				var weatherFile:File = _getWeatherFileForIdf(idfFile);
				var line:String = "\"" + idfFile.nativePath + "\",\"" + weatherFile.nativePath + "\"\n";
				stream.writeUTFBytes(line);
			}
			stream.close();
			return f;
		}
		
		protected function _runSimultaniousEnergyPlus(idfFilesToRun:Array):void
		{			
			var inputFile:File = _createSimultaniousEnergyPlusInputFile(idfFilesToRun);

			
			for each(var idfFile:File in idfFilesToRun)
			{
				var expectedOutput:String = idfFile.name;
				expectedOutput = expectedOutput.replace(".idf", ".csv");
				var expectedOutFile:File = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.ENERGY_PLUS_OUTPUT_DIR + expectedOutput);
				_ePlusOutputFiles.addItem(expectedOutFile);
			}
			
			/*
			"-i", "--input", help="Path to file containing all pairs of idf and weather files to be run.  Expects a csv with one pair per line, idf file first."
			"-o", "--output", help="Path to directory to store the output from all the E+ runs."
			"-e", "--eplus", help="Path to E+ binary"
			"-r", "--readeso", help="Path to ReadVarsESO binary"			
			*/
			
			var processArgs:Vector.<String> = new Vector.<String>();
			processArgs.push("-i");
			processArgs.push(inputFile.nativePath);
			processArgs.push("-o");
			processArgs.push(ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.ENERGY_PLUS_OUTPUT_DIR).nativePath);
			processArgs.push("-e");
			processArgs.push(_energyPlusExecutable);
			processArgs.push("-r");
			processArgs.push(_readVarsESOExecutable );
			
			Logger.debug(processArgs.join(" "), this);
			
			
			var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			startupInfo.executable = _energyPlusDir.resolvePath(_multipleEnergyPlusRunsExecutable);
			startupInfo.workingDirectory = _energyPlusDir;
			startupInfo.arguments = processArgs;
			
			_energyPlusProcess.addEventListener(NativeProcessExitEvent.EXIT, onEnergyPlusProcessFinished)
			_energyPlusProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onEnergyPlusStandardOutput)
			_energyPlusProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onEnergyPlusStandardError)
				
			try
			{
				_energyPlusProcess.start(startupInfo)
			}
			catch (err:Error)
			{						
				//Since we haven't gone async yet, this should be a regular error, not an error event
				var msg:String = "Cannot start EnergyPlus. " + err.errorID + " : " + err.message;
				throw new SimulationError(msg);
			}

		}
		
		
		public function onEnergyPlusProcessFinished(event:NativeProcessExitEvent):void
		{
			Logger.info("EnergyPlus completed successfully. Now starting ReadVarESO...",this);
			removeEnergyPlusEventListeners();
			var msg:DynamicEvent = new DynamicEvent(EPlusSimulationDelegate.RUN_EPLUS_FINISHED, true);
			msg.shadeType = _shadeType;
			if(msg.shadeType.indexOf("VB") > -1)
			{
				msg.shadeType = "VB";
			}
			if(msg.shadeType.indexOf("VL") > -1)
			{
				msg.shadeType = "VL";
			}
			msg.energyPlusFiles = _ePlusOutputFiles;
			dispatchEvent(msg);
		}
		
		
		public function onEnergyPlusStandardOutput(event:ProgressEvent):void
		{
			var text:String = _energyPlusProcess.standardOutput.readUTFBytes(_energyPlusProcess.standardOutput.bytesAvailable);
			var evt:SimulationEvent = new SimulationEvent(SimulationEvent.SIMULATION_STATUS, true);			
			var txt_to_remove:String = Utils.makeUsableAsAFilename(_window.name) + "_";
			text = text.split(txt_to_remove).join("");
			text = text.split(".idf").join("");
			if(_shadeType.indexOf("VB") > -1)
			{
				text = text.split("_VB").join("VB");
			}
			
			if(_shadeType.indexOf("VL") > -1)
			{
				text = text.split("_VL").join("VL");
			}
			evt.statusMessage = text;
			Logger.debug(text);			
			dispatcher.dispatchEvent(evt);
		}
		
		public function onEnergyPlusStandardError(event:ProgressEvent):void
		{
			var text:String = _energyPlusProcess.standardError.readUTFBytes(_energyPlusProcess.standardError.bytesAvailable);
			Logger.error(text);
		}
		
		public function removeEnergyPlusEventListeners():void
		{			
			_energyPlusProcess.removeEventListener(NativeProcessExitEvent.EXIT, onEnergyPlusProcessFinished);
			_energyPlusProcess.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onEnergyPlusStandardOutput);
			_energyPlusProcess.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onEnergyPlusStandardError);
		}
		
		public function removeAllProcessEventListeners():void
		{			
			removeEnergyPlusEventListeners();
		}
	}	
		
}