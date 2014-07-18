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

package nail.otlib.core
{
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.utils.Dictionary;
    
    import nail.errors.FileNotFoundError;
    import nail.errors.NullArgumentError;
    import nail.errors.SingletonClassError;
    import otlib.utils.FilesInfo;
    import nail.utils.StringUtil;

    public class Versions extends EventDispatcher
    {
        //--------------------------------------------------------------------------
        // PROPERTIES
        //--------------------------------------------------------------------------
        
        private var _list:Dictionary;
        private var _loaded:Boolean;
        
        //--------------------------------------
        // Getters / Setters
        //--------------------------------------
        
        public function get loaded():Boolean { return _loaded; }
        
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function Versions()
        {
            if (_instance)
                throw new SingletonClassError(Versions);
            
            _instance = this;
            _list = new Dictionary();
        }
        
        //--------------------------------------------------------------------------
        // METHODS
        //--------------------------------------------------------------------------
        
        //--------------------------------------
        // Public
        //--------------------------------------
        
        public function load(file:File):Boolean
        {
            if (!file)
                throw new NullArgumentError("file");
            
            if (!file.exists)
                throw new FileNotFoundError(file);
            
            if (this.loaded)
                dispose();
            
            var stream:FileStream = new FileStream();
            stream.open(file, FileMode.READ);
            var xml:XML = XML( stream.readUTFBytes(stream.bytesAvailable) );
            stream.close();
            
            if (xml.localName() != "versions")
                throw new Error("Invalid versions XML.");
            
            for each (var versionXML:XML in xml.version) {
                
                if (!versionXML.hasOwnProperty("@value"))
                    throw new Error("A version doesn't have the 'value' tag.");
                    
                if (!versionXML.hasOwnProperty("@string"))
                    throw new Error("A version doesn't have the 'string' tag.");
                
                if (!versionXML.hasOwnProperty("@dat"))
                    throw new Error("A version doesn't have the 'dat' tag.");
                
                if (!versionXML.hasOwnProperty("@spr"))
                    throw new Error("A version doesn't have the 'spr' tag.");
                
                if (!versionXML.hasOwnProperty("@otb"))
                    throw new Error("A version doesn't have the 'otb' tag.");
                
                var version:Version = new Version();
                version.value = uint(versionXML.@value);
                version.valueStr = String(versionXML.@string);
                version.datSignature = uint(StringUtil.substitute("0x{0}", versionXML.@dat));
                version.sprSignature = uint(StringUtil.substitute("0x{0}", versionXML.@spr));
                version.otbVersion = uint(versionXML.@otb);
                _list[version.valueStr] = version;
            }
            
            _loaded = true;
            dispatchEvent(new Event(Event.COMPLETE));
            return _loaded;
        }
        
        public function getList():Array
        {
            var list:Array = [];
            for each (var version:Version in _list) {
                list[list.length] = version;
            }
            
            if (list.length > 1)
                list.sortOn("value", Array.NUMERIC | Array.DESCENDING);
            
            return list;
        }
        
        public function getFromFilesInfo(info:FilesInfo):Version
        {
            for each (var version:Version in _list) {
                if (version.value == info.clientVersion &&
                    version.datSignature == info.datSignature &&
                    version.sprSignature == info.sprSignature)
                    return version;
            }
            return null;
        }
        
        public function getByValue(value:uint):Version
        {
            for each (var version:Version in _list) {
                if (version.value == value)
                    return version;
            }
            return null;
        }
        
        public function getByValueString(value:String):Version
        {
            if (!isNullOrEmpty(value)) {
                if (_list[value] !== undefined)
                    return _list[value];
            }
            return null;
        }
        
        public function getBySignatures(datSignature:uint, sprSignature:uint):Version
        {
            for each (var version:Version in _list) {
                if (version.sprSignature == sprSignature &&
                    version.datSignature == datSignature)
                    return version;
            }
            return null;
        }
        
        public function getByOtbVersion(otb:uint):Version
        {
            for each (var version:Version in _list) {
                if (version.otbVersion == otb)
                    return version;
            }
            return null;
        }
        
        public function dispose():void
        {
            _list = new Dictionary();
            _loaded = false;
        }
        
        //--------------------------------------------------------------------------
        // STATIC
        //--------------------------------------------------------------------------
        
        private static var _instance:Versions;
        public static function get instance():Versions
        {
            if (!_instance)
                _instance = new Versions();
            
            return _instance;
        }
    }
}
