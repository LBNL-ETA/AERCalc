package gov.lbl.aercalc.model
{
import mx.collections.ArrayCollection;
import gov.lbl.aercalc.view.dialogs.ImportW7WindowsDialog;

	[Bindable]
	public class ImportModel
	{
		//These are the states the import process can be in...
		public static const STATE_IMPORTING_WINDOW_LIST:String = "importingWindowList";
		public static const STATE_IMPORTING_WINDOW:String = "importingWindow";

		//These are the import states that an individual glazing system from W7 can be in...
		public static const IMPORT_STATE_INVALID:String =	"w7ImportInvalid";
		public static const IMPORT_STATE_AVAILABLE:String =	"w7ImportAvailable";
		public static const IMPORT_STATE_FAILED:String =	"w7ImportFailed";
		public static const IMPORT_STATE_COMPLETE:String = 	"w7ImportComplete";

		/* 	A complete list of base case window IDs that AERCalc recognizes.
			Any other incoming base window ID will be considered unrecognized.
		 */
		public static const VALID_BASE_CASE_WINDOW_IDS:Array = 	["BW-A", "BW-B", "BW-C", "BW-D", "BW-E", "BW-F"];


		public static const ATTACHMENT_POSITION_INDOOR:String = "I";
        public static const ATTACHMENT_POSITION_OUTDOOR:String = "O";
        public static const ATTACHMENT_POSITION_BETWEEN:String = "B";

		public static var attachmentPositions:ArrayCollection = new ArrayCollection([
			{ data: ATTACHMENT_POSITION_INDOOR, label:"Indoor"},
            { data: ATTACHMENT_POSITION_OUTDOOR, label:"Outdoor"},
            { data: ATTACHMENT_POSITION_BETWEEN, label:"Between"}
		]);

		public static function getAttachmentPositionName(id:String):String {
			var len:uint = attachmentPositions.length;
			for (var index:uint=0;index<len;index++){
				if (attachmentPositions[index].data == id){
					return attachmentPositions[index].label
				}
			}
			return null;
		}


        public var importW7WindowsDialog:ImportW7WindowsDialog = new ImportW7WindowsDialog();

		/* 	A complete list of shade type IDs (and related description) that AERCalc recognizes.F
		    Any other incoming IDs will be considered unrecognized.
		 */
        //TODO Expose for modification: move this to database and load on startup
		public static var shadingSystemTypes:ArrayCollection = new ArrayCollection([
            { data: "VB0", label:"Venetian Blind (0 deg.)", is_blind:true },
            { data: "VB45", label:"Venetian Blind (45 deg.)", is_blind:true },
            { data: "VB-45", label:"Venetian Blind (-45 deg.)", is_blind:true },
            { data: "VB90", label:"Venetian Blind (90 deg.)", is_blind:true },
			{ data: "VL0", label:"Vertical Louver (0 deg.)", is_blind:true },
			{ data: "VL45", label:"Vertical Louver (45 deg.)", is_blind:true },
			{ data: "VL-45", label:"Vertical Louver (-45 deg.)", is_blind:true },
			{ data: "VL90", label:"Vertical Louver (90 deg.)", is_blind:true },
            { data: "CS", label:"Cellular Shade", is_blind:false },
            { data: "PS", label:"Pleated Shade", is_blind:false },
            { data: "RS", label:"Roller Shade", is_blind:false },
            { data: "SS", label:"Solar Screen", is_blind:false },
            { data: "WP", label:"Window Panel", is_blind:false },
            { data: "AF", label:"Applied Film", is_blind:false }
        ]);

		/*  A dictionary mapping the integers used to define shading layer types
			in W7 to descriptive labels. Also, indicates which shading layer
			types are required to have shade materials defined.
		 */
		public static var shadingLayerTypes:ArrayCollection = new ArrayCollection([
			{ id: 0, label:"Horizontal Venetian Blind", requiresShadeMaterial:true},
			{ id: 1, label:"Homogeneous Diffusing Shade", requiresShadeMaterial:true},
            { id: 2, label:"XML", requiresShadeMaterial:false},
            { id: 3, label:"Woven Shade", requiresShadeMaterial:true},
            { id: 4, label:"(undefined)", requiresShadeMaterial:false},
            { id: 5, label:"Vertical Venetian Blind", requiresShadeMaterial:true},
            { id: 6, label:"Perforated Screen", requiresShadeMaterial:true},
            { id: 7, label:"THMX", requiresShadeMaterial:false}
		]);

		public function shadingLayerRequiresMaterial(id:int):Boolean {
			var len:uint = shadingLayerTypes.length;
			for (var index:uint=0;index<len;index++){
				var obj:Object = shadingLayerTypes.getItemAt(index);
				if (obj.id == id){
					return obj.requiresShadeMaterial;
				}
			}
			return false;
		}


		/* This is subset of shade type IDs that signify the system is a blind.
		 An incoming system's id is matched against this to
		 determine if it's a blind or not (and thereby adding things like parent-child relationship, etc.)
		 */
        public static var blindTypeIDs:Array = [];

		/* Improve speed of lookup */
		public static var validShadeTypeIDs:Array = [];

        //List of windows available from Window7
		public var w7GlazingSystemsAC:ArrayCollection;

		// An array of glazing system that were
		// selected for import
		public var importGlazingSystemAC:ArrayCollection = new ArrayCollection();

		public var currImportIndex:uint = 0;
		public var numBSDFImportFailures:uint = 0;

		public var currentState:String = "";

		/*TODO: This should probably be just a boolean property, like simulationInProgress
		 		on SimulationModel. I am loathe to use get/set though, given it's flaky behavior in AS */
		public function isImportInProgress():Boolean {
			return currentState != "";
		}
		
		public function ImportModel()
		{
			// Build a lookup arrays for faster access.
			// Lookup array for shade type IDs and 'is blind' subset
            for each (var obj:Object in shadingSystemTypes){
               validShadeTypeIDs.push(obj.data);
				if (obj.is_blind){
                    blindTypeIDs.push(obj.data);
				}
            }
		}

		/* Static functions */

		public static function isValidShadeType(shadeTypeID:String):Boolean {
			return validShadeTypeIDs.indexOf(shadeTypeID) > -1;
		}

		public static function isBlind(shadeTypeID:String):Boolean {
			return blindTypeIDs.indexOf(shadeTypeID) > -1;
		}

		public static function getValidShadeTypes():Array {
			var returnArr:Array = [];
			for each (var obj:Object in shadingSystemTypes){
				returnArr.push(obj.data);
			}
			return returnArr;
		}

		/* public instance functions */
		public function getShadingSystemName(shadingSystemType:String):String{
			var len:uint = shadingSystemTypes.length;
			for (var index:uint=0; index<len; index++){
				var obj:Object= shadingSystemTypes[index];
				if (obj.data == shadingSystemType){
					return obj.label;
				}
			}
			return "";
		}
	}
}