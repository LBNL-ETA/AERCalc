/**
 * Created by danie on 27/02/2017.
 */
package gov.lbl.aercalc.controller {
import gov.lbl.aercalc.util.Logger;

import flash.events.Event;

import flash.events.IEventDispatcher;

import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;

import gov.lbl.aercalc.business.ExportDelegate;
import gov.lbl.aercalc.events.ExportEvent;
import gov.lbl.aercalc.model.LibraryModel;

import spark.components.Alert;

public class ExportController {


    [Inject]
    public var libraryModel:LibraryModel;

    [Inject]
    public var exportDelegate:ExportDelegate;

    [Dispatcher]
    public var dispatcher:IEventDispatcher;


    public function ExportController() {
    }


    /*  Export all available windows as csv
        We may later update this method to allow user to select subset of all windows,
        or perhaps select other export formats. This method expects the PM to have already
        set isOpen property on parent rows in model to match state of UI.
     */
    [EventHandler(event="ExportEvent.DO_EXPORT_WINDOWS")]
    public function doExportWindows():void{

        if (libraryModel.windowsAC==null || libraryModel.windowsAC.length==0){
            Alert.show("There are windows to export. Please import windows from W7 first.", "No Windows Available", Alert.OK);
            return;
        }

        // default to documents directory
        // TODO: remember last export directory and open browseForFile there.
        var exportDirectory:File = File.documentsDirectory;
        var exportFile:File = exportDirectory.resolvePath("aercalc-export.csv");
        exportFile.browseForSave("Export to csv");
        exportFile.addEventListener(Event.SELECT, onDoExportToCSV, false, 0, true);
        exportFile.addEventListener(Event.CANCEL, onCancel, false, 0, true);

    }

    private function onDoExportToCSV(event:Event):void{

        var targetFile:File = event.target as File;

        //Generate csv contents
        try {
            var csvContent:String = exportDelegate.getCSVFromWindows(libraryModel.windowsAC);
        } catch (error:Error){
            var errorMsg:String = "Couldn't generate csv contents from windows list: " +error;
            Logger.error(errorMsg, this);
            Alert.show(errorMsg + ". Please check the log for details and contact support.", "Export Error", Alert.OK);
            return;
        }

        //Write to file
        try {
            var stream:FileStream = new FileStream();
            stream.open(targetFile, FileMode.WRITE);
            stream.writeUTFBytes(csvContent);
            stream.close();
        }
        catch(error:Error) {
            errorMsg = "Couldn't write csv file. Error: " + error;
            Logger.error(errorMsg, this);
            Alert.show(errorMsg + ". Please check the log for details and contact support.", "Export Error", Alert.OK);
            //make sure stream is closed.
            stream.close();
            return;
        }

        Alert.show("CSV file export complete. The file was saved here: " + targetFile.nativePath, "Export complete", Alert.OK);

        //Let everyone know we're done.
        var completeEvt:ExportEvent = new ExportEvent(ExportEvent.EXPORT_WINDOWS_COMPLETE);
        dispatcher.dispatchEvent(completeEvt);
    }

    private function onCancel(event:Event):void
    {
        // do nothing at this point.


    }

}
}
