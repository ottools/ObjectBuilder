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

package nail.otlib.things
{
    import flash.display.BitmapData;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    import flash.utils.CompressionAlgorithm;
    import flash.utils.Endian;
    
    import nail.errors.NullArgumentError;
    import nail.otlib.core.Version;
    import nail.otlib.geom.Rect;
    import nail.otlib.sprites.Sprite;
    import nail.otlib.sprites.SpriteData;
    import nail.otlib.utils.OTFormat;
    import nail.otlib.utils.SpriteUtils;
    import nail.utils.StringUtil;
    
    public class ThingData
    {
        //--------------------------------------------------------------------------
        //
        // PROPERTIES
        //
        //--------------------------------------------------------------------------
        
        public var thing:ThingType;
        public var sprites:Vector.<SpriteData>;
        
        //--------------------------------------
        // Getters / Setters 
        //--------------------------------------
        
        public function get id():uint { return thing ? thing.id : 0; }
        public function get category():String { return thing ? thing.category : null; }
        public function get length() : uint { return sprites ? sprites.length : 0; }
        
        //--------------------------------------------------------------------------
        //
        // CONSTRUCTOR
        //
        //--------------------------------------------------------------------------
        
        public function ThingData()
        {
        }
        
        //--------------------------------------------------------------------------
        //
        // METHODS
        //
        //--------------------------------------------------------------------------
        
        //--------------------------------------
        // Public
        //--------------------------------------
        
        public function clone():ThingData
        {
            var spritesCopy:Vector.<SpriteData> = new Vector.<SpriteData>();
            var length:uint = sprites.length;
            for (var i:uint = 0; i < length; i++) {
                spritesCopy[i] = sprites[i].clone();
            }
            var thingData:ThingData = new ThingData();
            thingData.thing = this.thing.clone();
            thingData.sprites = spritesCopy;
            return thingData;
        }
        
        //--------------------------------------------------------------------------
        //
        // STATIC
        //
        //--------------------------------------------------------------------------
        
        private static const RECTANGLE:Rectangle = new Rectangle(0, 0, 32, 32);
        private static const POINT:Point = new Point();
        
        public static function createThingData(thing:ThingType, sprites:Vector.<SpriteData>):ThingData
        {
            if (!thing) {
                throw new NullArgumentError("thing");
            }
            
            if (!sprites) {
                throw new NullArgumentError("sprites");
            }
            
            if (thing.spriteIndex.length != sprites.length) {
                throw new ArgumentError("Invalid sprites length.");
            }
            
            var thingData:ThingData = new ThingData();
            thingData.thing = thing;
            thingData.sprites = sprites;
            return thingData;
        }
        
        public static function createFromFile(file:File):ThingData
        {
            if (!file || file.extension != OTFormat.OBD || !file.exists)
                return null;
            
            var bytes:ByteArray = new ByteArray();
            var stream:FileStream = new FileStream();
            stream.open(file, FileMode.READ);
            stream.readBytes(bytes, 0, stream.bytesAvailable);
            stream.close();
            return unserialize(bytes);
        }
        
        public static function serialize(data:ThingData, version:Version):ByteArray
        {
            if (!data) {
                throw new NullArgumentError("data");
            }
            
            if (!data) {
                throw new NullArgumentError("version");
            }
            
            var thing:ThingType = data.thing;
            var bytes:ByteArray = new ByteArray();
            bytes.endian = Endian.LITTLE_ENDIAN;
            bytes.writeShort(version.value); // Write client version
            bytes.writeUTF(thing.category);  // Write thing category
            
            var done:Boolean;
            if (version.value <= 730)
                done = ThingSerializer.writeProperties1(thing, bytes);
            else if (version.value <= 750)
                done = ThingSerializer.writeProperties2(thing, bytes);
            else if (version.value <= 772)
                done = ThingSerializer.writeProperties3(thing, bytes);
            else if (version.value <= 854)
                done = ThingSerializer.writeProperties4(thing, bytes);
            else if (version.value <= 986)
                done = ThingSerializer.writeProperties5(thing, bytes);
            else
                done = ThingSerializer.writeProperties6(thing, bytes);
            
            if (!done || !writeSprites(data, bytes)) return null;
            
            bytes.compress(CompressionAlgorithm.LZMA);
            return bytes;
        }
        
        public static function unserialize(bytes:ByteArray):ThingData
        {
            if (!bytes) {
                throw new NullArgumentError("bytes");
            }
            
            bytes.endian = Endian.LITTLE_ENDIAN;
            bytes.uncompress(CompressionAlgorithm.LZMA);
            
            var version:Version = Version.getVersionByValue( bytes.readUnsignedShort() );
            if (!version) {
                throw new Error("Unsupported version.");
            }
            
            var thing:ThingType = new ThingType();
            thing.category = ThingCategory.getCategory( bytes.readUTF() );
            if (!thing.category) {
                throw new Error("Invalid thing category.");
            }
            
            var done:Boolean;
            if (version.value <= 730)
                done = ThingSerializer.readProperties1(thing, bytes);
            else if (version.value <= 750)
                done = ThingSerializer.readProperties2(thing, bytes);
            else if (version.value <= 772)
                done = ThingSerializer.readProperties3(thing, bytes);
            else if (version.value <= 854)
                done = ThingSerializer.readProperties4(thing, bytes);
            else if (version.value <= 986)
                done = ThingSerializer.readProperties5(thing, bytes);
            else
                done = ThingSerializer.readProperties6(thing, bytes);
            
            if (!done) return null;
            return readThingSprites(thing, bytes);
        }
        
        public static function getSpriteSheet(data:ThingData,
                                              textureIndex:Vector.<Rect> = null,
                                              backgroundColor:uint = 0xFFFF00FF):BitmapData
        {
            if (data == null) {
                throw new NullArgumentError("data");
            }
            
            var thing:ThingType = data.thing;
            var width:uint = thing.width;
            var height:uint = thing.height;
            var layers:uint = thing.layers;
            var patternX:uint = thing.patternX;
            var patternY:uint = thing.patternY;
            var patternZ:uint = thing.patternZ;
            var frames:uint = thing.frames;
            var size:uint = Sprite.SPRITE_PIXELS;
            
            // -----< Measure and create bitmap>-----
            var totalX:int = patternZ * patternX * layers;
            var totalY:int = frames * patternY;
            var bitmapWidth:Number = (totalX * width) * size;
            var bitmapHeight:Number = (totalY * height) * size;
            var pixelsWidth:int = width * size;
            var pixelsHeight:int = height * size;
            var bitmap:BitmapData = new BitmapData(bitmapWidth, bitmapHeight, true, backgroundColor);
            
            if (textureIndex) {
                textureIndex.length = layers * patternX * patternY * patternZ * frames;
            }
            
            for (var f:uint = 0; f < frames; f++) {
                for (var z:uint = 0; z < patternZ; z++) {
                    for (var y:uint = 0; y < patternY; y++) {
                        for (var x:uint = 0; x < patternX; x++) {
                            for (var l:uint = 0; l < layers; l++) {
                                
                                var index:uint = getTextureIndex(thing, f, x, y, z, l);
                                var fx:int = (index % totalX) * pixelsWidth;
                                var fy:int = Math.floor(index / totalX) * pixelsHeight;
                                
                                if (textureIndex) {
                                    textureIndex[index] = new Rect(fx, fy, pixelsWidth, pixelsHeight);
                                }
                                
                                for (var w:uint = 0; w < width; w++) {
                                    for (var h:uint = 0; h < height; h++) {
                                        index = getSpriteIndex(thing, w, h, l, x, y, z, f);
                                        var px:int = ((width - w - 1) * size);
                                        var py:int = ((height - h - 1) * size);
                                        copyPixels(data, index, bitmap, px + fx, py + fy);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return bitmap;
        }
        
        public static function setSpriteSheet(bitmap:BitmapData, thing:ThingType):ThingData
        {
            if (!bitmap) {
                throw new NullArgumentError("bitmap");
            }
            
            if (!thing) {
                throw new NullArgumentError("thing");
            }
            
            var rectSize:Rect = SpriteUtils.getSpriteSheetSize(thing);
            if (bitmap.width != rectSize.width || bitmap.height != rectSize.height) return null;
            
            bitmap = SpriteUtils.removeMagenta(bitmap);
            
            var width:uint = thing.width;
            var height: uint = thing.height;
            var layers:uint = thing.layers;
            var patternX:uint = thing.patternX;
            var patternY:uint = thing.patternY;
            var patternZ:uint = thing.patternZ;
            var frames:uint = thing.frames;
            var size:uint = Sprite.SPRITE_PIXELS;
            var totalX:int = patternZ * patternX * layers;
            var pixelsWidth:int  = width * size;
            var pixelsHeight:int = height * size;
            var sprites:Vector.<SpriteData> = new Vector.<SpriteData>(width * height * layers * patternX * patternY * patternZ * frames);
            
            POINT.setTo(0, 0);
            
            for (var f:uint = 0; f < frames; f++) {
                for (var z:uint = 0; z < patternZ; z++) {
                    for (var y:uint = 0; y < patternY; y++) {
                        for (var x:uint = 0; x < patternX; x++) {
                            for (var l:uint = 0; l < layers; l++) {
                                
                                var index:uint = getTextureIndex(thing, f, x, y, z, l);
                                var fx:int = (index % totalX) * pixelsWidth;
                                var fy:int = Math.floor(index / totalX) * pixelsHeight;
                                
                                for (var w:uint = 0; w < width; w++) {
                                    for (var h:uint = 0; h < height; h++) {
                                        index = getSpriteIndex(thing, w, h, l, x, y, z, f);
                                        var px:int = ((width - w - 1) * size);
                                        var py:int = ((height - h - 1) * size);
                                        RECTANGLE.setTo(px + fx, py + fy, size, size);
                                        var bmp:BitmapData = new BitmapData(size, size, true, 0x00000000);
                                        bmp.copyPixels(bitmap, RECTANGLE, POINT);
                                        var spriteData:SpriteData = new SpriteData();
                                        spriteData.pixels = bmp.getPixels(bmp.rect);
                                        spriteData.id = uint.MAX_VALUE;
                                        sprites[index] = spriteData;
                                        thing.spriteIndex[index] = spriteData.id;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return createThingData(thing, sprites);
        }
        
        public static function getTextureIndex(thing:ThingType, f:int, x:int, y:int, z:int, l:int):int
        {
            return (((f % thing.frames * thing.patternZ + z) * thing.patternY + y) * thing.patternX + x) * thing.layers + l;
        }
        
        public static function getSpriteIndex(thing:ThingType, w:uint, h:uint, l:uint, x:uint, y:uint, z:uint, f:uint):uint
        {
            return ((((((f % thing.frames)
                * thing.patternZ + z)
                * thing.patternY + y)
                * thing.patternX + x)
                * thing.layers + l)
                * thing.height + h)
                * thing.width + w;
        }
        
        static private function copyPixels(data:ThingData, index:uint, bitmap:BitmapData, x:uint, y:uint):void
        {
            if (index < data.length) {
                var spriteData:SpriteData = data.sprites[index];
                if (spriteData && spriteData.pixels) {
                    var bmp:BitmapData = spriteData.getBitmap();
                    if (bmp) {
                        spriteData.pixels.position = 0;
                        RECTANGLE.setTo(0, 0, bmp.width, bmp.height);
                        POINT.setTo(x, y);
                        bitmap.copyPixels(bmp, RECTANGLE, POINT, null, null, true);
                    }
                }
            }
        }
        
        private static function writeSprites(data:ThingData, bytes:ByteArray):Boolean
        { 
            var thing:ThingType = data.thing;
            bytes.writeByte(thing.width);  // Write width
            bytes.writeByte(thing.height); // Write height
            
            if (thing.width > 1 || thing.height > 1) {
                bytes.writeByte(thing.exactSize); // Write exact size
            }
            
            bytes.writeByte(thing.layers);   // Write layers
            bytes.writeByte(thing.patternX); // Write pattern X
            bytes.writeByte(thing.patternY); // Write pattern Y
            bytes.writeByte(thing.patternZ); // Write pattern Z
            bytes.writeByte(thing.frames);   // Write frames
            
            var spriteList:Vector.<uint> = thing.spriteIndex;
            var length:uint = spriteList.length;
            for (var i:uint = 0; i < length; i++) {
                var spriteId:uint = spriteList[i];
                var spriteData:SpriteData = data.sprites[i];
                if (!spriteData || !spriteData.pixels) {
                    throw new Error(StringUtil.substitute("Invalid sprite id.", spriteId));
                }
                var pixels:ByteArray = spriteData.pixels;
                pixels.position = 0;
                bytes.writeUnsignedInt(spriteId);
                bytes.writeUnsignedInt(pixels.length);
                bytes.writeBytes(pixels, 0, pixels.bytesAvailable);
            }
            return true;
        }
        
        private static function readThingSprites(thing:ThingType, bytes:ByteArray):ThingData
        {
            thing.width  = bytes.readUnsignedByte();
            thing.height = bytes.readUnsignedByte();
            
            if (thing.width > 1 || thing.height > 1)
                thing.exactSize = bytes.readUnsignedByte();
            else 
                thing.exactSize = Sprite.SPRITE_PIXELS;
            
            thing.layers = bytes.readUnsignedByte();
            thing.patternX = bytes.readUnsignedByte();
            thing.patternY = bytes.readUnsignedByte();
            thing.patternZ = bytes.readUnsignedByte();
            thing.frames = bytes.readUnsignedByte();
            
            var totalSprites:uint = thing.width * thing.height * thing.layers * thing.patternX * thing.patternY * thing.patternZ * thing.frames;
            if (totalSprites > 4096) {
                throw new Error("Thing has more than 4096 sprites.");
            }
            
            thing.spriteIndex = new Vector.<uint>(totalSprites);
            var sprites:Vector.<SpriteData> = new Vector.<SpriteData>(totalSprites);
            
            for (var i:uint = 0; i < totalSprites; i++) {
                var spriteId:uint = bytes.readUnsignedInt();
                var length:uint = bytes.readUnsignedInt();
                if (length > bytes.bytesAvailable) {
                    throw new Error("Not enough data.");
                }
                
                thing.spriteIndex[i] = spriteId;
                var pixels:ByteArray = new ByteArray();
                pixels.endian = Endian.BIG_ENDIAN;
                bytes.readBytes(pixels, 0, length);
                pixels.position = 0;
                var spriteData:SpriteData = new SpriteData();
                spriteData.id = spriteId;
                spriteData.pixels = pixels;
                sprites[i] = spriteData;
            }
            return createThingData(thing, sprites);
        }
    }
}
