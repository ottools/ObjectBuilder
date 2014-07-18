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

package nail.objectbuilder.core
{
    import flash.display.BitmapData;
    import flash.filesystem.File;
    import flash.utils.ByteArray;
    
    import nail.core.IApplication;
    import nail.objectbuilder.settings.ObjectBuilderSettings;
    import nail.otlib.core.Version;
    import nail.otlib.loaders.PathHelper;
    import nail.otlib.sprites.SpriteData;
    import nail.otlib.things.ThingData;
    import nail.otlib.things.ThingType;
    import otlib.utils.FilesInfo;
    import nail.utils.FileData;
    
    public interface IObjectBuilder extends IApplication
    {
        function loadFiles(datFile:File, sprFile:File, version:Version, extended:Boolean, transparency:Boolean):void;
        function createFiles(version:Version, extended:Boolean, transparency:Boolean):void;
        function openClient(directory:File = null):void;
        function openObjectViewer(file:File = null):void;
        function closeObjectViewer():void;
        function openSlicer(file:File = null):void;
        function closeSlicer():void;
        
        function importThingsFromFiles(list:Vector.<PathHelper>):void;
        function exportThings(fileDataList:Vector.<FileData>, category:String, version:Version, spriteSheetFlag:uint):void;
        function replaceThings(things:Vector.<ThingData>):void;
        function replaceThingsFromFiles(list:Vector.<PathHelper>):void;
        function duplicateThings(ids:Vector.<uint>, category:String):void;
        function removeThing(thing:ThingType, removeSprites:Boolean = false):void;
        function removeThings(list:Vector.<uint>, category:String, removeSprites:Boolean = false):void;
        function importSprites(list:Vector.<ByteArray>):void;
        function importSpritesFromFiles(list:Vector.<PathHelper>):void;
        function exportSprites(fileDataList:Vector.<FileData>):void;
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
        
        function get filesInfo():FilesInfo;
        function get loaded():Boolean;
        function get compiled():Boolean;
        function get isTemporary():Boolean;
        function get thingData():ThingData;
        function set thingData(value:ThingData):void;
        function get currentCategory():String;
        function set currentCategory(value:String):void;
        function get showThingList():Boolean;
        function set showThingList(value:Boolean):void;
        function get settings():ObjectBuilderSettings;
    }
}
