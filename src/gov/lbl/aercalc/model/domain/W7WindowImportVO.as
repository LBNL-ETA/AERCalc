package gov.lbl.aercalc.model.domain
{

import gov.lbl.aercalc.util.Conversions;
import flash.events.Event;
import gov.lbl.aercalc.error.InvalidImportWindowNameError;
import gov.lbl.aercalc.model.ImportModel;
import gov.lbl.aercalc.util.Utils;

[Bindable]
public class W7WindowImportVO extends BaseUnitsVO
{
    // W7 Window ID
    public var W7ID:String = "";
    // W7 Glazing System ID
    public var W7GlzSysID:String = "";
    public var W7ShdSysID:String = "";
    public var cgdbVersion:String = "";

    //attachment type
    public var _type:String = "";
    public var _height:Number = 0;
    public var _width:Number = 0;
    public var _UvalWinter:Number = 0;
    public var _chromogenicControlCostOverride:Number = -1;
    public var _defaultTotalCost:Number = 0;
    public var _totalCostOverride:Number = -1;

    public var importState:String = "";
    //extra information about why we're having trouble importing this glz sys from W7
    public var errorMessage:String = "";
    public var shadingSystemType:String = "";
    public var attachmentPosition:String = "";
    public var shadingSystemManufacturer:String = "";
    public var shadingMaterialManufacturer:String = "";
    public var baseWindowType:String;
    public var THERMFiles:String = "";
    public var WINDOWVersion:String = "";

    public var Tsol:Number = 0;
    public var Emishin:Number = 0;
    public var Emishout:Number = 0;

    protected var _name:String = "";
    protected var _tilt:Number = 0;
    protected var _envConditions:Number = 0;
    protected var _comment:String = "";
    protected var _certification:String = "";
    protected var _status:int = 0;
    protected var _SHGC:Number = 0;
    protected var _Tvis:Number = 0;
    protected var _TvT:Number = 0;
    protected var _chromogenicShadingControlID:uint;

    public function getBSDFFileName():String {
        return "w_" + this.W7ID.toString() + ".bsdf";
    }

    public function W7WindowImportVO(){}


    /* This is a pseudo-property used mainly to show "invalid" markers in the library list. Much simpler to use this as a flag
     than to look up a glazing system and see if it has an EMPTY layer or other invalidating quality when the ArrayCollection is shown in a list */
    [Transient]
    public var hasEmptyLayer:Boolean = false;

    /* GETTERS AND SETTERS */


    /* This method is somewhat involved as the name (for the moment) has encoded meta data
       such as what window, shading system type etc.

     */
    public function set name(value:String):void
    {
        value = Utils.scrubNewlines(value);
        _name = value;
    }
    public function get name():String
    {
        return _name
    }


    /* Set the shade type and base window type by parsing the name for expected suffixes.
     */
    public function setPropsByWindowName():void {
        try{
            shadingSystemType = Utils.getShadingTypeFromWindowName(this.name);
        } catch(error:Error){
            var msg:String = "Invalid shading type name. " + error.message;
            throw new InvalidImportWindowNameError(msg);
        }
        try {
            baseWindowType = Utils.getWindowTypeFromWindowName(this.name);
        } catch(error:Error){
            msg = "Invalid base window name. " + error.message;
            throw new InvalidImportWindowNameError(msg);
        }
        try {
            attachmentPosition = Utils.getAttachmentPositionFromWindowName(this.name);
        } catch(error:Error){
            var msg:String = "Invalid shading type name. " + error.message;
            throw new InvalidImportWindowNameError(msg);
        }
    }


    [Column(name='chromogenic_shading_control_id')]
    public function get chromogenicShadingControlID():int
    {
        return _chromogenicShadingControlID
    }
    public function set chromogenicShadingControlID(value:int):void
    {
        _chromogenicShadingControlID = value
    }

    public function get comment():String
    {
        return _comment
    }
    public function set comment(value:String):void
    {
        _comment = value
    }

    public function get tilt():Number
    {
        return _tilt
    }
    public function set tilt(value:Number):void
    {
        _tilt = value
    }


    public function get envConditions():Number
    {
        return _envConditions
    }
    public function set envConditions(value:Number):void
    {
        _envConditions = value
    }


    public function get certification():String
    {
        return _certification
    }
    public function set certification(value:String):void
    {
        _certification = value
    }


    public function get status():int
    {
        return _status
    }
    public function set status(value:int):void
    {
        _status = value
    }


    [Transient]
    public function get type():String
    {
        return _type
    }
    public function set type(value:String):void
    {
        _type = value
    }

    public function get SHGC():Number
    {
        return _SHGC
    }
    public function set SHGC(value:Number):void
    {
        _SHGC = value
    }

    public function get Tvis():Number
    {
        return _Tvis
    }
    public function set Tvis(value:Number):void
    {
        _Tvis = value
    }

    public function get TvT():Number
    {
        return _TvT
    }
    public function set TvT(value:Number):void
    {
        _TvT = value
    }

    [Transient]
    public function get height():Number
    {
        if (currUnits=="SI")
        {
            return _height
        }
        else
        {
            return Conversions.metersToFeet(_height) 		//TODO: Conversion
        }
    }
    public function set height(value:Number):void
    {
        if (currUnits=="SI")
        {
            _height = value
        }
        else
        {
            _height = Conversions.feetToMeters(value)
        }
    }


    [Transient]
    public function get width():Number
    {
        if (currUnits=="SI")
        {
            return _width
        }
        else
        {
            return Conversions.metersToFeet(_width)
        }
    }
    public function set width(value:Number):void
    {
        if (currUnits=="SI")
        {
            _width = value
        }
        else
        {
            _width = Conversions.feetToMeters(value)
        }
    }


    [Transient]
    public function get UvalWinter():Number
    {
        if (currUnits=="SI")
        {
            return _UvalWinter
        }
        else
        {
            return Conversions.WattsPerSqMCelToBtuPerHourSqFtFahr(_UvalWinter)
        }
    }
    public function set UvalWinter(value:Number):void
    {
        if (currUnits=="SI")
        {
            _UvalWinter = value
        }
        else
        {
            _UvalWinter =  Conversions.BtuPerHourSqFtFahrToWattsPerSqMCel(value)
        }
    }


    [Transient]
    public function get defaultTotalCost():Number
    {
        if (currUnits=="SI")
        {
            return _defaultTotalCost
        }
        else
        {
            return Conversions.costPerSqMToCostPerSqFt(_defaultTotalCost)
        }
    }
    public function set defaultTotalCost(value:Number):void
    {
        if (currUnits=="SI")
        {
            _defaultTotalCost = value
        }
        else
        {
            _defaultTotalCost = Conversions.costPerSqFtToCostPerSqM(value)
        }
    }


    [Transient]
    public function get chromogenicControlCostOverride():Number
    {
        if (currUnits=="SI")
        {
            return _chromogenicControlCostOverride
        }
        else
        {
            return Conversions.costPerSqMToCostPerSqFt(_chromogenicControlCostOverride)
        }
    }
    public function set chromogenicControlCostOverride(value:Number):void
    {
        if (currUnits=="SI")
        {
            _chromogenicControlCostOverride = value
        }
        else
        {
            _chromogenicControlCostOverride = Conversions.costPerSqFtToCostPerSqM(value)
        }
        dispatchEvent(new Event("glazingSystemTotalCostChange", true))
    }


    [Transient]
    public function get totalCostOverride():Number
    {
        if (currUnits=="SI")
        {
            return _totalCostOverride
        }
        else
        {
            return Conversions.costPerSqMToCostPerSqFt(_totalCostOverride)
        }
    }
    public function set totalCostOverride(value:Number):void
    {
        if (currUnits=="SI")
        {
            _totalCostOverride = value
        }
        else
        {
            _totalCostOverride = Conversions.costPerSqFtToCostPerSqM(value)
        }
    }


    public function getBaseName():String {
        return this.name.split("::")[0];
    }

    public function isBlind():Boolean {
        return (ImportModel.isBlind(shadingSystemType));
    }

}
}