package gov.lbl.aercalc.util
{
	import flash.system.Capabilities;
	
	public class CapabilitiesUtils
	{
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
		
		private static const _MAC : String = 'Mac';
		
		private static const _WINDOWS : String = 'Windows';
		
		private static const _LINUX : String = 'Linux';		
	}
}



// ActionScript file