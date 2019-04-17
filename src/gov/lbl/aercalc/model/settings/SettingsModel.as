package gov.lbl.aercalc.model.settings
{
	import gov.lbl.aercalc.util.CopyUtil;
	import gov.lbl.aercalc.model.settings.AppSettings;

	public class SettingsModel
	{
		[Bindable]
		public var editableSettings:AppSettings;
				
		[Inject]
		[Bindable]
		public var appSettings:AppSettings;
		
		public function SettingsModel()
		{
		}
				
		public function beginEdit():void
		{
			editableSettings = CopyUtil.clone(appSettings) as AppSettings;
		}		
		
		public function commit():void
		{
			CopyUtil.copyFrom(editableSettings, appSettings);
			editableSettings = null;
		}
		
		public function cancel():void
		{
			editableSettings = null;
		}
		
	}
}