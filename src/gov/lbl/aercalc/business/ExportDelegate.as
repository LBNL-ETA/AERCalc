/**
 * Created by danie on 27/02/2017.
 */
package gov.lbl.aercalc.business {

import gov.lbl.aercalc.util.Logger;

import flash.filesystem.File;
import flash.filesystem.FileMode;

import mx.collections.ArrayCollection;

import spark.formatters.DateTimeFormatter;

import gov.lbl.aercalc.model.domain.WindowVO;

public class ExportDelegate {


    // List of property names that we export
    // Make sure these are in the order you want them
    // to appear in the generated csv
    // Include title for the csv column head, the property name, and whether
    // to escape the delimiter if it appears in property value
    private var _exportColumns:Array = [
        {
            title: "AERCalc Record ID",
            varName: "id",
            escapeDelimiter: false,
            includeInParentRow: true,
            blankIfZero: false
        },
        {
            title: "Parent ID",
            varName: "parent_id",
            escapeDelimiter: false,
            includeInParentRow: true,
            blankIfZero: true
        },
        {
            title: "Parent/Child",
            varName: "parentChildType",
            escapeDelimiter: false,
            includeInParentRow: true,
            blankIfZero: false
        },
        {
            title: "CGDB Version",
            varName: "cgdbVersion",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "Simulated Product Name",
            varName: "name",
            escapeDelimiter: true,
            includeInParentRow: true,
            blankIfZero: false
        },
        {
            title: "W7 ID",
            varName: "W7ID",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "W7 Glz Sys ID",
            varName: "W7GlzSysID",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "CGDB ID",
            varName: "W7ShdSysID",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "Shading System Type",
            varName: "shadingSystemType",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "AERC Baseline Window Type",
            varName: "baseWindowType",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "U-factor",
            varName: "UvalWinter",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "SHGC",
            varName: "SHGC",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "VT",
            varName: "Tvis",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "TvT",
            varName: "TvT",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: true
        },
        {
            title: "AL",
            varName: "airInfiltration",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "EPc Ratio",
            varName: "epc",
            escapeDelimiter: false,
            includeInParentRow: true,
            blankIfZero: true
        },
        {
            title: "EPh Ratio",
            varName: "eph",
            escapeDelimiter: false,
            includeInParentRow: true,
            blankIfZero: true
        },
        {
            title: "EPc",
            varName: "epcNormalized",
            escapeDelimiter: false,
            includeInParentRow: true,
            blankIfZero: true
        },
        {
            title: "EPh",
            varName: "ephNormalized",
            escapeDelimiter: false,
            includeInParentRow: true,
            blankIfZero: true
        },
        {
            title: "WINDOW Origin DB Filepath",
            varName: "WINDOWOriginDB",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false

        },
        {
            title: "THERM Files",
            varName: "THERMFiles",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "Manufacturer",
            varName: "shadingSystemManufacturer",
            escapeDelimiter: true,
            includeInParentRow: true,
            blankIfZero: false
        },
        {
            title: "Material Manufacturer",
            varName: "shadingMaterialManufacturer",
            escapeDelimiter: false,
            includeInParentRow: true,
            blankIfZero: false
        },
        {
            title: "AERCalc Version",
            varName: "AERCalcVersion",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "WINDOW Version",
            varName: "WINDOWVersion",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "EnergyPlus Version",
            varName: "EPlusVersion",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "ESCalc Version",
            varName: "ESCalcVersion",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "BSDF",
            varName: "hasBSDF",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "Status",
            varName: "versionStatus",
            escapeDelimiter: true,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "AERC ID",
            varName: "userID",
            escapeDelimiter: false,
            includeInParentRow: true,
            blankIfZero: false
        },
        {
            title: "Emissivity Front",
            varName: "Emishout",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "Emissivity Back",
            varName: "Emishin",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "Tsol",
            varName: "Tsol",
            escapeDelimiter: false,
            includeInParentRow: false,
            blankIfZero: false
        },
        {
            title: "Attachment Position",
            varName: "attachmentPosition",
            escapeDelimiter: true,
            includeInParentRow: true,
            blankIfZero: false
        }
    ];

	public function getColumnsDefs():Array {
		return _exportColumns
	}
	
	/* Util function just to help get column info */
	public function getColumnIndex(varName:String):int {
		var numCols:uint = _exportColumns.length;
		for (var colIndex:uint=0; colIndex<numCols; colIndex++){
			if (_exportColumns[colIndex].varName==varName){
				return colIndex;
			}
		}
		return -1;
	}

    public function ExportDelegate() {
    }

    /*  Take windows provided in argument and return one csv-based string,
        including a header row as first row.

        @param windowsAC             ArrayCollection of WindowVOs to export to csv.
        @param delimiter             String value. Delimiter to use, defaults to comma
        @param includeHeaderInfo     Boolean value. If true, write out some meta-data at top of csv. Defaults to false

        @return String containing csv data.

     */
    public function getCSVFromWindows(windowsAC:ArrayCollection, delimiter:String = "", includeHeaderInfo:Boolean = false):String{

        var exportStr:String = "";
        var delimiter:String = ",";
        var fileName:String = "";

        // Write meta-data header if required
        Logger.debug("Exporting csv at : " + exportDateTime);
        if (includeHeaderInfo){
            var formatter:DateTimeFormatter = new DateTimeFormatter();
            formatter.dateTimePattern = "hh:mm a, MM/dd/yyyy";
            var exportDateTime:String = formatter.format(new Date());
            exportStr += "Date Created: " + exportDateTime + File.lineEnding;
            exportStr += "Number of Windows: " + windowsAC.length.toString() + File.lineEnding;
        }

        var numWindows:uint = windowsAC.length;
        var numCols:uint = _exportColumns.length;

        //write column headers
        for (var colIndex:uint = 0; colIndex<numCols; colIndex++){

            var title:String = _exportColumns[colIndex].title;

            //Avoid SYLK bug in Excel. See https://support.microsoft.com/en-us/help/323626/-sylk-file-format-is-not-valid-error-message-when-you-open-file
            if (colIndex==0 && title=="ID"){
                title = "id";
            }

            exportStr += title;
            if (colIndex<numCols-1) {
                exportStr += ",";
            }
            else {
                exportStr += File.lineEnding;
            }
        }

        // write a row for each window, only writing the window properties
        // that are defined in this class
        for (var rowIndex:uint = 0; rowIndex < numWindows; rowIndex ++) {

            var rowData:String = "";
            var currWindow:WindowVO = windowsAC[rowIndex]as WindowVO;
            exportStr += writeWindowAsCSVLine(currWindow);
            if (currWindow.isParent && currWindow.isOpen){
				var numChildren:uint = currWindow.children.length;
                for (var childRowIndex:uint = 0; childRowIndex < numChildren; childRowIndex++){
                    exportStr += writeWindowAsCSVLine(currWindow.children[childRowIndex]);
                }
            }
        }

        return exportStr;
    }

    /* Write window properties as a line of csv */
    private function writeWindowAsCSVLine(currWindow:WindowVO):String {

        var rowData:String = "";
        var numCols:uint = _exportColumns.length;

        for (var colIndex:uint = 0; colIndex < numCols; colIndex++) {

            var colData:Object = _exportColumns[colIndex];
            var value:String = currWindow[colData.varName];

            if (currWindow.isParent){
                if (colData.varName == "attachmentPosition"){
                    var value:String = currWindow.getChildAttachmentPosition();
                }
                if (colData.varName == "shadingSystemManufacturer"){
                    value = currWindow.getChildShadingSystemManufacturer();
                }
                if (colData.varName == "shadingMaterialManufacturer"){
                    value = currWindow.getChildShadingMaterialManufacturer();
                }
                if (colData.includeInParentRow==false) {
                    value = "";
                }
            }

            if (value=="0" && colData.blankIfZero){
                value= "";
            }

            if (value!="" && colData.escapeDelimiter) {
                value = escapeValueForCSV(value);
            }
            rowData += value;
            if (colIndex<numCols-1) {
                rowData += ",";
            }
            else {
                rowData += File.lineEnding;
            }
        }

        return rowData;
    }

    /*  Escape a value for CSV export. We follow these rules:
        - If the value contains a comma, newline or double quote, then the String value should be returned enclosed in double quotes.
        - Any double quote characters in the value should be escaped with another double quote.
        - Remove any newlines.
     */
    private function escapeValueForCSV(originalString:String):String {
        var newString:String = originalString.replace("\"", "\\\"");
        if (newString.indexOf("\n")>-1){
            newString = newString.split("\n").join(". ");
        }
        return '"' + newString + '"';
    }


}
}
