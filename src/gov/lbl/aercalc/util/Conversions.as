package gov.lbl.aercalc.util {

/* Holds conversions for units used in AERCalc  */

public class Conversions
{
    public function Conversions()
    {}

    //SI
    public static var UNITS_METERS:String = "m";
    public static var UNITS_CENTIMETERS:String = "cm";
    public static var UNITS_MILLIMETERS:String = "cm";

    //IP
    public static var UNITS_FEET:String = "ft";
    public static var UNITS_INCHES:String = "ft";

    public static const M3_PER_MJ:Number = 0.0268;

    /* CONVERSION FUNCTIONS */


    public static function celciusToFahr(value:Number):Number
    {
        return (  1.8 * value)  + 32;
    }

    public static function fahrToCelcius(value:Number):Number
    {
        return 0.555555556*(value-32);
    }

    public static function metersToFeet(value:Number):Number
    {
        return value * 3.2808399;
    }

    public static function feetToMeters(value:Number):Number
    {
        return value * 0.3048;
    }

    public static function metersToInches(value:Number):Number
    {
        return value * 39.3700787;
    }

    public static function inchesToMeters(value:Number):Number
    {
        return value *  0.0254;
    }







    //COSTS

    public static function costPerSqFtToCostPerSqM(value:Number):Number
    {
        return value * 10.7639104;
    }

    public static function costPerSqMToCostPerSqFt(value:Number):Number
    {
        return value / 10.7639104;
    }


    public static function costPerKWHToCostPerMJoule(value:Number):Number
    {
        return value / 3.6;
    }

    public static function costPerMJouleToCostPerKWH(value:Number):Number
    {
        return value * 3.6;
    }



    public static function costPerM3ToCostPerTherm(value:Number):Number
    {
        return value / 0.361975333;
    }

    public static function costPerThermToCostPerM3(value:Number):Number
    {
        return value * 0.361975333;
    }



    public static function costPerM3ToCostPerThousandFt3(value:Number):Number
    {
        return value * 28.32;
    }

    public static function costPerThousandFt3ToCostPerM3(value:Number):Number
    {
        return value / 28.32;
    }


    public static function costPerTonToCostPerKW(value:Number):Number
    {
        return value / 3.517;
    }

    public static function costPerKWToCostPerTon(value:Number):Number
    {
        return value * 3.517;
    }



    public static function costPerTonToCostPerKBTU(value:Number):Number
    {
        return value / 12;
    }

    public static function costPerKBTUToCostPerTon(value:Number):Number
    {
        return value * 12;
    }


    public static function costPerKBTUHRToCostPerKW(value:Number):Number
    {
        return value / 0.2930711;
    }

    public static function costPerKWToCostPerKBTUHR(value:Number):Number
    {
        return value * 0.2930711;
    }










    public static function wattsSqFtToWattsSqM(value:Number):Number
    {
        return value / 0.09290304;
    }

    public static function wattsSqMToWattsSqF(value:Number):Number
    {
        return value / 10.7639104;
    }

    public static function squareFeetToSquareMeters(value:Number):Number
    {
        return value * 0.09290304;
    }

    public static function squareMetersToSquareFeet(value:Number):Number
    {
        return value * 10.7639104;
    }

    public static function inchesToCentimeters(value:Number):Number
    {
        return 2.54 * value;
    }

    public static function inchesToMillimeters(value:Number):Number
    {
        return 25.4 * value;
    }

    public static function inchesToFeet(value:Number):Number
    {
        return value * 0.0833333333;
    }

    public static function centimetersToInches(value:Number):Number
    {
        return value * 0.393700787;
    }

    public static function millimetersToInches(value:Number):Number
    {
        return value * 0.0393700787;
    }

    public static function millimetersToMeters(value:Number):Number
    {
        return value / 1000;
    }


    public static function metersToMillimeters(value:Number):Number
    {
        return value * 1000;
    }


    public static function millimetersToFeet(value:Number):Number
    {
        return value * .0032808399;
    }

    public static function centimetersToFeet(value:Number):Number
    {
        return value * 0.032808399;
    }

    public static function centimetersToMeters(value:Number):Number
    {
        return value * 100;
    }

    public static function metersToCentimeters(value:Number):Number
    {
        return value / 100;
    }


    public static function joulesToBTU(value:Number):Number
    {
        return value * 0.000948;
    }


    public static function BTUToJoules(value:Number):Number
    {
        return value / 0.000948;
    }

    public static function joulesToKBTU(value:Number):Number
    {
        return value * 0.000000948;
    }

    public static function kBTUtoJoules(value:Number):Number
    {
        return value / 0.000000948;
    }

    public static function joulesToKWH(value:Number):Number
    {
        return value * 0.000000278;
    }

    public static function kWHToJoules(value:Number):Number
    {
        return value / 0.000000278;
    }

    public static function megaJoulesToKBTU(value:Number):Number
    {
        return value * 0.947867299;
    }



    public static function megaJoulesPerSqMeterToKBTUPerSqFt(value:Number):Number
    {
        value = megaJoulesToKBTU(value);	//convert from MJ/m2 to kBtu/m2
        value = value / 10.7639104;		//convert from kBtu/m2 to kBtu/ft2
        return value;
    }

    public static function joulesToMegaJoules(value:Number):Number
    {
        return value / 1000000;
    }

    public static function megaJoulesToJoules(value:Number):Number
    {
        return value * 1000000;
    }


    public static function lbPerSqFtToKgPerSqM(value:Number):Number
    {
        return value * 4.88242764;
    }




    public static function KgPerSqMToLbPerSqFt(value:Number):Number
    {
        return value * 0.204816144;
    }

    public static function KgPerMSecToLbPerFtSec(value:Number):Number
    {
        return value * 6719689497;
    }

    public static function LbPerFtSecToKgPerMSec(value:Number):Number
    {
        return value / 6719689497;
    }

    public static function KgPerMSecKelToLbPerFtSecFahr(value:Number):Number
    {
        return value * 3733161272;
    }

    public static function LbPerFtSecFahrToKgPerMSecKel(value:Number):Number
    {
        return value / 3733161272;
    }

    public static function KgPerMSecKelSqToLbPerFtSecFahrSq(value:Number):Number
    {
        return value * 2073978650;
    }

    public static function LbPerFtSecFahrSqToKgPerMSecKelSq(value:Number):Number
    {
        return value / 2073978650;
    }


    public static function  JoulesToWattHours(value:Number):Number
    {
        return value * 0.00027777778;
    }


    public static function  WattsPerCelToBtuPerHourF(value:Number):Number
    {
        return value * 1.89563424;
    }

    public static function BtuPerHourFToWattsPerCel(value:Number):Number
    {
        return value / 1.89563424;
    }


    /* Conversion for conductivity */
    public static function  WattsPerMCelToBtuPerHourFtFahr(value:Number):Number
    {
        return value * 0.578;
    }

    public static function BtuPerHourFtFahrToWattsPerMCel(value:Number):Number
    {
        return value / 0.578;
    }

    /* Conversion for conductance */
    public static function  WattsPerSqMCelToBtuPerHourSqFtFahr(value:Number):Number
    {
        return value * 0.17611;
    }


    public static function BtuPerHourSqFtFahrToWattsPerSqMCel(value:Number):Number
    {
        return value / 0.17611;
    }



    /* Conversion for density */
    public static function  lbPerFootCubedToKgPerMeterCubed(value:Number):Number
    {
        return value * 16.01846;
    }


    public static function kgPerMeterCubedToLbPerFootCubed(value:Number):Number
    {
        return value / 16.01846;
    }

    /* Conversion for specific heat */
    public static function  btuPerLbFahrToKJPerKgCel(value:Number):Number
    {
        return value * 4.1868;
    }


    public static function KJPerKgCelToBtuPerLbFahr(value:Number):Number
    {
        return value / 4.1868;
    }



    public static function WattsToBtuPerHour(value:Number):Number
    {
        return value * 3.412;
    }

    public static function BtuPerHourToWatts(value:Number):Number
    {
        return value / 3.412;
    }

    public static function WattsPerSqMToBtuPerSqFtHour(value:Number):Number
    {
        return value * .316957210776545;
    }


    public static function BtuPerHourSqFtToWattsPerSqM(value:Number):Number
    {
        return value / .316957210776545;
    }

    public static function kWTokBtuPerHr(value:Number):Number
    {
        return value * 3.41214129;
    }

    public static function kBtuPerHrToKW(value:Number):Number
    {
        return value / 3.41214129;
    }


    public static function kWToTon(value:Number):Number
    {
        return value * 0.284333239;
    }

    public static function tonToKW(value:Number):Number
    {
        return value / 0.284333239;
    }




    public static function  WattsPerMCelCubedToBtuPerHourFtFahrCubed(value:Number):Number
    {
        return value * 0.1783300539;
    }

    public static function BtuPerHourFtFahrCubedToWattsPerMCelCubed(value:Number):Number
    {
        return value / 0.1783300539;
    }

    public static function MetricRValueToIPRValue(value:Number):Number
    {
        return value / 0.17611;
    }

    public static function IPRValueToMetricRValue(value:Number):Number
    {
        return value * 0.17611;
    }

    public static function metersPerSecondToKPH(value:Number):Number
    {
        return value * 3.6;
    }

    public static function metersPerSecondToMPH(value:Number):Number
    {
        return value * 2.24;
    }


    public static function fangerPPDToPPS(value:Number):Number
    {
        return 100-value;
    }


    //For CO2ElectricFactor
    public static function kgPerKWHTolbPerKWH(value:Number):Number
    {
        return value / 0.45359237;
    }

    public static function lbPerKWHTokgPerKWH(value:Number):Number
    {
        return value * 0.45359237;
    }




    //For CO2GasFactor
    //from E+ docs kg/J => lb/Btu 2325.83774250441
    public static function kgPerMJTolbPerKBTU(value:Number):Number
    {
        return value / 2.3258;
    }


    public static function lbPerKBTUTokgPerMJ(value:Number):Number
    {
        return value * 2.3258;
    }




    // HELPER FUNCTIONS


    public static function roundToDecimals(value:Number, numDecimals:Number):Number
    {
        if (numDecimals<1) return Math.round(value);
        var f:Number = Math.pow(10,numDecimals);
        value = value * f;
        value = Math.round(value);
        value = value / f;
        return value;
    }

    public static function luxToFootcandles(value:Number):Number
    {
        return value * 0.092902267; //value from E+ Input Output Docs
    }

    public static function footcandlesToLux(value:Number):Number
    {
        return value / 0.092902267; //value from E+ Input Output Docs
    }


    //GAS

    public static function cubicMeterToMJ(value:Number):Number
    {
        return value * 37.3134328;
    }


    /** gives all strings representing numbers the same number of decimals, even if they are 0 */
    public static function normalizeDecimalPlaceString(displayValue:String, numberOfDecimals:Number = 2):String
    {
        var zerosToAdd:int = 0;
        if (displayValue.indexOf(".")!=-1)
        {
            var decimals:String = displayValue.split(".")[1];
            if (decimals.length<numberOfDecimals)
            {
                zerosToAdd = numberOfDecimals - decimals.length;
            }

        }
        else
        {
            if (numberOfDecimals>0) displayValue+=".";
            zerosToAdd = numberOfDecimals;
        }
        for (var i:int; i< zerosToAdd; i++)
        {
            displayValue+="0";
        }
        return displayValue
    }





    //Outdoor air flow rates

    //per person
    public static function m3PerSecondPerPersonToCFMPerPerson(value:Number):Number
    {
        return value * 2119;
    }

    public static function	CFMPerPersonToM3PerSecondPerPerson(value:Number):Number
    {
        return value / 2119;
    }

    // per zone floor area
    public static function m3PerSecondM2ToCFMPerFt2(value:Number):Number
    {
        return value * 196.85;
    }

    public static function	CFMPerFt2ToM3PerSecondM2(value:Number):Number
    {
        return value  / 196.85;
    }



}
}
