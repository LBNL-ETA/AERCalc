package gov.lbl.aercalc.view.item_renderers
{
	import mx.controls.advancedDataGridClasses.AdvancedDataGridHeaderRenderer;
	
	public class MyADGHeaderRenderer extends AdvancedDataGridHeaderRenderer
	{
		public function MyADGHeaderRenderer()
		{
			super();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth,unscaledHeight);
		}
	}
}