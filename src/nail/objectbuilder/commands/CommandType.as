///////////////////////////////////////////////////////////////////////////////////
// 
//  Copyright (c) 2014 Nailson <nailsonnego@gmail.com>
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
        
        static public const CREATE_NEW_FILES:String = "createNewFiles";
        static public const LOAD_FILES:String = "loadFiles";
        static public const UNLOAD_FILES:String = "unloadFiles";
        static public const FILES_INFO:String = "filesInfo";
        static public const LOAD_COMPLETE:String = "loadComplete";
        static public const COMPILE:String = "compile";
        static public const COMPILE_AS:String = "compileAs";
        
        static public const NEW_THING:String = "newThing";
        static public const IMPORT_THINGS:String = "importThings";
        static public const IMPORT_THINGS_FROM_FILES:String = "importThingsFromFiles";
        static public const EXPORT_THINGS:String = "exportThings";
        static public const DUPLICATE_THINGS:String = "duplicateThings";
        static public const REPLACE_THINGS:String = "replaceThings";
        static public const REPLACE_THINGS_FROM_FILES:String = "replaceThingsFromFiles";
        static public const REMOVE_THINGS:String = "removeThings";
        static public const UPDATE_THING:String = "updateThing";
        static public const GET_THING:String = "getThing";
        static public const SET_THING:String = "setThing";
        static public const GET_THING_LIST:String = "getThingList";
        static public const SET_THING_LIST:String = "setThingList";
        static public const FIND_THING:String = "findThing";
        static public const FIND_RESULT:String = "findResult";
        
        static public const NEW_SPRITE:String = "newSprite";
        static public const IMPORT_SPRITES:String = "importSprites";
        static public const IMPORT_SPRITES_FROM_FILES:String = "importSpritesFromFiles";
        static public const REPLACE_SPRITES:String = "replaceSprites";
        static public const REPLACE_SPRITES_FROM_FILES:String = "replaceSpritesFromFiles";
        static public const REMOVE_SPRITES:String = "removeSprites";
        static public const EXPORT_SPRITES:String = "exportSprites";
        static public const GET_SPRITE_LIST:String = "getSpriteList";
        static public const SET_SPRITE_LIST:String = "setSpriteList";
        static public const FIND_SPRITES:String = "findSprites";
        
        static public const PROGRESS:String = "progress";
        static public const SHOW_PROGRESS_BAR:String = "showProgressBar";
        static public const HIDE_PROGRESS_BAR:String = "hideProgressBar";
        static public const ERROR:String = "error";
        static public const NEED_TO_RELOAD:String = "needToReload";
    }
}
