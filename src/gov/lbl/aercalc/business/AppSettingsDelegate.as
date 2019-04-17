
package gov.lbl.aercalc.business {
import com.googlecode.flexxb.core.FxBEngine;
import gov.lbl.aercalc.util.Logger;

import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;

import gov.lbl.aercalc.util.Utils;

import mx.logging.LogEventLevel;

import spark.components.Alert;

import gov.lbl.aercalc.events.ApplicationEvent;
import gov.lbl.aercalc.model.ApplicationModel;
import gov.lbl.aercalc.model.settings.AppSettings;
import gov.lbl.aercalc.util.AboutInfo;

public class AppSettingsDelegate {


    public function AppSettingsDelegate() {
    }

	
    /*  Load app settings if one exists, otherwise create a new
        appSettings object with defaults set. */
    public function load():AppSettings {

        var settingsFile:File = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.APP_SETTINGS_FILE_PATH);
        var appSettings:AppSettings;
        if (settingsFile.exists)
        {
            var stream:FileStream = new FileStream();
            stream.open(settingsFile, FileMode.READ);
			if (stream.bytesAvailable>0){
				var xml:XML = XML(stream.readUTFBytes(stream.bytesAvailable));
				stream.close();
				try {
					appSettings = parseAppSettings(xml);
				} catch(error:Error){
					Logger.error("Couldn't parse app settings. Using default settings. Error:" + error, this);
					Alert.show("Couldn't load app settings (see log for details). Using default settings...", "Settings Error");
					appSettings = getDefaults();
				}	
			} else {
				appSettings = getDefaults();
			}       					
        }
        else
        {
            appSettings = getDefaults();           
        }

        // Do any setup or init of static helpers and such that need to know about
        // user settings
        Utils.epFormatter.precision = appSettings.epPrecision;

        return appSettings;
    }

    public function save(appSettings:AppSettings):void {
        try
        {
			// get string xml of settings
			var settingsXML:XML = settingsToXml(appSettings);
			Logger.debug("settingsXML: " + settingsXML);
			var settings:String = settingsXML.toString();
			
			// save out xml string to file
            var settingsFile:File = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.APP_SETTINGS_FILE_PATH);
            var stream:FileStream = new FileStream();
            stream.open(settingsFile, FileMode.WRITE);
			stream.writeUTFBytes(settings);
            stream.close();
        }
        catch (e:Error)
        {
            Logger.warn("Couldn't save settings: " + e.toString());
        }
    }

    /* Deserialize xml into AppSettings. Handle any missing or incorrectedly serialized values */
    private function parseAppSettings(xml:XML):AppSettings {
        var result:AppSettings = FxBEngine.instance.getXmlSerializer().deserialize(xml, AppSettings) as AppSettings;
        //set some sane defaults
        if (!result.lblWindowDBPath || result.lblWindowDBPath == "") {
            result.lblWindowDBPath = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.WINDOW_DEFAULT_MDB_FILE_PATH).nativePath;
        }
        return result;
    }
    private function settingsToXml(settings:AppSettings):XML
    {
        var result:XML = FxBEngine.instance.getXmlSerializer().serialize(settings) as XML;
        return result;
    }
		
	/* Build some reasonable defaults for app settings */
	private function getDefaults():AppSettings {
		var appSettings:AppSettings = new AppSettings();
		appSettings.lblWindowDBPath = ApplicationModel.baseStorageDir.resolvePath(ApplicationModel.WINDOW_MDB_FILE_PATH).nativePath;
		appSettings.logEventLevel = LogEventLevel.DEBUG;
		return appSettings;
	}
	


}
}
