package gov.lbl.aercalc.util
{
	import flash.desktop.NativeApplication;
	import flash.system.Capabilities;
	
	public class AboutInfo
	{
		
		
		public function AboutInfo()
		{
			
			
		}
		
		public static function get applicationVersion():String
		{			
			
			var appXML:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var air:Namespace = appXML.namespaceDeclarations()[0];
			var version:String = appXML.air::versionNumber;
			
			if (version.indexOf("v") == 0) version = version.substr(1);
			return version;
		}
		
		public static function get flashPlayerVersion():String
		{
			return Capabilities.version
		}
		
		
	}
}

