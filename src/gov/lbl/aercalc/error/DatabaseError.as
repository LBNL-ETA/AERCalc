package gov.lbl.aercalc.error
{
	public class DatabaseError extends Error
	{
		public function DatabaseError(message:*="", id:*=0)
		{
			super(message, id);
		}
	}
}