package gov.lbl.aercalc.model.domain {


/** An abstract class that gives all value objects the ability to show both SI and IP values,
 *  and to allow SHADEFEN code to grab the SI value directly when needed.
 *  Also, defines core attributes needed by the data manager (id)
 *
 *  */

[Bindable]
public class AERCalcVO extends BaseUnitsVO
{

    protected var _id:int = 0;

    public function AERCalcVO()
    {
    }


    [Id]
    public function get id():int
    {
        return _id
    }

    public function set id(value:int):void
    {
        _id = value
    }




}
}
