package otlib.components
{
	import flash.ui.ContextMenu;
	
	import spark.components.Button;
	import spark.components.Group;
	
	import otlib.core.otlib_internal;
	import otlib.events.FrameSpriteGroupEvent;

	public class FrameSpriteGroup extends Group
	{
		//--------------------------------------------------------------------------
		// PROPERTIES
		//--------------------------------------------------------------------------

		[Bindable]
		public var editor:ThingTypeEditor;
		
		public function FrameSpriteGroup()
		{
			
		}

		//--------------------------------------------------------------------------
		// METHODS
		//--------------------------------------------------------------------------
		
		//--------------------------------------
		// Internal
		//--------------------------------------

		otlib_internal function onContextMenuDisplaying(button:Button, menu:ContextMenu):void
		{
			if (!editor.hasTransferData)
				menu.items[2].enabled = false; // Paste Frame
		}

		otlib_internal function onContextMenuSelect(button:Button, type:String):void
		{
			switch(type) {
				case FrameSpriteGroupEvent.CLEAR_SPRITE:
					var frame:int = editor.currentFrame;
					var index:int = parseInt(button.label);
					editor.clearSprite(frame, index);
					break;

				case FrameSpriteGroupEvent.COPY_FRAME:
					editor.copyFrame(editor.currentFrame);
					break;

				case FrameSpriteGroupEvent.PASTE_FRAME:
					editor.pasteFrame(editor.currentFrame);
					break;

				case FrameSpriteGroupEvent.CLEAR_FRAME:
					editor.clearFrame(editor.currentFrame);
					break;
			}
		}
	}
}
