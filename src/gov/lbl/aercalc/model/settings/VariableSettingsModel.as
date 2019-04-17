package gov.lbl.aercalc.model.settings
{
import gov.lbl.aercalc.model.*;


import gov.lbl.aercalc.util.Logger;
import gov.lbl.aercalc.model.settings.VariableSettingsVO;

public class VariableSettingsModel
{

    private var varGroupsArr:Array;

    public function VariableSettingsModel()
    {
    }

    [PostConstruct]
    public function onPostConstruct():void {

        this.init();

        //TODO AERCalc should load these from external file, as COMFEN does

        Logger.debug("Initializing variable settings");

        //UValue
        var vo:VariableSettingsVO = new VariableSettingsVO();
        vo.type     = "app";
        vo.name     = "UvalWinter";
        vo.SI_short = "W/m2-K";
        vo.SI_long  = "W/m2-K";
        vo.IP_short = "Btu/h-ft2-F";
        vo.IP_long  = "Btu/h-ft2-F";
        vo.displayDecimals_SI = 2;
        vo.displayDecimals_IP = 2;
        addVarSettingsVO(vo);
		
		//Air Infiltration
		var infil:VariableSettingsVO = new VariableSettingsVO();
		infil.type     = "app";
		infil.name     = "Infiltration";
		infil.SI_short = "m3/sm2";
		infil.SI_long  = "m3/sm2";
		infil.IP_short = "cfm/ft2";
		infil.IP_long  = "cfm/ft2";
		infil.displayDecimals_SI = 2;
		infil.displayDecimals_IP = 2;
		addVarSettingsVO(infil);


    }

    private function init():void
    {
        varGroupsArr = [];
    }

    public function addVarSettingsVO(varSettingsVO:VariableSettingsVO):void
    {
        if (varSettingsVO.type==""){
            varSettingsVO.type="app";
        }

        if (varGroupsArr[varSettingsVO.type] == null) {
            varGroupsArr[varSettingsVO.type] = new Array();
        }

        varGroupsArr[varSettingsVO.type][varSettingsVO.name] =  varSettingsVO;
    }

    /** Gets the string description of units (e.g. W/m.sq ) for a certain field
     *
     * @param 		fieldName the name of the field, as defined in static variables within this class
     * @type 		group type for variable, if available
     * @length 		length of the string ("short" or "long" ... e.g. ft. or feet)
     * @returnUnits SI or IP ...used to override the currUnits defined in ApplicationModel
     *
     * */

    public function getUnits(fieldName:String, type:String="app", length:String="short", returnUnits:String=null):String
    {
        if (type=="")
        {
            Logger.warn("getUnits() type argument was empty,setting to app",this);
            type="app";
        }
        if (fieldName=="")
        {
            Logger.warn("getUnits() fieldName argument was empty",this);
            return "";
        }

        try {
            var varSettingsVO:VariableSettingsVO = VariableSettingsVO(varGroupsArr[type][fieldName]);

            if (varSettingsVO==null)
            {
                Logger.error("getUnits() can't find units for type: " + type + " fieldName: " + fieldName, this);
                return "";
            }

            if (length!="short" && length!="long")
            {
                Logger.error("getUnits() length argument must be 'short' or 'long'", this);
                return "";
            }

            //use user's units if units aren't passed in as argument
            if (returnUnits!="SI" && returnUnits!="IP")
            {
                returnUnits = ApplicationModel.currUnits;
            }

            return varSettingsVO[returnUnits + "_" + length];
        }
        catch (err:Error)
        {
            Logger.error("getUnits() error when searching for units on type: " + type + " fieldName: " + fieldName + " error :" + err, this);
        }

        return null;
    }

    /** Gets the min value for a property
     *
     * @param 		fieldName the name of the field, as defined in static variables within this class
     * @type 		group type for variable, if available
     * @returnUnits SI or IP ...used to override the currUnits defined in CModelLocator
     *
     * */

    public function getMin(fieldName:String, type:String="app", returnUnits:String=null):Number
    {

        var varSettingsVO:VariableSettingsVO = VariableSettingsVO(varGroupsArr[type][fieldName]);

        if (varSettingsVO==null)
        {
            Logger.error("getMin() can't find unitsVO for fieldName: " + fieldName, this);
            return 0;
        }

        //use user's units if units aren't passed in as argument
        if (returnUnits!="SI" && returnUnits!="IP")
        {
            returnUnits = ApplicationModel.currUnits;
        }

        var min:Number = varSettingsVO[returnUnits + "_min"];
        if (isNaN(min))
        {
            Logger.warn("getMin() for " + fieldName + " isNaN. returning 0", this);
            min = 0;
        }

        return min;
    }


    /** Gets the max value for a property
     *
     * @param 		fieldName the name of the field, as defined in static variables within this class
     * @returnUnits SI or IP ...used to override the currUnits defined in CModelLocator
     *
     * */

    public function getMax(fieldName:String, type:String="app", returnUnits:String=null):Number
    {
        var varSettingsVO:VariableSettingsVO = VariableSettingsVO(varGroupsArr[type][fieldName]);

        if (varSettingsVO==null)
        {
            Logger.error("getMax() can't find unitsVO for fieldName: " + fieldName, this);
            return 0;
        }

        //use user's units if units aren't passed in as argument
        if (returnUnits!="SI" && returnUnits!="IP")
        {
            returnUnits = ApplicationModel.currUnits;
        }

        var max:Number = varSettingsVO[returnUnits + "_max"];

        if (isNaN(max))
        {
            Logger.warn("getMax() for " + fieldName + " isNaN. returning 100", this);
            max = 100;
        }

        return max;
    }


    public function getVarSettingsVO(group:String, varSettingsName:String):VariableSettingsVO
    {
        var arr:Array = varGroupsArr[group];
        if (arr)
        {
            return arr[varSettingsName];
        }
        Logger.warn("Couldn't find " + varSettingsName + " in group " + group, this);
        return null;
    }







}
}
