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
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.utils.Dictionary;
    
    import nail.logging.Log;
    import nail.utils.StringUtil;
    
    public final class Version
    {
        //--------------------------------------------------------------------------
        //
        // PROPERTIES
        //
        //--------------------------------------------------------------------------
        
        private var _value:uint;
        private var _valueStr:String;
        private var _datSignature:uint;
        private var _sprSignature:uint;
        private var _otbVersion:uint;
        
        //--------------------------------------
        // Getters / Setters
        //--------------------------------------
        
        public function get value():uint { return _value; }
        public function get valueStr():String { return _valueStr; }
        public function get sprSignature():uint { return _sprSignature; }
        public function get datSignature():uint { return _datSignature; }
        public function get otbVersion():uint { return _otbVersion; }
        
        //--------------------------------------------------------------------------
        //
        // CONSTRUCTOR
        //
        //--------------------------------------------------------------------------
        
        public function Version(versionValue:uint, versionString:String, datSignature:uint, sprSignature:uint, otbVersion:uint)
        {
            _value = versionValue;
            _valueStr = versionString;
            _datSignature = datSignature;
            _sprSignature = sprSignature;
            _otbVersion = otbVersion;
        }
        
        //----------------------------------------------------
        //
        // METHODS
        //
        //----------------------------------------------------
        
        //--------------------------------------
        // Public
        //--------------------------------------
        
        public function toString():String
        {
            return _valueStr;
        }
        
        public function equals(version:Version):Boolean
        {
            if (version &&
                version.value == this.value &&
                version.datSignature == this.datSignature &&
                version.sprSignature == this.sprSignature) {
                return true;
            }
            return false;
        }
        
        //----------------------------------------------------
        //
        // STATIC
        //
        //----------------------------------------------------
        
        private static const VERSION_LIST:Dictionary = new Dictionary();
        
        static public function load():void
        {
            var file:File = File.applicationDirectory.resolvePath("versions.xml");
            if (!file.exists) return;
            
            try
            {
                var stream:FileStream = new FileStream();
                stream.open(file, FileMode.READ);
                var xml:XML = XML( stream.readUTFBytes(stream.bytesAvailable) );
                stream.close();
                
                if (xml.localName() != "versions")  return;
                
                for each (var versionXML:XML in xml.version) {
                    if (versionXML.hasOwnProperty("@value") &&
                        versionXML.hasOwnProperty("@string") &&
                        versionXML.hasOwnProperty("@dat") &&
                        versionXML.hasOwnProperty("@spr") &&
                        versionXML.hasOwnProperty("@otb")) {
                        var value:uint = uint(versionXML.@value);
                        var string:String = String(versionXML.@string);
                        var dat:uint = uint(StringUtil.substitute("0x{0}", versionXML.@dat));
                        var spr:uint = uint(StringUtil.substitute("0x{0}", versionXML.@spr));
                        var otb:uint = uint(versionXML.@otb);
                        var version:Version = new Version(value, string, dat, spr, otb);
                        VERSION_LIST[string] = version;
                    }
                }
            } catch(error:Error) {
                Log.error(error.message, error.getStackTrace(), error.errorID);
            }
        }
        load();
        
        public static function getList():Array
        {
            var list:Array = [];
            for each (var version:Version in VERSION_LIST) {
                list[list.length] = version;
            }
            
            if (list.length > 1) {
                list.sortOn("value", Array.NUMERIC | Array.DESCENDING);
            }
            return list;
        }
        
        public static function getVersionByValue(value:uint):Version
        {
            for each (var version:Version in VERSION_LIST) {
                if (version.value == value) {
                    return version;
                }
            }
            return null;
        }
        
        public static function getVersionByString(value:String):Version
        {
            if (!isNullOrEmpty(value)) {
                if (VERSION_LIST[value] !== undefined) {
                    return Version(VERSION_LIST[value]);
                }
            }
            return null;
        }
        
        public static function getVersionBySignatures(datSignature:uint, sprSignature:uint):Version
        {
            for each (var version:Version in VERSION_LIST) {
                if (version.sprSignature == sprSignature && version.datSignature == datSignature) {
                    return version;
                }
            }
            return null;
        }
        
        public static function getVersionByOtb(otb:uint):Version
        {
            for each (var version:Version in VERSION_LIST) {
                if (version.otbVersion == otb) {
                    return version;
                }
            }
            return null;
        }
    }
}
