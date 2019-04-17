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
	
	import gov.lbl.aercalc.model.ApplicationModel;
	import gov.lbl.aercalc.model.SimulationModel;
	import gov.lbl.aercalc.model.domain.WindowVO;
	import gov.lbl.aercalc.util.Logger;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.events.DynamicEvent;
	
 
	
	public class ESCalcResultsLoader extends EventDispatcher
	{		
	
		/* Events launched from this delegate */	
		public static const LOAD_RESULTS_FAILED:String = "escalcLoadResultsFailed"
		public static const LOAD_RESULTS_FINISHED:String = "escalcLoadResultsFinished"
						
		protected var _logDir:File
		
		protected var _escalcDir:File				
		protected var _escalcExe:File
		protected var _escalcProcess:NativeProcess
		protected var _inputFilePath:File
		
		protected var _houstonFinished:Boolean = false;
		protected var _houstonFiles:ArrayCollection = new ArrayCollection();
		protected var _minneapolisFiles:ArrayCollection = new ArrayCollection();
		protected var _attachmentType:String;
		
		[Inject]
		public var applicationModel:ApplicationModel
		
		[Inject]
		public var simulationModel:SimulationModel
		
		public function ESCalcResultsLoader():void
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
		
		public function loadHotClimateResults(hotOutputPath:String):Number
		{			
			try{
				var hotESCalcOutput:File = new File(hotOutputPath);			
				var stream:FileStream = new FileStream();
				stream.open(hotESCalcOutput, FileMode.READ);
				var hotXml:XML = XML(stream.readUTFBytes(stream.bytesAvailable));
				stream.close();
				var epCooling:Number = Number(hotXml.EPcooling[0]);			
				return epCooling;
			}
			catch(error:Error){
				var msg:String = "Couldn't read file : " + hotOutputPath;
				Logger.error(msg, this);
				throw new Error(msg);
			}
			return -999;
		}
		
		
		public function loadColdClimateResults(coldOutputPath:String):Number
		{			
			try{
				var coldESCalcOutput:File = new File(coldOutputPath);	
				var stream:FileStream = new FileStream();
				stream.open(coldESCalcOutput, FileMode.READ);
				var coldXml:XML = XML(stream.readUTFBytes(stream.bytesAvailable));
				stream.close();
				
				var epHeating:Number = Number(coldXml.EPheating[0]);
				return epHeating;
			}
			catch(error:Error){
				var msg:String = "Couldn't read file : " + coldOutputPath;
				Logger.error(msg, this);
				throw new Error(msg);
			}
			return -999;
		}
		
		public function cancel():void
		{}
		
	}
}
