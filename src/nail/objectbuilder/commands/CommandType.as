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
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function CommandType()
        {
            throw new AbstractClassError(CommandType);
        }
        
        //--------------------------------------------------------------------------
        // STATIC
        //--------------------------------------------------------------------------
        
        public static const CREATE_NEW_FILES:String = "createNewFiles";
        public static const LOAD_FILES:String = "loadFiles";
        public static const UNLOAD_FILES:String = "unloadFiles";
        public static const FILES_INFO:String = "filesInfo";
        public static const LOAD_COMPLETE:String = "loadComplete";
        public static const COMPILE:String = "compile";
        public static const COMPILE_AS:String = "compileAs";
        
        public static const NEW_THING:String = "newThing";
        public static const IMPORT_THINGS:String = "importThings";
        public static const IMPORT_THINGS_FROM_FILES:String = "importThingsFromFiles";
        public static const EXPORT_THINGS:String = "exportThings";
        public static const DUPLICATE_THINGS:String = "duplicateThings";
        public static const REPLACE_THINGS:String = "replaceThings";
        public static const REPLACE_THINGS_FROM_FILES:String = "replaceThingsFromFiles";
        public static const REMOVE_THINGS:String = "removeThings";
        public static const UPDATE_THING:String = "updateThing";
        public static const GET_THING:String = "getThing";
        public static const SET_THING:String = "setThing";
        public static const GET_THING_LIST:String = "getThingList";
        public static const SET_THING_LIST:String = "setThingList";
        public static const FIND_THING:String = "findThing";
        public static const FIND_RESULT:String = "findResult";
        
        public static const NEW_SPRITE:String = "newSprite";
        public static const IMPORT_SPRITES:String = "importSprites";
        public static const IMPORT_SPRITES_FROM_FILES:String = "importSpritesFromFiles";
        public static const REPLACE_SPRITES:String = "replaceSprites";
        public static const REPLACE_SPRITES_FROM_FILES:String = "replaceSpritesFromFiles";
        public static const REMOVE_SPRITES:String = "removeSprites";
        public static const EXPORT_SPRITES:String = "exportSprites";
        public static const GET_SPRITE_LIST:String = "getSpriteList";
        public static const SET_SPRITE_LIST:String = "setSpriteList";
        public static const FIND_SPRITES:String = "findSprites";
        
        public static const PROGRESS:String = "progress";
        public static const SHOW_PROGRESS_BAR:String = "showProgressBar";
        public static const HIDE_PROGRESS_BAR:String = "hideProgressBar";
        public static const ERROR:String = "error";
        public static const NEED_TO_RELOAD:String = "needToReload";
    }
}
