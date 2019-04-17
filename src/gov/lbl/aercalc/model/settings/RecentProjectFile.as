package gov.lbl.aercalc.model.settings
{
	[XmlClass(alias="file")]
	[RemoteClass]
	public class RecentProjectFile
	{
		[XmlElement]
		public var name:String;
		
		[XmlElement]
		public var path:String;
		
		public function RecentProjectFile(name:String = null, path:String = null)
		{
			this.name = name;
			this.path = path;
		}
	}
}

