package gov.lbl.aercalc.model.domain
{
	import gov.lbl.aercalc.util.Conversions;
	
	import gov.lbl.aercalc.model.ApplicationModel;
	import gov.lbl.aercalc.util.Logger;
	import gov.lbl.aercalc.util.Utils;
	
	import mx.collections.ArrayList;

[Bindable]
	[Table(name="windows")]
	public class WindowVO extends AERCalcVO
	{
		
		public static const STATUS_INVALID:String = "invalid";
		public static const STATUS_WARNING:String = "warning";
		public static const STATUS_OK:String = "ok";
		
		[Transient]
		public var simulationStatus:String = "";

		/* Helper property to manage selection in grid */
		[Transient]
		public var selected:Boolean;

        private var _isOpen:Boolean = false;

        [Transient]
		public var children:Array = [];

		// Indicate whether this row was created
		// to hold child WindowVOs for different slat angles
		public var isParent:Boolean = false;

        public var shadingSystemManufacturer:String  = "";

        public var shadingMaterialManufacturer:String  = "";

		// Flag to know which VO's to save when closing
		[Transient]
		public var isDirty:Boolean;

		// Flag to indicate whether BSDF exists
		// in bdsf folder
		[Transient]
		public var hasBSDF:Boolean;

		// Flag to indicate whether row is
		// outdated b/c of helper program
		// versioning
		[Transient]
		public var versionStatus:String;

		// The original name as defined in W7
		// Used to match re-imports
		public var W7Name:String ="";
		// W7 Window and Glz Sys IDs
		public var W7ID:String = "";
		public var W7GlzSysID:String = "";
        public var W7ShdSysID:String = "";
		public var cgdbVersion:String = "";
		public var WINDOWOriginDB:String = "";
		public var THERMFiles:String = "";
		protected var _AERCalcVersion:String = "";
        protected var _WINDOWVersion:String = "";
        protected var _EPlusVersion:String = "";
        protected var _ESCalcVersion:String = "";

		protected var _userID:String = null;
		public var shadingSystemType:String = "";
		public var attachmentPosition:String = "";
		public var baseWindowType:String = "";

		public var parent_id:uint = 0;

		//Public vars. These have SI/IP values
		//so getters/setters will convert
		public var _width:Number = 0;
		public var _height:Number = 0;
		public var _UvalWinter:Number= 0;


        public var Tsol:Number = 0;
        public var Emishin:Number = 0;
        public var Emishout:Number = 0;

		//Protected vars. Getters/Setters
		//don't convert values
		protected var _Tvis:Number = 0;
		//TvT represents 'material variability'
		protected var _TvT:Number = 0;
		protected var _epc:Number = 0;
		protected var _eph:Number = 0;
		protected var _name:String = "";
		protected var _airInfiltration:Number = ApplicationModel.AIR_INFILTRATION_DEFAULT;
		//protected var _airInfiltrationCold:Number = ApplicationModel.AIR_INFILTRATION_COLD_DEFAULT;

		protected var _SHGC:Number = 0;

		public function WindowVO()
		{
		}

		
		/* Set the 'versionStatus' string that indicates
		   if there are any warnings or issues with this window. */
		public function setVersionStatus():void {

			var msg:String = "";
			var childrenImportedWithOldVersion = "";
			var currWINDOWVersion:String = ApplicationModel.VERSION_WINDOW;
			var isOldW7Import:Boolean = false;
			if (isParent){				
				for each(var child:WindowVO in children){
					if(Utils.compareVersions(currWINDOWVersion, child._WINDOWVersion) == Utils.FIRST_ARG_HIGHER){
						//childrenImportedWithOldVersion += "\t" + child.name + ": " + child._WINDOWVersion + "\n";
						isOldW7Import = true;
					}						
				}
			}
			else{
				isOldW7Import = Utils.compareVersions(currWINDOWVersion, _WINDOWVersion) == Utils.FIRST_ARG_HIGHER;	
			}
						
			if (isOldW7Import){
				if (isParent){
					msg += "Child records imported with old W7\n";
				}
				else{
					msg += "Imported with old W7 : " + _WINDOWVersion + "\n";	
				}				
                msg += "Current version of W7 : " + currWINDOWVersion + "\n";
			}

			if (this.isSimulated()){

                var currEPlusVersion:String = ApplicationModel.VERSION_ENERGYPLUS;
                var isOldEPlusImport:Boolean = Utils.compareVersions(currEPlusVersion, _EPlusVersion) == Utils.FIRST_ARG_HIGHER;
                if (isOldEPlusImport){
                    msg += "Simulated with old E+ : " + _EPlusVersion + "\n";
                    msg += "Current version of E+ : " + currEPlusVersion + "\n";
                }

                var currESCalcVersion:String = ApplicationModel.VERSION_ESCALC;
                var isOldESCalcImport:Boolean = Utils.compareVersions(currESCalcVersion, _ESCalcVersion) == Utils.FIRST_ARG_HIGHER;
                if (isOldESCalcImport){
                    msg += "Simulated with old ESCalc : " + _ESCalcVersion + "\n";
                    msg += "Current version of ESCalc : " + currESCalcVersion + "\n";
                }
			}

			this.versionStatus = msg;
		}


		[Transient]
		public function get epcNormalized():Number{
			return this.epc * 100;
		}
		
        [Transient]
        public function get ephNormalized():Number{
            return this.eph * 100;
        }


		//TODO Need better way to know row has been simulated
		public function isSimulated():Boolean {
			return (this.epc>0 || this.eph>0);
		}
		
		
		// Convenience method, mainly for csv output
		[Transient]
		public function get parentChildType():String {
			if (isParent){
				return "P";
			}
			else if (isChild()){
				return "C";
			}
			return "";
		}

        /* Helper property that allows us to export
           only parents are expanded to show child rows.
         */
		[Transient]
		public var isOpen:Boolean = false;

		public function isChild():Boolean {
			return parent_id > 0;
		}
		

		public function addChild(child:WindowVO):void {
			if (!child){
				throw new Error("WindowVO: Invalid child");
			}
			if (parent_id > 0){
				throw new Error("WindowVO: Can't add child to child WindowVO");
			}
			// compare by IDs rather than whole objects to 
			// make sure we're not somehow adding a
			// different object with same id.
			var childIDsArr:Array = getChildIDs();
			if(childIDsArr.indexOf(child.id)==-1){
				child.parent_id = this.id;
				child.isParent = false;
				children.push(child);
			}
		}

		/*  Return attachment position of children.
			If they are various return "(various)"  */
		public function getChildAttachmentPosition():String {
			var attachmentPosition:String = "";
            for (var index:uint=0;index<children.length;index++){
				var childAttachmentPosition:String = WindowVO(children[index]).attachmentPosition;
				if (attachmentPosition !="" && attachmentPosition!=childAttachmentPosition){
					return "(various)";
				}
				attachmentPosition = childAttachmentPosition;
            }
            return attachmentPosition;
		}

        /*  Return shading system manufacturer of children.
        If they are various return "(various)"  */
        public function getChildShadingSystemManufacturer():String {
            var shdSysManufacturer:String = "";
            for (var index:uint=0;index<children.length;index++){
                var childShdSysManufacturer:String =  WindowVO(children[index]).shadingSystemManufacturer;
                if (shdSysManufacturer !="" && shdSysManufacturer!=childShdSysManufacturer){
                    return "(various)";
                }
                shdSysManufacturer = childShdSysManufacturer;
            }
            return shdSysManufacturer;
        }

        /*  Return shading material manufacturer of children.
             If they are various return "(various)"  */
        public function getChildShadingMaterialManufacturer():String {
            var shdMatManufacturer:String = "";
            for (var index:uint=0;index<children.length;index++){
                var childShdMatsManufacturer:String =  WindowVO(children[index]).shadingMaterialManufacturer;
                if (shdMatManufacturer !="" && shdMatManufacturer!=childShdMatsManufacturer){
                    return "(various)";
                }
                shdMatManufacturer = childShdMatsManufacturer;
            }
            return shdMatManufacturer;
        }



		public function getChildIDs():Array {
			if (children.length==0){
				return [];
			}
			var idsArr:Array = []
			for (var index:uint=0;index<children.length;index++){
				idsArr.push(children[index].id);
			}
			return idsArr;
		}
		
		
		public function getChildByID(windowID:uint):WindowVO {
			for (var index:uint=0;index<children.length;index++){
				if (children[index].id == windowID){
					return children[index] as WindowVO
				}
			}
			return null;
		}
		
		
		public function numChildren():uint {
			if (this.children){
				return children.length;
			}
			return 0;
		}
		
		
		public function getChildByW7Name(w7Name:String):WindowVO{
			for (var index:uint=0;index<children.length;index++){
				if (children[index].W7Name==w7Name){
					return children[index] as WindowVO;
				}
			}
			return null;
		}
		

		public function removeChild(o:Object):void {
			if (o==null){
				throw new Error("Invalid object");
			}
			if (parent_id > 0){
				throw new Error("WindowVO: Can't remove child from child WindowVO");
			}
			var index:int = children.indexOf(o);
			if(index > -1){
				children.removeAt(index);
			}
		}

		
		public function removeAllChildren():void {
			children = [];
		}


		public function set name(value:String):void
		{
			value = Utils.scrubNewlines(value);
			_name = value	
		}
		public function get name():String
		{
			return _name
		}
		

		public function set userID(value:String):void{
			//We have a unique index constraint on userID column
			//in db, so we can't have empty strings, they must
			//be nulls
			if (value==""){
				value = null;
			}
			_userID = value;
		}
		public function get userID():String {
			if(_userID==null || _userID==undefined){
				return "";
			}
			return _userID;
		}


        public function set AERCalcVersion(value:String):void {
            if (value==null || value==""){
                value = "0.0.0";
            }
            _AERCalcVersion = value;
            setVersionStatus();
        }
        public function get AERCalcVersion():String {
            return _AERCalcVersion;
        }

		
		public function set WINDOWVersion(value:String):void {
			if (value==null || value==""){
				value = "0.0.0";
			}
			_WINDOWVersion = value;
			setVersionStatus();			
		}
		public function get WINDOWVersion():String {
			return _WINDOWVersion;
		}


        public function set EPlusVersion(value:String):void {
            if (value==null || value==""){
                value = "0.0.0";
            }
            _EPlusVersion = value;
            setVersionStatus();
        }
        public function get EPlusVersion():String {
            return _EPlusVersion;
        }


        public function set ESCalcVersion(value:String):void {
            if (value==null || value==""){
                value = "0.0.0";
            }
            _ESCalcVersion = value;
            setVersionStatus();
        }
        public function get ESCalcVersion():String {
            return _ESCalcVersion;
        }








        [Transient]
		public function set width(value:Number):void
		{
			if (value<0) throw new Error("Window width must be greater than 0");
			if (currUnits=="SI")
			{
				_width = value
			}
			else
			{
				_width = Conversions.feetToMeters(value) 
			}
		}
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


		[Transient]
		public function set height(value:Number):void
		{
			if (value<0) throw new Error("Window height must be greater that 0")
			if (currUnits=="SI")
			{
				_height = value
			}
			else
			{
				_height = Conversions.feetToMeters(value)  
			}
		}
		public function get height():Number
		{
			if (currUnits=="SI")
			{
				return _height
			}
			else
			{
				return Conversions.metersToFeet(_height)
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

		public function get SHGC():Number
		{
			return _SHGC
		}
		public function set SHGC(value:Number):void
		{
			_SHGC = value
		}		


		public function set epc(value:Number):void
		{
			_epc = value
		}
		public function get epc():Number
		{
			return _epc
		}


		public function set airInfiltration(value:Number):void
		{
			if (isNaN(value)){
				Logger.error("Invalid Air Infiltration value: " + value + ". Setting to 0.");
				value = 0;
			}
            if (value!=_airInfiltration){
				isDirty = true;
			}
			if (currUnits=="SI")
			{
				_airInfiltration = value;
			} else {
				_airInfiltration = Conversions.CFMPerFt2ToM3PerSecondM2(value);
			}
		}
		public function get airInfiltration():Number {
			if (currUnits=="SI")
			{
				return _airInfiltration;
			} else {
				return Conversions.m3PerSecondM2ToCFMPerFt2(_airInfiltration);
			}
		}



		public function set eph(value:Number):void
		{
			_eph = value
		}
		public function get eph():Number
		{
			return _eph
		}



	}
}