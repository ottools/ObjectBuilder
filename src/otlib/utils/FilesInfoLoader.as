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
    import nail.otlib.core.Version;
    import nail.otlib.core.Versions;
    import nail.resources.Resources;
    
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
        private var _filesInfo:FilesInfo;
        private var _bytesTotal:uint;
        private var _bytesLoaded:uint;
        
        //--------------------------------------
        // Getters / Setters
        //--------------------------------------
        
        public function get filesInfo():FilesInfo { return _filesInfo; }
        
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
                dispatchEvent( createErrorEvent( Resources.getString("strings", "datFileNotFound") ) );
            
            if (!spr.exists)
                dispatchEvent( createErrorEvent( Resources.getString("strings", "sprFileNotFound") ) );
            
            _dat = dat;
            _spr = spr;
            _extended = extended;
            _filesInfo = new FilesInfo();
            _bytesTotal = _dat.size + _spr.size;
            
            try
            {
                loadDat();
            } catch(error:Error) {
                _filesInfo = null;
                dispatchEvent( createErrorEvent(error.message, error.errorID) );
            }
        }
        
        //--------------------------------------
        // Private
        //--------------------------------------
        
        private function loadDat():void
        {
            var stream:FileStream = new FileStream();
            stream.endian = Endian.LITTLE_ENDIAN;
            stream.addEventListener(Event.COMPLETE, datLoadCompleteHandler);
            stream.addEventListener(ProgressEvent.PROGRESS, progressHandler);
            stream.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            stream.openAsync(_dat, FileMode.READ);
        }
        
        private function loadSpr():void
        {
            var stream:FileStream = new FileStream();
            stream.endian = Endian.LITTLE_ENDIAN;
            stream.addEventListener(Event.COMPLETE, sprLoadCompleteHandler);
            stream.addEventListener(ProgressEvent.PROGRESS, progressHandler);
            stream.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            stream.openAsync(_spr, FileMode.READ);
        }
        
        //--------------------------------------
        // Event Handlers
        //--------------------------------------
        
        private function datLoadCompleteHandler(event:Event):void
        {
            var stream:FileStream = event.target as FileStream;
            _filesInfo.datSignature = stream.readUnsignedInt();
            _filesInfo.maxItemId = stream.readUnsignedShort();
            _filesInfo.maxOutfitId = stream.readUnsignedShort();
            _filesInfo.maxEffectId = stream.readUnsignedShort();
            _filesInfo.maxMissileId = stream.readUnsignedShort();
            stream.close();
            
            loadSpr();
        }
        
        private function sprLoadCompleteHandler(event:Event):void
        {
            var stream:FileStream = event.target as FileStream;
            _filesInfo.sprSignature = stream.readUnsignedInt();
            
            var version:Version = Versions.instance.getBySignatures(
                _filesInfo.datSignature,
                _filesInfo.sprSignature);
            
            if (!version) {
                _filesInfo.maxItemId = 0;
                _filesInfo.maxOutfitId = 0;
                _filesInfo.maxEffectId = 0;
                _filesInfo.maxMissileId = 0;
                _filesInfo.maxSpriteId = 0;
                
                dispatchEvent(new Event(Event.COMPLETE));
                dispatchEvent( createErrorEvent( Resources.getString("strings", "unsupportedVersion") ) );
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
            
            stream.close();
            
            dispatchEvent(new Event(Event.COMPLETE));
        }
        
        private function progressHandler(event:ProgressEvent):void
        {
            _bytesLoaded = (event.bytesLoaded % _bytesTotal);
            dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, _bytesLoaded, _bytesTotal));
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
