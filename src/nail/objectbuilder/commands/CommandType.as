///////////////////////////////////////////////////////////////////////////////////
// 
//  Copyright (c) 2014 <nailsonnego@gmail.com>
// 
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
// 
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
///////////////////////////////////////////////////////////////////////////////////

package nail.objectbuilder.commands
{
	import nail.errors.AbstractClassError;

	public final class CommandType
	{
		//--------------------------------------------------------------------------
		//
		// CONSTRUCTOR
		//
		//--------------------------------------------------------------------------
		
		public function CommandType()
		{
			throw new AbstractClassError(CommandType);
		}
		
		//--------------------------------------------------------------------------
		//
		// STATIC
		//
		//--------------------------------------------------------------------------
		
		static public const LOAD_ASSETS : String = "loadAssets";
		
		static public const GET_ASSETS_INFO : String = "getAssetsInfo";
		
		static public const SET_ASSETS_INFO : String = "getAssetsInfo";
		
		static public var LOAD_COMPLETE : String = "loadComplete";
		
		static public const NEW_THING : String = "newThing";
		
		static public const REPLACE_THING : String = "replaceThing";
		
		static public const DUPLICATE_THING : String = "duplicateThing";
		
		static public const IMPORT_THING : String = "importThing";
		
		static public const UPDATE_THING : String = "updateThing";
		
		static public const REMOVE_THING : String = "removeThing";
		
		static public const GET_THING : String = "getThing";
		
		static public const SET_THING : String = "setThing";
		
		static public const ADD_SPRITE : String = "addSprite";
		
		static public const REPLACE_SPRITE : String = "replaceSprite";
		
		static public const DUPLICATE_SPRITE : String = "duplicateSprite";
		
		static public const NEW_SPRITE : String = "newSprite"
		
		static public const REMOVE_SPRITES : String = "removeSprites";
		
		static public const IMPORT_SPRITE : String = "importSprite";
		
		static public const EXPORT_SPRITE : String = "exportSprite";
		
		static public const GET_SPRITE_LIST : String = "getSpriteList";
		
		static public const SET_SPRITE_LIST : String = "setSpriteList";
		
		static public const COMPILE_ASSETS : String = "compileAssets";
		
		static public const SHOW_PROGRESS_BAR : String = "showProgressBar";	
		
		static public const HIDE_PROGRESS_BAR : String = "hideProgressBar";	
		
		static public const SHOW_MESSAGE : String = "showMessage";	
		
		static public const ERROR : String = "error";
	}
}
