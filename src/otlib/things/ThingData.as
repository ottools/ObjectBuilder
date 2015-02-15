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

package otlib.things
{
    import flash.display.BitmapData;
    import flash.display.BitmapDataChannel;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.filters.ColorMatrixFilter;
    import flash.geom.ColorTransform;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    import flash.utils.CompressionAlgorithm;
    import flash.utils.Endian;
    
    import nail.errors.NullArgumentError;
    import nail.errors.NullOrEmptyArgumentError;
    import nail.utils.StringUtil;
    import nail.utils.isNullOrEmpty;
    
    import otlib.core.Version;
    import otlib.core.VersionStorage;
    import otlib.geom.Rect;
    import otlib.sprites.Sprite;
    import otlib.sprites.SpriteData;
    import otlib.utils.ColorUtils;
    import otlib.utils.OTFormat;
    import otlib.utils.OutfitData;
    import otlib.utils.SpriteUtils;
    
    public class ThingData
    {
        //--------------------------------------------------------------------------
        // PROPERTIES
        //--------------------------------------------------------------------------
        
        private var m_version:uint;
        private var m_thing:ThingType;
        private var m_sprites:Vector.<SpriteData>;
        
        //--------------------------------------
        // Getters / Setters 
        //--------------------------------------
        
        public function get id():uint { return m_thing.id; }
        public function get category():String { return m_thing.category; }
        public function get length():uint { return m_sprites.length; }
        public function get animator():Animator { return m_thing.animator; }
        
        public function get version():uint { return m_version; }
        public function set version(value:uint):void
        {
            if (value < 710)
                throw new ArgumentError(StringUtil.format("Invalid version {0}.", value));
            
            m_version = value;
        }
        
        public function get thing():ThingType { return m_thing; }
        public function set thing(value:ThingType):void
        {
            if (!value)
                throw new NullArgumentError("thing");
            
            m_thing = value;
        }
        
        public function get sprites():Vector.<SpriteData> { return m_sprites; }
        public function set sprites(value:Vector.<SpriteData>):void
        {
            if (isNullOrEmpty(value))
                throw new NullOrEmptyArgumentError("sprites");
            
            var length:uint = value.length;
            for (var i:uint = 0; i < length; i++)
            {
                if (value[i] == null)
                    throw new ArgumentError("Invalid sprite list");
            }
            
            m_sprites = value;
        }
        
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function ThingData()
        {
        }
        
        //--------------------------------------------------------------------------
        // METHODS
        //--------------------------------------------------------------------------
        
        //--------------------------------------
        // Public
        //--------------------------------------
        
        public function getSpriteSheet(textureIndex:Vector.<Rect> = null,
                                       backgroundColor:uint = 0xFFFF00FF):BitmapData
        {
            // Measures and creates bitmap
            var size:uint = Sprite.DEFAULT_SIZE;
            var totalX:int = m_thing.patternZ * m_thing.patternX * m_thing.layers;
            var totalY:int = m_thing.frames * m_thing.patternY;
            var bitmapWidth:Number = (totalX * m_thing.width) * size;
            var bitmapHeight:Number = (totalY * m_thing.height) * size;
            var pixelsWidth:int = m_thing.width * size;
            var pixelsHeight:int = m_thing.height * size;
            var bitmap:BitmapData = new BitmapData(bitmapWidth, bitmapHeight, true, backgroundColor);
            
            if (textureIndex)
                textureIndex.length = m_thing.layers * m_thing.patternX * m_thing.patternY * m_thing.patternZ * m_thing.frames;
            
            for (var f:uint = 0; f < m_thing.frames; f++)
            {
                for (var z:uint = 0; z < m_thing.patternZ; z++)
                {
                    for (var y:uint = 0; y < m_thing.patternY; y++)
                    {
                        for (var x:uint = 0; x < m_thing.patternX; x++)
                        {
                            for (var l:uint = 0; l < m_thing.layers; l++)
                            {
                                var index:uint = thing.getTextureIndex(l, x, y, z, f);
                                var fx:int = (index % totalX) * pixelsWidth;
                                var fy:int = Math.floor(index / totalX) * pixelsHeight;
                                
                                if (textureIndex)
                                    textureIndex[index] = new Rect(fx, fy, pixelsWidth, pixelsHeight);
                                
                                for (var w:uint = 0; w < m_thing.width; w++)
                                {
                                    for (var h:uint = 0; h < m_thing.height; h++)
                                    {
                                        index = thing.getSpriteIndex(w, h, l, x, y, z, f);
                                        var px:int = ((m_thing.width - w - 1) * size);
                                        var py:int = ((m_thing.height - h - 1) * size);
                                        copyPixels(index, bitmap, px + fx, py + fy);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return bitmap;
        }
        
        public function getColoredSpriteSheet(outfitData:OutfitData):BitmapData
        {
            if (!outfitData)
                throw new NullArgumentError("outfitData");
            
            var textureRectList:Vector.<Rect> = new Vector.<Rect>();
            var spriteSheet:BitmapData = getSpriteSheet(textureRectList, 0x00000000);
            spriteSheet = SpriteUtils.removeMagenta(spriteSheet);
            
            if (m_thing.layers != 2)
                return spriteSheet;
            
            var size:uint = Sprite.DEFAULT_SIZE;
            var totalX:int = m_thing.patternZ * m_thing.patternX * m_thing.layers;
            var totalY:int = m_thing.height;
            var pixelsWidth:int  = m_thing.width * size;
            var pixelsHeight:int = m_thing.height * size;
            var bitmapWidth:uint = m_thing.patternZ * m_thing.patternX * pixelsWidth;
            var bitmapHeight:uint = m_thing.frames * pixelsHeight;
            var numSprites:uint = m_thing.layers * m_thing.patternX * m_thing.patternY * m_thing.patternZ * m_thing.frames;
            var grayBitmap:BitmapData = new BitmapData(bitmapWidth, bitmapHeight, true, 0);
            var blendBitmap:BitmapData = new BitmapData(bitmapWidth, bitmapHeight, true, 0);
            var colorBitmap:BitmapData = new BitmapData(bitmapWidth, bitmapHeight, true, 0);
            var bitmap:BitmapData = new BitmapData(bitmapWidth, bitmapHeight, true, 0);
            var bitmapRect:Rectangle = bitmap.rect;
            var rectList:Vector.<Rect> = new Vector.<Rect>(numSprites, true);
            var index:uint;
            var f:uint;
            var x:uint;
            var y:uint;
            var z:uint;
            
            for (f = 0; f < m_thing.frames; f++)
            {
                for (z = 0; z < m_thing.patternZ; z++)
                {
                    for (x = 0; x < m_thing.patternX; x++)
                    {
                        index = (((f % m_thing.frames * m_thing.patternZ + z) * m_thing.patternY + y) * m_thing.patternX + x) * m_thing.layers;
                        rectList[index] = new Rect((z * m_thing.patternX + x) * pixelsWidth, f * pixelsHeight, pixelsWidth, pixelsHeight);
                    }
                }
            }
            
            for (y = 0; y < m_thing.patternY; y++) {
                if (y == 0 || (outfitData.addons & 1 << (y - 1)) != 0) {
                    for (f = 0; f < m_thing.frames; f++) {
                        for (z = 0; z < m_thing.patternZ; z++) {
                            for (x = 0; x < m_thing.patternX; x++) {
                                var i:uint = (((f % m_thing.frames * m_thing.patternZ + z) * m_thing.patternY + y) * m_thing.patternX + x) * m_thing.layers;
                                var rect:Rect = textureRectList[i];
                                RECTANGLE.setTo(rect.x, rect.y, rect.width, rect.height);
                                
                                index = (((f * m_thing.patternZ + z) * m_thing.patternY) * m_thing.patternX + x) * m_thing.layers;
                                rect = rectList[index];
                                POINT.setTo(rect.x, rect.y);
                                grayBitmap.copyPixels(spriteSheet, RECTANGLE, POINT);
                                
                                i++;
                                rect = textureRectList[i];
                                RECTANGLE.setTo(rect.x, rect.y, rect.width, rect.height);
                                blendBitmap.copyPixels(spriteSheet, RECTANGLE, POINT);
                            }
                        }
                    }
                    
                    POINT.setTo(0, 0);
                    setColor(colorBitmap, grayBitmap, blendBitmap, bitmapRect, BitmapDataChannel.BLUE, ColorUtils.HSItoARGB(outfitData.feet));
                    blendBitmap.applyFilter(blendBitmap, bitmapRect, POINT, MATRIX_FILTER);
                    setColor(colorBitmap, grayBitmap, blendBitmap, bitmapRect, BitmapDataChannel.BLUE, ColorUtils.HSItoARGB(outfitData.head));
                    setColor(colorBitmap, grayBitmap, blendBitmap, bitmapRect, BitmapDataChannel.RED, ColorUtils.HSItoARGB(outfitData.body));
                    setColor(colorBitmap, grayBitmap, blendBitmap, bitmapRect, BitmapDataChannel.GREEN, ColorUtils.HSItoARGB(outfitData.legs));
                    bitmap.copyPixels(grayBitmap, bitmapRect, POINT, null, null, true);
                }
            }
            
            grayBitmap.dispose();
            blendBitmap.dispose();
            colorBitmap.dispose();
            return bitmap;
        }
        
        public function setSpriteSheet(bitmap:BitmapData):void
        {
            if (!bitmap)
                throw new NullArgumentError("bitmap");
            
            var rectSize:Rect = SpriteUtils.getSpriteSheetSize(thing);
            if (bitmap.width != rectSize.width ||
                bitmap.height != rectSize.height) return;
            
            bitmap = SpriteUtils.removeMagenta(bitmap);
            
            var size:uint = Sprite.DEFAULT_SIZE;
            var totalX:int = m_thing.patternZ * m_thing.patternX * m_thing.layers;
            var pixelsWidth:int  = m_thing.width * size;
            var pixelsHeight:int = m_thing.height * size;
            
            POINT.setTo(0, 0);
            
            for (var f:uint = 0; f < m_thing.frames; f++)
            {
                for (var z:uint = 0; z < m_thing.patternZ; z++)
                {
                    for (var y:uint = 0; y < m_thing.patternY; y++)
                    {
                        for (var x:uint = 0; x < m_thing.patternX; x++)
                        {
                            for (var l:uint = 0; l < m_thing.layers; l++)
                            {
                                var index:uint = m_thing.getTextureIndex(l, x, y, z, f);
                                var fx:int = (index % totalX) * pixelsWidth;
                                var fy:int = Math.floor(index / totalX) * pixelsHeight;
                                
                                for (var w:uint = 0; w < m_thing.width; w++)
                                {
                                    for (var h:uint = 0; h < m_thing.height; h++)
                                    {
                                        index = m_thing.getSpriteIndex(w, h, l, x, y, z, f);
                                        var px:int = ((m_thing.width - w - 1) * size);
                                        var py:int = ((m_thing.height - h - 1) * size);
                                        
                                        RECTANGLE.setTo(px + fx, py + fy, size, size);
                                        var bmp:BitmapData = new BitmapData(size, size, true, 0x00000000);
                                        bmp.copyPixels(bitmap, RECTANGLE, POINT);
                                        
                                        var sd:SpriteData = new SpriteData();
                                        sd.pixels = bmp.getPixels(bmp.rect);
                                        sd.id = uint.MAX_VALUE;
                                        
                                        m_sprites[index] = sd;
                                        m_thing.spriteIndex[index] = sd.id;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        public function colorize(outfitData:OutfitData):void
        {
            if (!outfitData)
                throw new NullArgumentError("outfitData");
            
            if (m_thing.category != ThingCategory.OUTFIT) return;
            
            var bitmap:BitmapData = getColoredSpriteSheet(outfitData);
            
            m_thing.patternY = 1; // Decrease addons
            m_thing.layers = 1; // Decrease layers 
            m_thing.spriteIndex = new Vector.<uint>(m_thing.getTotalSprites(), true);
            m_sprites = new Vector.<SpriteData>(m_thing.getTotalSprites(), true);
            setSpriteSheet(bitmap);
        }
        
        public function clone():ThingData
        {
            var length:uint = m_sprites.length;
            
            var td:ThingData = new ThingData();
            td.m_version = m_version;
            td.m_thing = m_thing.clone();
            td.m_sprites = new Vector.<SpriteData>(length, true);
            
            for (var i:uint = 0; i < length; i++)
                td.m_sprites[i] = m_sprites[i].clone();
           
            return td;
        }
        
        //--------------------------------------
        // Private
        //--------------------------------------
        
        private function copyPixels(index:uint, bitmap:BitmapData, x:uint, y:uint):void
        {
            if (index < m_sprites.length)
            {
                var sd:SpriteData = m_sprites[index];
                if (sd && sd.pixels)
                {
                    var bmp:BitmapData = sd.getBitmap();
                    if (bmp)
                    {
                        sd.pixels.position = 0;
                        RECTANGLE.setTo(0, 0, bmp.width, bmp.height);
                        POINT.setTo(x, y);
                        bitmap.copyPixels(bmp, RECTANGLE, POINT, null, null, true);
                    }
                }
            }
        }
        
        private function setColor(canvas:BitmapData,
                                  grey:BitmapData,
                                  blend:BitmapData,
                                  rect:Rectangle,
                                  channel:uint,
                                  color:uint):void
        {
            POINT.setTo(0, 0);
            COLOR_TRANSFORM.redMultiplier = (color >> 16 & 0xFF) / 0xFF;
            COLOR_TRANSFORM.greenMultiplier = (color >> 8 & 0xFF) / 0xFF;
            COLOR_TRANSFORM.blueMultiplier = (color & 0xFF) / 0xFF;
            
            canvas.copyPixels(grey, rect, POINT);
            canvas.copyChannel(blend, rect, POINT, channel, BitmapDataChannel.ALPHA);
            canvas.colorTransform(rect, COLOR_TRANSFORM);
            grey.copyPixels(canvas, rect, POINT, null, null, true);
        }
        
        //--------------------------------------------------------------------------
        // STATIC
        //--------------------------------------------------------------------------
        
        public static const OBD_MAJOR_VERSION:uint = 2;
        public static const OBD_MINOR_VERSION:uint = 0;
        
        private static const RECTANGLE:Rectangle = new Rectangle(0, 0, 32, 32);
        private static const POINT:Point = new Point();
        private static const COLOR_TRANSFORM:ColorTransform = new ColorTransform();
        private static const MATRIX_FILTER:ColorMatrixFilter = new ColorMatrixFilter([1, -1,    0, 0,
                                                                                      0, -1,    1, 0,
                                                                                      0,  0,    1, 1,
                                                                                      0,  0, -255, 0,
                                                                                      0, -1,    1, 0]);
        
        public static function createThingData(version:uint, thing:ThingType, sprites:Vector.<SpriteData>):ThingData
        {
            if (!thing)
                throw new NullArgumentError("thing");
            
            if (!sprites)
                throw new NullArgumentError("sprites");
            
            if (thing.spriteIndex.length != sprites.length)
                throw new ArgumentError("Invalid sprites length.");
            
            var thingData:ThingData = new ThingData();
            thingData.version = version;
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
            if (!data)
                throw new NullArgumentError("data");
            
            if (!version)
                throw new NullArgumentError("version");
            
            var thing:ThingType = data.thing;
            var bytes:ByteArray = new ByteArray();
            bytes.endian = Endian.LITTLE_ENDIAN;
            
            bytes.writeByte(OBD_MAJOR_VERSION);                         // Write major file version
            bytes.writeByte(OBD_MINOR_VERSION);                         // Write minor file version
            bytes.writeShort(version.value);                            // Write client version
            bytes.writeByte(ThingCategory.getValue(thing.category));    // Write thing category
            
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
            if (!bytes)
                throw new NullArgumentError("bytes");
            
            bytes.position = 0;
            bytes.endian = Endian.LITTLE_ENDIAN;
            bytes.uncompress(CompressionAlgorithm.LZMA);
            
            var versions:Vector.<Version>;
            var version:Version;
            var category:String;
            var newObd:Boolean = (bytes.readUnsignedByte() == OBD_MAJOR_VERSION);
            
            if (newObd) {
                bytes.readUnsignedByte(); // Reads obd minor version.
                versions = VersionStorage.getInstance().getByValue( bytes.readUnsignedShort() );
                category = ThingCategory.getCategoryByValue( bytes.readUnsignedByte() );
            } else {
                bytes.position = 0;
                versions = VersionStorage.getInstance().getByValue( bytes.readUnsignedShort() );
                category = ThingCategory.getCategory( bytes.readUTF() );
            }
            
            if (versions.length == 0)
                throw new Error("Unsupported version.");
            
            version = versions[0];
            
            if (category == null)
                throw new Error("Invalid thing category.");
            
            var thing:ThingType = new ThingType();
            thing.category = category;
            
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
            
            if (newObd)
                return readSprites(version.value, thing, bytes);
            
            return readThingSprites(version.value, thing, bytes);
        }
        
        private static function writeSprites(data:ThingData, bytes:ByteArray):Boolean
        { 
            var thing:ThingType = data.thing;
            
            bytes.writeByte(thing.width);  // Write width
            bytes.writeByte(thing.height); // Write height
            
            if (thing.width > 1 || thing.height > 1)
                bytes.writeByte(thing.exactSize); // Write exact size
            
            bytes.writeByte(thing.layers);          // Write layers
            bytes.writeByte(thing.patternX);        // Write pattern X
            bytes.writeByte(thing.patternY);        // Write pattern Y
            bytes.writeByte(thing.patternZ || 1);   // Write pattern Z
            bytes.writeByte(thing.frames);          // Write frames
            
            var length:uint;
            var i:uint;
            
            if (thing.isAnimation) {
                
                var animator:Animator = thing.animator;
                bytes.writeByte(animator.animationMode); // Write animation type
                bytes.writeInt(animator.frameStrategy);  // Write frame Strategy
                bytes.writeByte(animator.startFrame);    // Write start frame
                
                var frameDuration:Vector.<FrameDuration> = animator.frameDurations;
                length = frameDuration.length;
                for (i = 0; i < length; i++) {
                    bytes.writeUnsignedInt(frameDuration[i].minimum); // Write minimum duration
                    bytes.writeUnsignedInt(frameDuration[i].maximum); // Write maximum duration
                }
            }
            
            var spriteList:Vector.<uint> = thing.spriteIndex;
            length = spriteList.length;
            for (i = 0; i < length; i++) {
                var spriteId:uint = spriteList[i];
                
                var spriteData:SpriteData = data.sprites[i];
                if (!spriteData || !spriteData.pixels)
                    throw new Error(StringUtil.format("Invalid sprite id.", spriteId));
                
                var pixels:ByteArray = spriteData.pixels;
                pixels.position = 0;
                
                if (pixels.bytesAvailable != 4096)
                    throw new Error(StringUtil.format("Invalid pixels length."));
                
                bytes.writeUnsignedInt(spriteId);
                bytes.writeBytes(pixels, 0, pixels.bytesAvailable);
            }
            return true;
        }
        
        private static function readSprites(version:uint, thing:ThingType, bytes:ByteArray):ThingData
        {
            thing.width  = bytes.readUnsignedByte();
            thing.height = bytes.readUnsignedByte();
            
            if (thing.width > 1 || thing.height > 1)
                thing.exactSize = bytes.readUnsignedByte();
            else 
                thing.exactSize = Sprite.DEFAULT_SIZE;
            
            thing.layers = bytes.readUnsignedByte();
            thing.patternX = bytes.readUnsignedByte();
            thing.patternY = bytes.readUnsignedByte();
            thing.patternZ = bytes.readUnsignedByte() || 1;
            thing.frames = bytes.readUnsignedByte();
            
            var totalSprites:uint = thing.getTotalSprites();
            if (totalSprites > 4096)
                throw new Error("Thing has more than 4096 sprites.");
            
            var i:uint;
            
            if (thing.frames > 1) {
                thing.isAnimation = true;
                
                var animationType:uint = bytes.readUnsignedByte();  // Read animation type
                var frameStrategy:int = bytes.readInt();            // Read frame Strategy
                var startFrame:uint = bytes.readByte();             // Read start frame
                var frameDurations:Vector.<FrameDuration> = new Vector.<FrameDuration>(thing.frames, true);
                
                for (i = 0; i < thing.frames; i++) {
                    // Read minimum and maximum frame duration
                    frameDurations[i] = new FrameDuration(bytes.readUnsignedInt(), bytes.readUnsignedInt());
                }
                
                thing.animator = Animator.create(thing.frames,
                                                 startFrame,
                                                 frameStrategy,
                                                 animationType,
                                                 frameDurations);
            }
            
            thing.spriteIndex = new Vector.<uint>(totalSprites);
            var sprites:Vector.<SpriteData> = new Vector.<SpriteData>(totalSprites);
            
            for (i = 0; i < totalSprites; i++) {
                var spriteId:uint = bytes.readUnsignedInt();
                thing.spriteIndex[i] = spriteId;
                
                var pixels:ByteArray = new ByteArray();
                pixels.endian = Endian.BIG_ENDIAN;
                
                bytes.readBytes(pixels, 0, 4096);
                pixels.position = 0;
                
                var spriteData:SpriteData = new SpriteData();
                spriteData.id = spriteId;
                spriteData.pixels = pixels;
                sprites[i] = spriteData;
            }
            
            return createThingData(version, thing, sprites);
        }
        
        /**
         * @private
         * 
         * Reads old OBD files. It will be removed in future revision.
         */
        private static function readThingSprites(version:uint, thing:ThingType, bytes:ByteArray):ThingData
        {
            thing.width  = bytes.readUnsignedByte();
            thing.height = bytes.readUnsignedByte();
            
            if (thing.width > 1 || thing.height > 1)
                thing.exactSize = bytes.readUnsignedByte();
            else 
                thing.exactSize = Sprite.DEFAULT_SIZE;
            
            thing.layers = bytes.readUnsignedByte();
            thing.patternX = bytes.readUnsignedByte();
            thing.patternY = bytes.readUnsignedByte();
            thing.patternZ = bytes.readUnsignedByte();
            thing.frames = bytes.readUnsignedByte();
            
            var totalSprites:uint = thing.getTotalSprites();
            if (totalSprites > 4096)
                throw new Error("Thing has more than 4096 sprites.");
            
            var i:uint;
            
            if (thing.frames > 1) {
                thing.isAnimation = true;
                
                var animationType:uint = thing.category == ThingCategory.ITEM ? 1 : 0;
                var frameStrategy:int = thing.category == ThingCategory.EFFECT ? 1 : 0;
                var frameDurations:Vector.<FrameDuration> = new Vector.<FrameDuration>(thing.frames, true);
                var duration:uint = FrameDuration.getDefaultDuration(thing.category);
                
                for (i = 0; i < thing.frames; i++)
                    frameDurations[i] = new FrameDuration(duration, duration);
                
                thing.animator = Animator.create(thing.frames,
                                                 0,
                                                 frameStrategy,
                                                 animationType,
                                                 frameDurations);
            }
            
            thing.spriteIndex = new Vector.<uint>(totalSprites);
            var sprites:Vector.<SpriteData> = new Vector.<SpriteData>(totalSprites);
            
            for (i = 0; i < totalSprites; i++) {
                var spriteId:uint = bytes.readUnsignedInt();
                var length:uint = bytes.readUnsignedInt();
                if (length > bytes.bytesAvailable)
                    throw new Error("Not enough data.");
                
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
            return createThingData(version, thing, sprites);
        }
    }
}
