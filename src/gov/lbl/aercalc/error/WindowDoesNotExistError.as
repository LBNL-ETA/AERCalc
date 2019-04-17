package gov.lbl.aercalc.error
{
	public class WindowDoesNotExistError extends Error
	{
		public function WindowDoesNotExistError(message:*="", id:*=0)
		{
			super(message, id);
		}
	}
}