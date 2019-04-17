package gov.lbl.aercalc.util
{

import flash.filesystem.File;
import flash.system.Capabilities;
import flash.utils.ByteArray;

import gov.lbl.aercalc.model.ImportModel;

import mx.formatters.NumberBaseRoundType;
import mx.formatters.NumberFormatter;

import spark.formatters.DateTimeFormatter;

import gov.lbl.aercalc.error.InvalidUnitsError;
import gov.lbl.aercalc.model.ApplicationModel;

public class Utils
	{
	
		// Colors (Move to styles eventually)
		
		public static const ROW_YELLOW:uint = 0xfffef3;
		public static const ROW_YELLOW_DARK:uint = 0xfaf9ef;

		//Hold colors here for now...
		public static const COLOR_BLUE_DARK:uint = 0x39537e;

		public static const COLOR_BLUE_1:uint = 0x7292c8;
		public static const COLOR_BLUE_2:uint = 0x4f73af;

        private static const _MAC : String = 'Mac';
        private static const _WINDOWS : String = 'Windows';
        private static const _LINUX : String = 'Linux';

        public static var epFormatter:NumberFormatter = new NumberFormatter();
		public static var ufactorFormatter:NumberFormatter = new NumberFormatter();
		public static var infiltrationFormatter:NumberFormatter = new NumberFormatter();
		public static var basicFormatter:NumberFormatter = new NumberFormatter();
		public static var dateTimeFormmater:DateTimeFormatter = new DateTimeFormatter();



		public function Utils()
		{

		}


		public static function getWindowTypeFromWindowName(windowName:String):String {

            var windowNameArr:Array = getWindowNameArr(windowName);

            //make sure base window ID is valid
            var baseWindowToken:String = windowNameArr.pop();
            if (ImportModel.VALID_BASE_CASE_WINDOW_IDS.indexOf(baseWindowToken)==-1){
                var msg:String = "Invalid base window value: " + baseWindowToken  + " for window name: " + windowName + ". Valid windows are : " + ImportModel.VALID_BASE_CASE_WINDOW_IDS.join(",");
                throw new Error(msg);
            }
			return baseWindowToken;
        }


		public static function getShadingTypeFromWindowName(windowName:String):String {
            var windowNameArr:Array = getWindowNameArr(windowName);
			var shadeTypeToken:String = windowNameArr[1];
            if (!ImportModel.isValidShadeType(shadeTypeToken)){
                var msg:String = "Invalid shade type : " + shadeTypeToken + " for window name " + windowName + ". Valid types are : " + ImportModel.getValidShadeTypes().concat();
                throw new Error(msg);
            }
			return shadeTypeToken;
		}


		/* Returns full string for attachment position, based on token in product name */
		public static function getAttachmentPositionFromWindowName(windowName:String):String {
            var windowNameArr:Array = getWindowNameArr(windowName);
            //make sure it's a valid shade type
            var attachmentPositionToken:String = windowNameArr[2];
			var attachmentPositionLabel = ImportModel.getAttachmentPositionName(attachmentPositionToken);
            if (attachmentPositionLabel==null || attachmentPositionLabel==""){
                var msg:String = 	"Invalid attachment position : " + attachmentPositionToken +
									" for product name " + windowName + ". ";
                throw new Error(msg);
            }
            return attachmentPositionLabel;
		}


        private static function getWindowNameArr(windowName:String):Array {
            var windowNameArr:Array = windowName.split("::");
            if (windowNameArr.length != 4) {
                var msg:String = "Incorrect number of suffixes in window name. There should be exactly three '::' delimiters. See documentation for details. Window name: " + windowName;
                throw new Error(msg);
            }
            return windowNameArr;
        }



		public static function initFormatters():void {
			/* Initialize static formatters */
			Utils.epFormatter.rounding = NumberBaseRoundType.NEAREST;
			// Set initial precision default, but this should be set
			// to user's preference when settings are read in during startup...
			Utils.epFormatter.precision = 0;

			Utils.ufactorFormatter.rounding = NumberBaseRoundType.NEAREST;
			Utils.ufactorFormatter.precision = 2;

			Utils.infiltrationFormatter.rounding = NumberBaseRoundType.NEAREST;
			Utils.infiltrationFormatter.precision = 2;

			Utils.basicFormatter.rounding = NumberBaseRoundType.NEAREST;
			Utils.basicFormatter.precision = 2;

			Utils.dateTimeFormmater.dateTimePattern = "hh:mm a, MM/dd/yyyy";
		}

		/*
		 Update formatters to have correct precision
		 for selected units.
		 */
		public static function setUnits(value:String):void{

			if (value!="SI" && value!="IP"){
				var errorMsg:String = "Unrecognized units: " + value;
				Logger.error(errorMsg);
				throw new InvalidUnitsError(errorMsg);
			}
			if (value=="SI"){
				Utils.infiltrationFormatter.precision = 2;
				Utils.ufactorFormatter.precision = 2;
			} else {
				Utils.infiltrationFormatter.precision = 2;
				Utils.ufactorFormatter.precision = 2;
			}
		}

		public static function normalizeEPValue(value:Number):String {
			return Utils.epFormatter.format(value * 100);
		}

		public static function roundUFactor(value:Number):String {
			return Utils.ufactorFormatter.format(value);
		}
		
		public static function roundInfiltration(value:Number):String {
			return Utils.infiltrationFormatter.format(value);
		}

		public static function roundValue(value:Number, precision:uint = 2):String {
			Utils.basicFormatter.precision = precision;
			return Utils.basicFormatter.format(value);
		}

        public static function getCurrentDateTime():String
        {
            var dateTime:Date = new Date();
            return Utils.dateTimeFormmater.format(dateTime);
        }
		
		public static function clone(source:Object):*
		{
			var myBA:ByteArray = new ByteArray();
			myBA.writeObject(source);
			myBA.position = 0;
			return(myBA.readObject());
		}
		
		public static function stripspaces(originalstring:String):String
		{
			var originalArr:Array=originalstring.split(" ");
			return(originalArr.join(""));
		}
		
		
		public static function replaceAll(originalString:String, find:String, replace:String):String
		{
			return originalString.split(find).join(replace);
		}
		
		
		//remove end of line characters AND spaces
		public static function munch(s:String):String
		{
			var l:int = s.length - 1;
			while (s.charAt(l)=="\n" || s.charAt(l)=="\r" || s.charCodeAt(l)==32)
			{
				s = s.substr(0,l);
				l--;
			}
			return s;
		}


		//remove all spaces from beginning of string
		public static function chump(s:String):String
		{
			while (s.charCodeAt(0)==32)
			{
				s = s.substr(1);
			}
			return s;
		}
		

		public static function scrubNewlines(s:String):String
		{
			var cleaned:String = s.replace(/[\u000d\u000a]+/g,""); 
			return cleaned;
		}
		
		
		public static function formatEPlusComment(s:String):String
		{
			//TODO any other changes to E+ string for a comment
			var cleaned:String = s.replace("\n","");
			return cleaned;
		}
		
		
		/* Returns array with unique values 
		* original array must be all numbers */
		public static function getUniqueValues(originalArray:Array):Array
		{
			var uniqueArr:Array = [];
			for(var idx:int=0;idx < originalArray.length;idx++)
			{
				if (isNaN(originalArray[idx]))
				{
					throw new Error("Array must contain numbers only")
				}
				var num:Number=originalArray[idx];
				if(uniqueArr.indexOf(num)==-1)
				{
					uniqueArr.push(num);
				}
			}
			return(uniqueArr);
		}
		
		
		public static function removeEmptyElementsFromEndOfArray(arr:Array):Array
		{
			
			var len:uint = arr.length;
			
			for (var i:uint=arr.length-1; i>=0;i--)
			{
				if (arr[i]==undefined || arr[i]==null || arr[i]=="")
				{
					arr.pop()
				}
				else
				{
					return arr
				}
			}
			
			return arr
		}

		
		public static function getFileNameFromPath(path:String):String {
			if (!path || path =="" || path.indexOf(File.separator)<0){
				return "";
			}
			var fileName:String = path.split(File.separator).pop();
			return fileName;

		}

		
		public static function get isMac() : Boolean
		{
			return Capabilities.os.indexOf(_MAC) >= 0;
		}
		

		public static function get isWindows() : Boolean
		{
			return Capabilities.os.indexOf(_WINDOWS) >= 0;
		}
		

		public static function get isLinux() : Boolean
		{
			return Capabilities.os.indexOf(_LINUX) >= 0;
		}
		

		public static function getOS() : String
		{
			var os : String = 'Unknown';

			if (isWindows)
				os = _WINDOWS;
			else if (isMac)
				os = _MAC;
			else if (isLinux)
				os = _LINUX;

			return os;
		}

		
		public static function get version() : String
		{
			return Capabilities.version;
		}

		/* Compare two strings that have semantic versions
		   in the form major.minor.patch

			@returns 	-1 if first version is newer
						0 if equal
						1 if second version is newer

		 */
		
		public static const FIRST_ARG_HIGHER:int = -1;
		public static const SECOND_ARG_HIGHER:int = 1;
		public static const ARGS_SAME:int = 0;

		public static function compareVersions(versionA:String, versionB:String):int {

			if (versionA==null || versionA==""){
                versionA = "0";
			}
            if (versionB==null || versionB==""){
                versionB = "0";
            }

			var v1Arr:Array = versionA.split(".");
			var v2Arr:Array = versionB.split(".");

			if (Number(v1Arr[0]) > Number(v2Arr[0])){
				return FIRST_ARG_HIGHER;
			} else if (Number(v1Arr[0]) < Number(v2Arr[0])){
				return SECOND_ARG_HIGHER;
			} else if (v1Arr.length==1 && v2Arr.length==1){
				return ARGS_SAME;
			} else {
				v1Arr.shift();
				v2Arr.shift();
				return compareVersions(v1Arr.join("."), v2Arr.join("."));
			}

		}
		
		/*
		Since the naming conventions are not valid windows filenames this is a way
		to convert them to names that are.
		*/
		public static function makeUsableAsAFilename(s:String):String{
			var _globalColonPattern:RegExp = /:/g;
			return s.replace(_globalColonPattern, "_");
		}
		
		/*
		Since the naming conventions are not valid windows filenames this is a way
		to convert them to names that are.
		*/
		public static function makeUsableAsAnEPlusField(s:String):String{
			var _globalColonPattern:RegExp = /,/g;
			return s.replace(_globalColonPattern, "_");
		}
			


	}
}