package gov.lbl.aercalc.util
{
	
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.XMLSocket;
	import flash.utils.getQualifiedClassName;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.logging.LogEventLevel;
	
	import gov.lbl.aercalc.model.ApplicationModel;
	
	public class Logger
	{
		
		public static var enabled:Boolean = true;
		public static var myLogger:ILogger;
		private static var socket:XMLSocket;
		public static var logFile:File;
		public static var logFileStream:FileStream;
		public static var logToFile:Boolean = true;
		
		
		public static function debug(o:Object, target:Object = null):void
		{
			_send(LogEventLevel.DEBUG, o, target);
		}
		
		public static function info(o:Object, target:Object = null):void
		{
			_send(LogEventLevel.INFO, o, target);
		}
		
		public static function warn(o:Object, target:Object = null):void
		{
			_send(LogEventLevel.WARN, o, target);
		}
		
		public static function error(o:Object, target:Object = null):void
		{
			_send(LogEventLevel.ERROR, o, target);
		}
		
		public static function fatal(o:Object, target:Object = null):void
		{
			_send(LogEventLevel.FATAL, o, target);
		}
		
		public static function all(o:Object, target:Object = null):void
		{
			_send(LogEventLevel.ALL, o, target);
		}
		
		private static function onSocketError(err:IOErrorEvent):void
		{
			//do nothing.
		}
		
		private static function _send(lvl:Number, o:Object, target:Object):void
		{
			
			try
			{
				
				if (myLogger == null)
				{
					myLogger = Log.getLogger("gov.lbl.aercalc")
				}
				
				var type:String;
				switch (lvl)
				{
					case LogEventLevel.DEBUG:
						type = "DEBUG:";
						if (Log.isDebug())
						{
							var targetName:String = getTargetClassName(target)
							myLogger.debug(targetName + " : " + o.toString())
						}
						break;
					case LogEventLevel.INFO:
						type = "INFO:";
						if (Log.isInfo())
						{
							targetName = getTargetClassName(target)
							myLogger.info(targetName + " : " + o.toString());
						}
						break;
					case LogEventLevel.WARN:
						type = "WARN:";
						if (Log.isWarn())
						{
							targetName = getTargetClassName(target)
							myLogger.warn(targetName + " : " + o.toString());
						}
						break;
					case LogEventLevel.ERROR:
						type = "ERROR:";
						if (Log.isError())
						{
							targetName = getTargetClassName(target)
							myLogger.error(targetName + " : " + o.toString());
						}
						break;
					case LogEventLevel.FATAL:
						type = "FATAL:";
						if (Log.isFatal())
						{
							targetName = getTargetClassName(target);
							myLogger.fatal(targetName + " : " + o.toString());
						}
						break;
					case LogEventLevel.ALL:
						type = "ALL:";
						targetName = getTargetClassName(target);
						myLogger.log(lvl, targetName + " : " + o.toString());
						break;
				}
			}
			catch (error:Error)
			{
				//hmm...
			}
			
			if (logToFile && logFile == null)
			{
				try
				{
					var logFile:File = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.AERCALC_LOG_FILE_PATH);
					if (!logFile.exists) {
						logFile.createDirectory();
					}
					logFile = logFile.resolvePath(ApplicationModel.AERCALC_LOG_FILE_NAME);
					if (logFile.exists){
						logFile.deleteFile();
					}
				}
				catch (err:Error)
				{
					trace("couldn't delete log file! Error: " + err)
				}
				
				if (logFileStream == null) logFileStream = new FileStream();
				try
				{					
					logFileStream.open(logFile, FileMode.WRITE);
					logFileStream.writeUTFBytes("AERCalc LOG" + File.lineEnding + "-------------------------------------" + File.lineEnding);
					logFileStream.writeUTFBytes("AERCalc version: " + AboutInfo.applicationVersion + File.lineEnding);
					logFileStream.writeUTFBytes("Flash player version: " + AboutInfo.flashPlayerVersion + File.lineEnding);
					
				}
				catch (err:Error)
				{
					trace("couldn't init log file! Error: " + err)
				}
				logFileStream.close();
				
			}
			
			if (logToFile && logFile) 
			{
				if (logFileStream == null) logFileStream = new FileStream();
				try
				{
					logFileStream.open(logFile, FileMode.APPEND)
					logFileStream.writeUTFBytes(File.lineEnding + type + o)
				}
				catch(err:Error)
				{					
					trace("couldn't write to log file! Error: " + err)
				}               
				logFileStream.close()
			}
			
		}
		
		protected static function getTargetClassName(target:Object):String
		{
			if (target != null)
			{
				var targetName:String = getQualifiedClassName(target).split("::")[1];
			}
			else
			{
				targetName = "";
			}
			return targetName
		}
		
		
	}
	
	
}