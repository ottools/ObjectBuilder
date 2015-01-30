/*
*  Copyright (c) 2015 Object Builder <https://github.com/Mignari/ObjectBuilder>
* 
*  Permission is hereby granted, free of charge, to any person obtaining a copy
*  of this software and associated documentation files (the "Software"), to deal
*  in the Software without restriction, including without limitation the rights
*  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*  copies of the Software, and to permit persons to whom the Software is
*  furnished to do so, subject to the following conditions:
* 
*  The above copyright notice and this permission notice shall be included in
*  all copies or substantial portions of the Software.
* 
*  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
*  THE SOFTWARE.
*/

package ob.core
{
    import flash.display.BitmapData;
    import flash.filesystem.File;
    import flash.utils.ByteArray;
    
    import nail.commands.ICommunicator;
    import nail.settings.ISettingsManager;
    import nail.utils.FileData;
    
    import ob.settings.ObjectBuilderSettings;
    
    import otlib.core.IVersionStorage;
    import otlib.core.Version;
    import otlib.loaders.PathHelper;
    import otlib.sprites.SpriteData;
    import otlib.things.ThingData;
    import otlib.things.ThingType;
    import otlib.utils.ClientInfo;
    
    public interface IObjectBuilder extends ICommunicator
    {
        function get settingsManager():ISettingsManager;
        function get settings():ObjectBuilderSettings;
        function get versionStorage():IVersionStorage;
        
        function get clientInfo():ClientInfo;
        function get clientChanged():Boolean;
        function get clientIsTemporary():Boolean;
        function get clientLoaded():Boolean;
        
        function get thingData():ThingData;
        function set thingData(value:ThingData):void;
        function get showPreviewPanel():Boolean;
        function set showPreviewPanel(value:Boolean):void;
        function get showThingsPanel():Boolean;
        function set showThingsPanel(value:Boolean):void;
        function get showSpritesPanel():Boolean;
        function set showSpritesPanel(value:Boolean):void;
        function get currentCategory():String;
        function set currentCategory(value:String):void;
        
        function loadFiles(datFile:File,
                           sprFile:File,
                           version:Version,
                           extended:Boolean,
                           transparency:Boolean):void;
        function createFiles(version:Version,
                             extended:Boolean,
                             transparency:Boolean):void;
        function openClient(directory:File = null):void;
        function openObjectViewer(file:File = null):void;
        function closeObjectViewer():void;
        function openSlicer(file:File = null):void;
        function closeSlicer():void;
        
        function importThingsFromFiles(list:Vector.<PathHelper>):void;
        function exportThings(fileDataList:Vector.<FileData>,
                              category:String,
                              version:Version,
                              spriteSheetFlag:uint,
                              transparentBackground:Boolean,
                              jpegQuality:uint):void;
        function replaceThings(things:Vector.<ThingData>):void;
        function replaceThingsFromFiles(list:Vector.<PathHelper>):void;
        function duplicateThings(ids:Vector.<uint>, category:String):void;
        function removeThing(thing:ThingType, removeSprites:Boolean = false):void;
        function removeThings(list:Vector.<uint>,
                              category:String,
                              removeSprites:Boolean = false):void;
        function importSprites(list:Vector.<ByteArray>):void;
        function importSpritesFromFiles(list:Vector.<PathHelper>):void;
        function exportSprites(fileDataList:Vector.<FileData>,
                               transparentBackground:Boolean,
                               jpegQuality:uint):void;
        function replaceSprite(id:uint, bitmap:BitmapData):void;
        function replaceSprites(list:Vector.<SpriteData>):void;
        function replaceSpritesFromFiles(list:Vector.<PathHelper>):void;
        function removeSpritesIds(sprites:Vector.<uint>):void;
        function removeSprites(sprites:Vector.<SpriteData>):void;
        function saveThingChanges():void;
        function openPreferencesWindow():void;
        function compile():void;
        function compileAs():void;
        function unload():void;
    }
}
