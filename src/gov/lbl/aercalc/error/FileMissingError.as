package gov.lbl.aercalc.error
{
	public class FileMissingError extends Error
	{
		public function FileMissingError(message:*="", id:*=0)
		{
			super(message, id);
		}
	}
}