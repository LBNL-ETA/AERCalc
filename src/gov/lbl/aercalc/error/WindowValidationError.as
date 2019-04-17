package gov.lbl.aercalc.error
{
	public class WindowValidationError extends Error
	{
		public function WindowValidationError(message:*="", id:*=0)
		{
			super(message, id);
		}
	}
}