package gov.lbl.aercalc.model.settings
{


public class VariableSettingsVO
{
    public var name:String = "";
    public var type:String = ""; //glass, gas, etc.

    public var SI_long:String= "";
    public var SI_short:String	= "";
    public var IP_long:String= "";
    public var IP_short:String= "";

    public var SI_min:Number = 0;
    public var SI_max:Number = 100;
    public var IP_min:Number = 0;
    public var IP_max:Number = 100;

    public var displayDecimals_SI:Number = 2;
    public var displayDecimals_IP:Number = 2;

    public var toolTip:String = "";

    public var lowerThanMinError:String = "";
    public var exceedsMaxError:String = "";

    public function VariableSettingsVO()
    {
    }

    public function getDisplayDecimals(units:String):Number
    {
        if (units=="SI")
        {
            return displayDecimals_SI
        }
        else
        {
            return displayDecimals_IP
        }
    }

}
}
