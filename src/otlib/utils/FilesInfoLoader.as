/*
*  Copyright (c) 2014 Object Builder <https://github.com/Mignari/ObjectBuilder>
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

package otlib.utils
{
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.utils.Endian;
    
    import nail.errors.NullArgumentError;
    
    import otlib.core.Version;
    import otlib.core.VersionStorage;
    import otlib.resources.Resources;
    
    [Event(name="complete", type="flash.events.Event")]
    [Event(name="progress", type="flash.events.ProgressEvent")]
    [Event(name="error", type="flash.events.ErrorEvent")]
    
    [ResourceBundle("strings")]
    
    public class FilesInfoLoader extends EventDispatcher
    {
        //--------------------------------------------------------------------------
        // PROPERTIES
        //--------------------------------------------------------------------------
        
        private var _dat:File;
        private var _spr:File;
        private var _extended:Boolean;
        private var _filesInfo:ClientInfo;
        private var _total:uint;
        private var _loaded:uint;
        
        //--------------------------------------
        // Getters / Setters
        //--------------------------------------
        
        public function get filesInfo():ClientInfo { return _filesInfo; }
        
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function FilesInfoLoader()
        {
        }
        
        //--------------------------------------------------------------------------
        // METHODS
        //--------------------------------------------------------------------------
        
        //--------------------------------------
        // Public
        //--------------------------------------
        
        public function load(dat:File, spr:File, extended:Boolean):void
        {
            if (!dat)
                throw new NullArgumentError("dat");
            
            if (!spr)
                throw new NullArgumentError("spr");
            
            if (!dat.exists)
                dispatchEvent( createErrorEvent( Resources.getString("datFileNotFound") ) );
            
            if (!spr.exists)
                dispatchEvent( createErrorEvent( Resources.getString("sprFileNotFound") ) );
            
            _dat = dat;
            _spr = spr;
            _extended = extended;
            _filesInfo = new ClientInfo();
            _total = 2;
            
            loadNext();
        }
        
        //--------------------------------------
        // Private
        //--------------------------------------
        
        private function loadNext():void
        {
            _loaded++;
            
            dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, _loaded, _total));
            
            if (_loaded == 1)
                loadDat();
            else if (_loaded == 2)
                loadSpr();
            else
                dispatchEvent(new Event(Event.COMPLETE));
        }
        
        private function loadDat():void
        {
            var stream:FileStream = new FileStream();
            stream.endian = Endian.LITTLE_ENDIAN;
            stream.addEventListener(ProgressEvent.PROGRESS, metadataProgressHandler);
            stream.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            stream.openAsync(_dat, FileMode.READ);
        }
        
        private function loadSpr():void
        {
            var stream:FileStream = new FileStream();
            stream.endian = Endian.LITTLE_ENDIAN;
            stream.addEventListener(ProgressEvent.PROGRESS, spritesProgressHandler);
            stream.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            stream.openAsync(_spr, FileMode.READ);
        }
        
        //--------------------------------------
        // Event Handlers
        //--------------------------------------
        
        private function readMetadaInfo(stream:FileStream):void
        {
            _filesInfo.datSignature = stream.readUnsignedInt();
            _filesInfo.maxItemId = stream.readUnsignedShort();
            _filesInfo.maxOutfitId = stream.readUnsignedShort();
            _filesInfo.maxEffectId = stream.readUnsignedShort();
            _filesInfo.maxMissileId = stream.readUnsignedShort();
            
            loadNext();
        }
        
        private function readSpritesInfo(stream:FileStream):void
        {
            _filesInfo.sprSignature = stream.readUnsignedInt();
            
            var version:Version = VersionStorage.instance.getBySignatures(
                _filesInfo.datSignature,
                _filesInfo.sprSignature);
            
            if (!version)
            {
                _filesInfo.maxItemId = 0;
                _filesInfo.maxOutfitId = 0;
                _filesInfo.maxEffectId = 0;
                _filesInfo.maxMissileId = 0;
                _filesInfo.maxSpriteId = 0;
                
                dispatchEvent(new Event(Event.COMPLETE));
                dispatchEvent( createErrorEvent( Resources.getString("unsupportedVersion") ) );
                return;
            }
            
            _filesInfo.clientVersion = version.value;
            _filesInfo.clientVersionStr = version.valueStr;
            
            if (_extended || version.value >= 960) {
                _filesInfo.maxSpriteId = stream.readUnsignedInt();
                _filesInfo.extended = true;
            } else {
                _filesInfo.maxSpriteId = stream.readUnsignedShort();
            }
            
            loadNext();
        }
        
        private function metadataProgressHandler(event:ProgressEvent):void
        {
            var stream:FileStream = event.target as FileStream;
            if (stream.bytesAvailable >= 12)
                readMetadaInfo(stream);
            
            stream.removeEventListener(ProgressEvent.PROGRESS, metadataProgressHandler);
            stream.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            stream.close();
        }
        
        private function spritesProgressHandler(event:ProgressEvent):void
        {
            var stream:FileStream = event.target as FileStream;
            if (stream.bytesAvailable >= 8)
                readSpritesInfo(stream);
            
            stream.removeEventListener(ProgressEvent.PROGRESS, spritesProgressHandler);
            stream.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            stream.close();
        }
        
        private function ioErrorHandler(event:IOErrorEvent):void
        {
            _filesInfo = null;
            dispatchEvent( createErrorEvent(event.text, event.errorID) );
        }
        
        private function createErrorEvent(text:String, id:uint = 0):ErrorEvent
        {
            return new ErrorEvent(ErrorEvent.ERROR, false, false, text, id);
        }
    }
}
