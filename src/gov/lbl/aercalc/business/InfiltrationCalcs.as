package gov.lbl.aercalc.business
{
	/*
	Most of these can probably go
	*/
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import flashx.textLayout.formats.Float;
	
	import gov.lbl.aercalc.events.EnergyPlusEvent;
	import gov.lbl.aercalc.events.SimulationErrorEvent;
	import gov.lbl.aercalc.events.SimulationEvent;
	import gov.lbl.aercalc.model.ApplicationModel;
	import gov.lbl.aercalc.model.LibraryModel;
	import gov.lbl.aercalc.model.SimulationModel;
	import gov.lbl.aercalc.model.domain.WindowVO;
	import gov.lbl.aercalc.util.Logger;
	
	import mx.collections.ArrayCollection;
	import mx.core.RuntimeDPIProvider;
	import mx.events.DynamicEvent;
	
	
	public class InfiltrationCalcs extends EventDispatcher	//Probably doesn't need to be an event dispatcher.
	{
		/*
		These numbers are defined for the current baseline case and are currently constants.
		If/when more base cases are added these will need to either be calculated from something
		or stored somewhere and chosen depending on which baseline is run
		*/
		protected const _baseline_V_h:Number = 577.6288; //volume of the house in m3
		protected const _baseline_ACH_50_cooling:Number = 10;  //Air changes per hour at 50 Pa
		protected const _baseline_ACH_50_heating:Number = 7;   //Air changes per hour at 50 Pa
		protected const _baseline_q_W_75:Number = 0.01016; 	 //Infiltration per unit area of baseline window at 75 Pa in m3/(s*m2)
		protected const _baseline_A_w:Number = 33.6;            //Total window area in m2				
		
		/*
		I think these numbers are actual constants.
		*/
		protected const _delta_P_50:Number = 50; //50 Pa test pressure for windows
		protected const _delta_P_4:Number = 4;   //4 Pa used as baseline for comparison
		protected const _delta_P_75:Number = 75; //75 Pa test pressure for windows
		protected const _flow_exponent:Number = 0.65; //flow exponent		
		protected const _air_density_STP:Number = 1.29; //Air density at standard temperature and pressure in kg/m3		
		protected const _pressure_scaling_denominator:Number = Math.pow(2.0 * _delta_P_4 / _air_density_STP, 0.5);
		protected const _pressure_scaling_factor_for_Q_50:Number = Math.pow(_delta_P_4 / _delta_P_50, _flow_exponent) / _pressure_scaling_denominator;	//value used to scale the Q_50 total house infiltration at 50 Pa to the 4 Pa baseline
		protected const _pressure_scaling_factor_for_Q_W_75:Number = Math.pow(_delta_P_4 / _delta_P_75, _flow_exponent) / _pressure_scaling_denominator; //value used to scale the Q_W_75 total baseline infiltration at 75 Pa to the 4 Pa baseline
		
		protected const _air_leakage_conversion_factor_IP_to_SI:Number = 0.00508; //Converts from cfm/(s*f2) to m3/(s * m2) or converting feet to meters / minutes to seconds: 0.3048 / 60
		
		public function calc_Q_50(V_h:Number, ACH_50:Number):Number
		{
			/*			
			Returns the total house infiltration at 50 Pa in m3/s
			V_h is volume of the house in m3
			ACH_50 is air changes per hour at 50 Pa.  This is climate dependent
			*/
			
			return V_h * ACH_50 / 3600.0;
		}
		
		
					
		public function calc_ELA_H(V_h:Number, ACH_50:Number):Number
		{
			/*			
			Returns the effective leakage area of the whole house with baseline windows in cm2
			V_h is volume of the house in m3
			ACH_50 is air changes per hour at 50 Pa.  This is climate dependent
			*/
			
			var Q_50:Number = calc_Q_50(V_h, ACH_50);
			var ELA_H:Number = Q_50 * _pressure_scaling_factor_for_Q_50 * 10000;
			return ELA_H;
		}
		
		public function calc_Q_W_75(q_W_75:Number, A_w:Number):Number
		{
			/*			
			Returns the total baseline window infiltration at 75 Pa in m3/s
			q_W_75 is the infiltration per unit area of baseline window at 75 Pa in m3/(s*m2)
			A_w is the total window area in m2
			*/
			
			return q_W_75 * A_w;
		}
		
		public function calc_ELA_W(q_W_75:Number, A_w:Number):Number
		{
			/*			
			Returns the effective leakage area of all baseline windows in cm2
			q_W_75 is the infiltration per unit area of baseline window at 75 Pa in m3/(s*m2)
			A_w is the total window area in m2
			*/
			
			var Q_W_75:Number = calc_Q_W_75(q_W_75, A_w);
			var ELA_W:Number = Q_W_75 * _pressure_scaling_factor_for_Q_W_75 * 10000;
			return ELA_W;
		}
		
		public function calc_ELA_HO(V_h:Number, ACH_50:Number, q_W_75:Number, A_w:Number):Number
		{
			/*			
			Returns the effective leakage area of the whole house without windows in cm2
			V_h is volume of the house in m3
			ACH_50 is air changes per hour at 50 Pa.  This is climate dependent
			q_W_75 is the infiltration per unit area of baseline window at 75 Pa in m3/(s*m2)
			A_w is the total window area in m2
			*/
			
			var ELA_H:Number = calc_ELA_H(V_h, ACH_50);
			var ELA_W:Number = calc_ELA_W(q_W_75, A_w);
			return ELA_H - ELA_W;
		}
		
		public function calc_Q_WA_75(q_WA_75:Number, A_w:Number):Number
		{
			/*			
			Returns the total infiltration of windows with attachment at 75 Pa in m3/s
			q_WA_75 is the infiltration per unit area of baseline window with attachment at 75 Pa in m3/(s*m2)
			A_w is the total window area in m2
			*/
			
			return q_WA_75 * A_w;
		}
		
		public function calc_ELA_WA(q_WA_75:Number, A_w:Number):Number
		{
			/*
			Returns the effective air leakage of all windows with attachment in cm2
			q_WA_75 is the infiltration per unit area of baseline window with attachment at 75 Pa in m3/(s*m2)
			A_w is the total window area in m2
			*/
			var Q_WA_75:Number = calc_Q_WA_75(q_WA_75, A_w);
			return Q_WA_75 * _pressure_scaling_factor_for_Q_W_75 * 10000;
		}
		
		public function convert_air_leakage_to_SI(q_WA_75_IP:Number):Number
		{
			/*
			Converts from cfm/(s*f2) to m3/(s * m2) or converting feet to meters / minutes to seconds: 0.3048 / 60
			q_WA_75_IP is the measured air leakage per unit area of window in cfm/(s*f2)
			*/
			return q_WA_75_IP * _air_leakage_conversion_factor_IP_to_SI;
		}
		
		public function calc_ELA_HWA(measured_air_leakage_IP:Number, V_h:Number, ACH_50:Number, q_W_75:Number, A_w:Number):Number
		{
			/*			
			Returns the effective leakage area of the whole house window and attachment in cm2
			measured_air_leakage_IP is the measured air infiltration per unit area of window with attachment at 75 Pa in IP units:  cfm/(s*f2)
				This is what the user input and currently is only in IP
			V_h is volume of the house in m3
			ACH_50 is air changes per hour at 50 Pa.  This is climate dependent
			q_W_75 is the infiltration per unit area of baseline window at 75 Pa in m3/(s*m2)
			A_w is the total window area in m2
			*/
			
			//first convert the user input to SI
			var q_WA_75:Number = convert_air_leakage_to_SI(measured_air_leakage_IP);
			
			var ELA_HO:Number = calc_ELA_HO(V_h, ACH_50, q_W_75, A_w);
			var ELA_WA:Number = calc_ELA_WA(q_WA_75, A_w);
			
			return ELA_HO + ELA_WA;
		}
		
		public function calc_ELA_HWA_heating(measured_air_leakage_IP:Number):Number
		{
			/*
			Returns the effective leakage area of the whole house window and attachment for the heating climate in cm2
			measured_air_leakage_IP is in cfm/(s*f2
			*/
			return calc_ELA_HWA(measured_air_leakage_IP, _baseline_V_h, _baseline_ACH_50_heating, _baseline_q_W_75, _baseline_A_w);
		}
		
		public function calc_ELA_HWA_cooling(measured_air_leakage_IP:Number):Number
		{
			/*
			Returns the effective leakage area of the whole house window and attachment for the cooling climate in cm2
			measured_air_leakage_IP is in cfm/(s*f2
			*/
			return calc_ELA_HWA(measured_air_leakage_IP, _baseline_V_h, _baseline_ACH_50_cooling, _baseline_q_W_75, _baseline_A_w);
		}
	}	
		
}