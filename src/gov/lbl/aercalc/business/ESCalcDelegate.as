package gov.lbl.aercalc.business
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.EventDispatcher;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import gov.lbl.aercalc.error.ESCalcDelegateError;
	import gov.lbl.aercalc.model.ApplicationModel;
	import gov.lbl.aercalc.model.SimulationModel;
	import gov.lbl.aercalc.util.Logger;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.events.DynamicEvent;
	
 
	
	public class ESCalcDelegate extends EventDispatcher
	{		
	
		/* Events launched from this delegate */
		public static const RUN_ESCALC_FAILED:String = "escalcFailed";
		public static const RUN_ESCALC_FINISHED:String = "escalcFinished";
						
		protected var _logDir:File
		
		protected var _escalcExecutable:String = ApplicationModel.ESCALC_EXE_FILE_NAME;
		
		protected var _escalcDir:File				
		protected var _escalcExe:File
		protected var _escalcProcess:NativeProcess
		protected var _inputFilePath:File
		
		protected var _houstonFinished:Boolean = false;
		protected var _houstonFiles:ArrayCollection = new ArrayCollection();
		protected var _minneapolisFiles:ArrayCollection = new ArrayCollection();

		// The subdirectory within the EPCalc subdirectory where output files will be saved by EPCalc
		protected var _baseOutputDir:File = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.EPCALC_OUTPUT);

		// The standardized first part of the output file name
		protected var _baseOutputFilename:String = "";


		protected var _attachmentType:String;
		protected var _hotResultsPath:String;
		protected var _coldResultsPath:String;
		
		[Inject]
		public var applicationModel:ApplicationModel
		
		[Inject]
		public var simulationModel:SimulationModel
		
		public function ESCalcDelegate():void
		{	
			
		}
		
		public function init():void
		{
			initVars();
		}
		
		public function initVars():void
		{
			_escalcProcess = new NativeProcess()
			_escalcDir = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.EPCALC_SUBDIR)
			Logger.debug("escalcDir: " + _escalcDir.nativePath, this) 
			_escalcExe = _escalcDir.resolvePath(ApplicationModel.ESCALC_EXE_FILE_NAME)				
		}
		
		
		public function get_deployment_from_file(f:File):String
		{
			var deployment:String = "";
			if(f.name.toUpperCase().indexOf("FULLY_SHADED") > -1)
			{
				deployment = "Full";				
			}
			else if(f.name.toUpperCase().indexOf("HALF_SHADED") > -1)
			{
				deployment = "Half"
			}
			
			return deployment;
		}
		
		public function get_slat_angle_from_file(f:File):String
		{
			var angle:String = "X";
			
			if(f.name.toUpperCase().indexOf("_VB") > -1)
			{
				var splitName:Array = f.name.split("_");
				var slatAngle:String = f.name.split("_VB")[1].split("_")[0]; //split on _VB then the next thing before an "_" is the slat angle
				angle = slatAngle;
			}
			
			if(f.name.toUpperCase().indexOf("_VL") > -1)
			{
				splitName = f.name.split("_");
				slatAngle = f.name.split("_VL")[1].split("_")[0]; //split on _VB then the next thing before an "_" is the slat angle
				angle = slatAngle;
			}
			
			return angle;
		}
		
		
		public function create_input_xml(path:File, city:String, attachment_type:String, energy_plus_output:ArrayCollection):void
		{
			var res:String;
			res = '<?xml version="1.0" encoding="UTF-8"?>' + File.lineEnding;
			res += '<!-- edited with XMLSpy v2016 rel. 2 sp1 (x64) (http://www.altova.com) by D. Charlie Curcija (Lawrence Berkeley National Laboratory) -->' + File.lineEnding;				
			res += '<!-- Based on XML schema ESCalc.xsd.-->\n';
			res += '<ESCalc xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="ESCalc.xsd">' + File.lineEnding;
			res += '<Input>' + File.lineEnding;
			res += '<Selection>ES</Selection>' + File.lineEnding;
			res += '<City>' + city + '</City>' + File.lineEnding;
			res += '<AttachmentType>' + attachment_type + '</AttachmentType>' + File.lineEnding;
			res += '<NoCSVFiles>' + energy_plus_output.length.toString() + '</NoCSVFiles>' + File.lineEnding;
			for(var i:uint = 0; i < energy_plus_output.length; ++i)
			{
				res += '<CSVFile>' + File.lineEnding;
				res += '<CSVFileName>' + energy_plus_output[i].nativePath + '</CSVFileName>' + File.lineEnding;
				res += '<Deployment>' + get_deployment_from_file(energy_plus_output[i]) + '</Deployment>' + File.lineEnding;
				res += '<SlatAngle>' + get_slat_angle_from_file(energy_plus_output[i]) + '</SlatAngle>' + File.lineEnding;
				res += '</CSVFile>' + File.lineEnding;
			}
			
			res += '</Input>' + File.lineEnding;
			res += '</ESCalc>' + File.lineEnding;
			
			try
			{	
				Logger.debug(" Writing ESCalc input xml to: " + path.nativePath, this)	
				var stream:FileStream = new FileStream();
				stream.open(path, FileMode.WRITE);
				stream.writeUTFBytes(res);
				stream.close();
			}
			catch(error:Error)
			{
				Logger.error("error while attempting to save : "+ path.nativePath + " Error: " + error, this)
				Alert.show("There was an error when trying to save this file (Error msg: " + error +")")
				return
			}
		}
		
		public function calc(ePlusOutput:ArrayCollection, attachmentType:String):void
		{
			//make sure the output directory exists
			if (!_baseOutputDir.exists){
				try{
                    _baseOutputDir.createDirectory();
				} catch (error:Error){
					var msg:String = "Couldn't create the output directory " + _baseOutputDir.nativePath;
					Logger.error(msg, this);
					throw new Error(msg)
				}
			}

			_houstonFiles = new ArrayCollection();
			_minneapolisFiles = new ArrayCollection();
			_attachmentType = attachmentType;
			for each(var f:File in ePlusOutput)
			{
				if(f.name.toUpperCase().indexOf("HOUSTON") > -1)
				{
					_houstonFiles.addItem(f);
				}
				if(f.name.toUpperCase().indexOf("MINNEAPOLIS") > -1)
				{
					_minneapolisFiles.addItem(f);
				}				
			}

			//assumes that Houston and Minneapolis files have identical file names
			//up until last part with "_(city)" ...
			var fname:String = _houstonFiles[0].name;
			fname = fname.split("_Houston")[0];
			_baseOutputFilename = fname;
			var houstonOutputFilename:String = _baseOutputFilename + "_Houston.xml";

			_hotResultsPath = _baseOutputDir.resolvePath(houstonOutputFilename).nativePath;
			_houstonFinished = false;

			runESCalc("Houston", _attachmentType, _houstonFiles, _hotResultsPath);
		}
		
		public function runESCalc(city:String, attachment_type:String, energy_plus_output:ArrayCollection, output_path:String):void
		{			
			_inputFilePath = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.EPCALC_SUBDIR + city + ".xml");
			create_input_xml(_inputFilePath, city, attachment_type, energy_plus_output);
			_runESCalc(output_path);
		}

		protected function _runESCalc(output_path:String):void
		{
			
			if (_escalcProcess && _escalcProcess.running)
			{
				_escalcProcess.exit(true)
			}
						
			if (_escalcExe && _escalcExe.exists==false)
			{
				Logger.error("Couldn't find the ESCalc executable (" + ApplicationModel.ESCALC_EXE_FILE_NAME + ") in the default directory.", this)
				throw new ESCalcDelegateError("Couldn't find the ESCalc executable (" + ApplicationModel.ESCALC_EXE_FILE_NAME + ") in the default directory. Please make sure the " + ApplicationModel.ESCALC_EXE_FILE_NAME + " file exists in the EP_Weighting_Scripts_ESCalc subdirectory.")
			}

			var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			startupInfo.executable = _escalcExe;
				
			var processArgs:Vector.<String> = new Vector.<String>();
			processArgs.push(_inputFilePath.nativePath);
			processArgs.push("-o");
			processArgs.push(output_path);
			Logger.debug("Writing the following line to ESCalc:",this);
			Logger.debug(processArgs.join(" "), this);
			startupInfo.arguments = processArgs;
					
			startupInfo.workingDirectory = _escalcDir;
				
			//simulationModel.escalcOutputMessage = "Starting ESCalc"
			
			_escalcProcess.addEventListener(NativeProcessExitEvent.EXIT, onESCalcProcessFinished);
			_escalcProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onESCalcStandardOutput);
			_escalcProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onESCalcStandardError);
			_escalcProcess.start(startupInfo)								
		}		

		public function isProcessRunning():Boolean
		{
			return _escalcProcess.running
		}
		
		public function onESCalcProcessFinished(event:NativeProcessExitEvent):void
		{
			if(!_houstonFinished)
			{
				_houstonFinished = true;
                var minnOutputFilename:String = _baseOutputFilename + "_Minneapolis.xml";
				_coldResultsPath = _baseOutputDir.resolvePath(minnOutputFilename).nativePath;
				runESCalc("Minneapolis", _attachmentType, _minneapolisFiles, _coldResultsPath);
				return
			}
			
			//_finishedCallback(_hotResultsPath, _coldResultsPath);
			var msg:DynamicEvent = new DynamicEvent(ESCalcDelegate.RUN_ESCALC_FINISHED, true);
			msg.hotResultsPath = _hotResultsPath;
			msg.coldResultsPath = _coldResultsPath;
			dispatchEvent(msg);
		}
		
		public function onESCalcStandardOutput(event:ProgressEvent):void
		{
			var text:String = _escalcProcess.standardOutput.readUTFBytes(_escalcProcess.standardOutput.bytesAvailable);			
			//simulationModel.escalcOutputMessage = text
			Logger.debug(text, this);
			
		}
		
		public function onESCalcStandardError(event:ProgressEvent):void
		{
			var text:String = _escalcProcess.standardError.readUTFBytes(_escalcProcess.standardError.bytesAvailable)
			Logger.error(text, this);

			removeESCalcEventListeners();

            //should already be closed but can't hurt to make sure...
            _escalcProcess.exit(true);

            throw new Error("ESCalc error: " + text);
		}
		
		public function removeESCalcEventListeners():void
		{
			if (_escalcProcess){
				_escalcProcess.removeEventListener(NativeProcessExitEvent.EXIT, onESCalcProcessFinished);
				_escalcProcess.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onESCalcStandardOutput);
				_escalcProcess.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, onESCalcStandardError);
			}

		}
		
		public function cancel():void
		{
			if (_escalcProcess && _escalcProcess.running)
			{
				_escalcProcess.exit(true)
			}
			removeESCalcEventListeners()
		}
	}
}
