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

package nail.objectbuilder.settings
{
    import flash.filesystem.File;
    
    import nail.codecs.ImageFormat;
    import nail.objectbuilder.utils.SupportedLanguages;
    import nail.otlib.core.Version;
    import nail.otlib.core.Versions;
    import nail.otlib.utils.OTFormat;
    import nail.settings.Settings;
    import nail.utils.FileUtil;
    
    public class ObjectBuilderSettings extends Settings
    {
        //--------------------------------------------------------------------------
        // PROPERTIES
        //--------------------------------------------------------------------------
        
        public var lastDirectory:String;
        public var lastIODirectory:String;
        public var exportThingFormat:String;
        public var exportSpriteFormat:String;
        public var datSignature:int;
        public var sprSignature:int;
        public var autosaveThingChanges:Boolean;
        public var maximized:Boolean;
        public var previewContainerWidth:Number = 0;
        public var thingListContainerWidth:Number = 0;
        public var spritesContainerWidth:Number = 0;
        public var showThingList:Boolean;
        public var language:String;
        public var extended:Boolean;
        public var transparency:Boolean;
        public var savingSpriteSheet:Number = 0;
        public var findWindowWidth:Number = 0;
        public var findWindowHeight:Number = 0;
        public var objectViewerWidth:Number = 0;
        public var objectViewerHeight:Number = 0;
        public var objectViewerMaximized:Boolean;
        public var slicerWidth:Number = 0;
        public var slicerHeight:Number = 0;
        public var slicerMaximized:Boolean;
        public var slicerLastDirectory:String;
        public var animationWindowWidth:Number = 0;
        public var animationWindowHeight:Number = 0;
        public var animationWindowMaximized:Boolean;
        public var objectsListAmount:Number;
        public var spritesListAmount:Number;
        
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function ObjectBuilderSettings()
        {
           this.language = SupportedLanguages.EN_US;
           this.maximized = true;
           this.showThingList = true;
           this.objectsListAmount = 100;
           this.spritesListAmount = 100;
        }
        
        //--------------------------------------------------------------------------
        // METHODS
        //--------------------------------------------------------------------------
        
        //--------------------------------------
        // Public
        //--------------------------------------
        
        public function getLastDirectory():File
        {
            if (isNullOrEmpty(lastDirectory)) return null;
            
            var directory:File;
            try
            {
                directory = new File(lastDirectory);
            } catch(error:Error) {
                return null;
            }
            return directory;
        }
        
        public function setLastDirectory(file:File):void
        {
            if (file) {
                this.lastDirectory = FileUtil.getDirectory(file).nativePath;
            }
        }
        
        public function getIODirectory():File
        {
            if (isNullOrEmpty(lastIODirectory)) return null;
            
            var directory:File;
            try 
            {
                directory = new File(lastIODirectory);
            } catch(error:Error) {
                return null;
            }
            return directory;
        }
        
        public function setIODirectory(file:File):void
        {
            if (file) {
                this.lastIODirectory = FileUtil.getDirectory(file).nativePath;
            }
        }
        
        public function getLastExportThingFormat():String
        {
            if (!isNullOrEmpty(exportThingFormat)) {
                if (ImageFormat.hasImageFormat(exportThingFormat) || exportThingFormat == OTFormat.OBD) {
                    return exportThingFormat;
                }
            }
            return null;
        }
        
        public function setLastExportThingFormat(format:String):void
        {
            format = format ? format.toLowerCase() : "";
            this.exportThingFormat = format;
        }
        
        public function getLastExportThingVersion():Version
        {
            return Versions.instance.getBySignatures(datSignature, sprSignature);
        }
        
        public function setLastExportThingVersion(version:Version):void
        {
            this.datSignature = !version ? 0 : version.datSignature;
            this.sprSignature = !version ? 0 : version.sprSignature;
        }
        
        public function getLastExportSpriteFormat():String
        {
            if (ImageFormat.hasImageFormat(exportSpriteFormat)) {
                return exportSpriteFormat;
            }
            return null;
        }
        
        public function setLastExportSpriteFormat(format:String):void
        {
            format = !format ? "" : format.toLowerCase();
            this.exportSpriteFormat = format;
        }
        
        public function getSlicerLastDirectory():File
        {
            if (isNullOrEmpty(slicerLastDirectory)) return null;
            
            var directory:File;
            try 
            {
                directory = new File(slicerLastDirectory);
            } catch(error:Error) {
                return null;
            }
            return directory;
        }
        
        public function setSlicerLastDirectory(file:File):void
        {
            if (file) {
                this.slicerLastDirectory = FileUtil.getDirectory(file).nativePath;
            }
        }
        
        public function getLanguage():Array
        {
            if (isNullOrEmpty(language) || language == "null") {
                return [SupportedLanguages.EN_US];
            }
            return [language];
        }
    }
}
