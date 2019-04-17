package gov.lbl.aercalc.error
{
	public class SimulationError extends Error
	{
		public function SimulationError(message:*="", id:*=0)
		{
			super(message, id);
		}
	}
}