package gov.lbl.aercalc.view.settings {

    import flash.events.EventDispatcher;
    
    import spark.components.VGroup;
    
    import gov.lbl.aercalc.events.SettingsEvent;
    import gov.lbl.aercalc.model.settings.AppSettings;

    public class SettingsEditor extends VGroup
    {
        public function SettingsEditor()
        {
            super();
        }

        private var _settings:AppSettings;
        private var settingsChanged:Boolean = false;

		[Bindable]
        [Inject(source="settingsModel.editableSettings", bind="true")]
        public function get settings():AppSettings {
            return _settings;
        }
		
		[Dispatcher]
		public var dispatcher:EventDispatcher;
		
        public function set settings(value:AppSettings):void {
            if(_settings != value) {
                _settings = value;
                settingsChanged = true;
                invalidateProperties();
				if(dispatcher){
					dispatcher.dispatchEvent(new SettingsEvent(SettingsEvent.SETTINGS_CHANGED, true));
				}
            }
        }


        protected override function commitProperties():void {
            super.commitProperties();
            if(settingsChanged) {
                settingsChanged = false;
                if(settings) {
                    read(settings);
                }
            }
        }


        protected function read(settings:AppSettings):void {
        }


        protected function write(settings:AppSettings):void {
        }


        protected function onChange():void
        {
            if(settings)
                write(settings);
        }
    }
}
