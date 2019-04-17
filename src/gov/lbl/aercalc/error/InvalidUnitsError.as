package gov.lbl.aercalc.error
{
	public class InvalidUnitsError extends Error
	{
		public function InvalidUnitsError(message:*="", id:*=0)
		{
			super(message, id);
		}
	}
}