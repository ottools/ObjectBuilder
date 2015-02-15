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

package otlib.obd
{
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.utils.ByteArray;
    import flash.utils.CompressionAlgorithm;
    import flash.utils.Endian;
    import flash.utils.IDataInput;
    import flash.utils.IDataOutput;
    
    import nail.errors.NullArgumentError;
    import nail.utils.StringUtil;
    
    import otlib.core.Version;
    import otlib.core.VersionStorage;
    import otlib.resources.Resources;
    import otlib.sprites.Sprite;
    import otlib.sprites.SpriteData;
    import otlib.things.AnimationMode;
    import otlib.things.Animator;
    import otlib.things.FrameDuration;
    import otlib.things.FrameStrategyType;
    import otlib.things.ThingCategory;
    import otlib.things.ThingData;
    import otlib.things.ThingSerializer;
    import otlib.things.ThingType;
    import otlib.utils.OTFormat;

    public class OBDEncoder
    {
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function OBDEncoder()
        {
            
        }
        
        //--------------------------------------------------------------------------
        // METHODS
        //--------------------------------------------------------------------------
        
        //--------------------------------------
        // Public
        //--------------------------------------
        
        public function encode(data:ThingData, obdVersion:uint = 25):ByteArray
        {
            if (!data)
                throw new NullArgumentError("data");
            
            if (obdVersion == 25)
                return encodeV2_5(data);
            else if (obdVersion == 2)
                return encodeV2(data);
            else if (obdVersion == 1)
                return encodeV1(data);
            
            throw new Error(StringUtil.format("Invalid OBD version {0}", obdVersion));
        }
        
        public function decode(bytes:ByteArray):ThingData
        {
            if (!bytes)
                throw new NullArgumentError("bytes");
            
            bytes.position = 0;
            bytes.endian = Endian.LITTLE_ENDIAN;
            bytes.uncompress(CompressionAlgorithm.LZMA);
            
            var version:uint = bytes.readUnsignedByte();
            if (version == 2)
            {
                var minor:uint = bytes.readUnsignedByte();
                if (minor == 5)
                    return decodeV2_5(bytes);
                else if (minor == 0)
                    return decodeV2(bytes);
            }
            else
            {
                bytes.position = 0;
                
                if (bytes.readUnsignedShort() >= 710)
                    return decodeV1(bytes);
            }
            
            throw new Error(StringUtil.format("Invalid OBD version {0}", version));
        }
        
        public function decodeFromFile(file:File):ThingData
        {
            if (!file || file.extension != OTFormat.OBD || !file.exists)
                return null;
            
            var bytes:ByteArray = new ByteArray();
            var stream:FileStream = new FileStream();
            stream.open(file, FileMode.READ);
            stream.readBytes(bytes, 0, stream.bytesAvailable);
            stream.close();
            
            return decode(bytes);
        }
        
        //--------------------------------------
        // Private
        //--------------------------------------
        
        private function encodeV1(data:ThingData):ByteArray
        {
            var thing:ThingType = data.thing;
            var version:uint = data.version;
            var bytes:ByteArray = new ByteArray();
            bytes.endian = Endian.LITTLE_ENDIAN;
            bytes.writeShort(version);      // Write client version
            bytes.writeUTF(thing.category); // Write object category
            
            var done:Boolean;
            if (version <= 730)
                done = ThingSerializer.writeProperties1(thing, bytes);
            else if (version <= 750)
                done = ThingSerializer.writeProperties2(thing, bytes);
            else if (version <= 772)
                done = ThingSerializer.writeProperties3(thing, bytes);
            else if (version <= 854)
                done = ThingSerializer.writeProperties4(thing, bytes);
            else if (version <= 986)
                done = ThingSerializer.writeProperties5(thing, bytes);
            else
                done = ThingSerializer.writeProperties6(thing, bytes);
            
            if (!done) return null;
            
            bytes.writeByte(thing.width);  // Write width
            bytes.writeByte(thing.height); // Write height
            
            if (thing.width > 1 || thing.height > 1)
                bytes.writeByte(thing.exactSize); // Write exact size
            
            bytes.writeByte(thing.layers);   // Write layers
            bytes.writeByte(thing.patternX); // Write pattern X
            bytes.writeByte(thing.patternY); // Write pattern Y
            bytes.writeByte(thing.patternZ); // Write pattern Z
            bytes.writeByte(thing.frames);   // Write frames
            
            var sprites:Vector.<SpriteData> = data.sprites;
            var spriteList:Vector.<uint> = thing.spriteIndex;
            var length:uint = spriteList.length;
            
            for (var i:uint = 0; i < length; i++)
            {
                var spriteId:uint = spriteList[i];
                var spriteData:SpriteData = sprites[i];
                
                if (!spriteData || !spriteData.pixels)
                    throw new Error(StringUtil.format("Invalid sprite id {0}.", spriteId));
                
                var pixels:ByteArray = spriteData.pixels;
                pixels.position = 0;
                bytes.writeUnsignedInt(spriteId);
                bytes.writeUnsignedInt(pixels.length);
                bytes.writeBytes(pixels, 0, pixels.bytesAvailable);
            }
            
            bytes.compress(CompressionAlgorithm.LZMA);
            return bytes;
        }
        
        private function encodeV2(data:ThingData):ByteArray
        {
            var thing:ThingType = data.thing;
            var version:uint = data.version;
            var bytes:ByteArray = new ByteArray();
            bytes.endian = Endian.LITTLE_ENDIAN;
            bytes.writeByte(2);                                         // Write major file version
            bytes.writeByte(0);                                         // Write minor file version
            bytes.writeShort(version);                                  // Write client version
            bytes.writeByte( ThingCategory.getValue(thing.category) ); // Write thing category
            
            var done:Boolean;
            if (version <= 730)
                done = ThingSerializer.writeProperties1(thing, bytes);
            else if (version <= 750)
                done = ThingSerializer.writeProperties2(thing, bytes);
            else if (version <= 772)
                done = ThingSerializer.writeProperties3(thing, bytes);
            else if (version <= 854)
                done = ThingSerializer.writeProperties4(thing, bytes);
            else if (version <= 986)
                done = ThingSerializer.writeProperties5(thing, bytes);
            else
                done = ThingSerializer.writeProperties6(thing, bytes);
            
            if (!done) return null;
            
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
            
            if (thing.isAnimation)
            {
                var animator:Animator = thing.animator;
                bytes.writeByte(animator.animationMode); // Write animation type
                bytes.writeInt(animator.frameStrategy);  // Write frame Strategy
                bytes.writeByte(animator.startFrame);    // Write start frame
                
                var frameDuration:Vector.<FrameDuration> = animator.frameDurations;
                length = frameDuration.length;
                for (i = 0; i < length; i++)
                {
                    bytes.writeUnsignedInt(frameDuration[i].minimum); // Write minimum duration
                    bytes.writeUnsignedInt(frameDuration[i].maximum); // Write maximum duration
                }
            }
            
            var sprites:Vector.<SpriteData> = data.sprites;
            var spriteList:Vector.<uint> = thing.spriteIndex;
            length = spriteList.length;
            
            for (i = 0; i < length; i++)
            {
                var spriteId:uint = spriteList[i];
                var spriteData:SpriteData = sprites[i];
                
                if (!spriteData || !spriteData.pixels)
                    throw new Error(StringUtil.format("Invalid sprite id {0}.", spriteId));
                
                var pixels:ByteArray = spriteData.pixels;
                pixels.position = 0;
                
                if (pixels.bytesAvailable != 4096)
                    throw new Error(StringUtil.format("Invalid pixels length."));
                
                bytes.writeUnsignedInt(spriteId);
                bytes.writeBytes(pixels, 0, pixels.bytesAvailable);
            }
            
            bytes.compress(CompressionAlgorithm.LZMA);
            return bytes;
        }
        
        private function encodeV2_5(data:ThingData):ByteArray
        {
            var thing:ThingType = data.thing;
            var version:uint = data.version;
            var bytes:ByteArray = new ByteArray();
            bytes.endian = Endian.LITTLE_ENDIAN;
            bytes.writeByte(2);                                         // Write major file version
            bytes.writeByte(5);                                         // Write minor file version
            bytes.writeShort(version);                                  // Write client version
            bytes.writeByte( ThingCategory.getValue(thing.category) );  // Write thing category
            
            if (!writeProperties(thing, bytes)) return null;
            
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
            
            if (thing.isAnimation)
            {
                var animator:Animator = thing.animator;
                bytes.writeByte(animator.animationMode); // Write animation type
                bytes.writeInt(animator.frameStrategy);  // Write frame Strategy
                bytes.writeByte(animator.startFrame);    // Write start frame
                
                var frameDuration:Vector.<FrameDuration> = animator.frameDurations;
                length = frameDuration.length;
                for (i = 0; i < length; i++)
                {
                    bytes.writeUnsignedInt(frameDuration[i].minimum); // Write minimum duration
                    bytes.writeUnsignedInt(frameDuration[i].maximum); // Write maximum duration
                }
            }
            
            var sprites:Vector.<SpriteData> = data.sprites;
            var spriteList:Vector.<uint> = thing.spriteIndex;
            length = spriteList.length;
            
            for (i = 0; i < length; i++)
            {
                var spriteId:uint = spriteList[i];
                var spriteData:SpriteData = sprites[i];
                
                if (!spriteData || !spriteData.pixels)
                    throw new Error(StringUtil.format("Invalid sprite id {0}.", spriteId));
                
                var pixels:ByteArray = spriteData.pixels;
                pixels.position = 0;
                
                if (pixels.bytesAvailable != 4096)
                    throw new Error(StringUtil.format("Invalid pixels length."));
                
                bytes.writeUnsignedInt(spriteId);
                bytes.writeBytes(pixels, 0, pixels.bytesAvailable);
            }
            
            bytes.compress(CompressionAlgorithm.LZMA);
            return bytes;
        }
        
        private function decodeV1(bytes:ByteArray):ThingData
        {
            if (!bytes)
                throw new NullArgumentError("bytes");
            
            bytes.position = 0;
            
            var versionValue:uint = bytes.readUnsignedShort();
            var versions:Vector.<Version> = VersionStorage.getInstance().getByValue(versionValue);
            if (versions.length == 0)
                throw new Error(StringUtil.format("Unsupported version {0}.", versionValue));
            
            var category:String = bytes.readUTF();
            if (!ThingCategory.isValid(category))
                throw new Error("Invalid thing category.");
            
            var version:uint = versions[0].value;
            var thing:ThingType = new ThingType();
            thing.category = category;
            
            var done:Boolean;
            if (version <= 730)
                done = ThingSerializer.readProperties1(thing, bytes);
            else if (version <= 750)
                done = ThingSerializer.readProperties2(thing, bytes);
            else if (version <= 772)
                done = ThingSerializer.readProperties3(thing, bytes);
            else if (version <= 854)
                done = ThingSerializer.readProperties4(thing, bytes);
            else if (version <= 986)
                done = ThingSerializer.readProperties5(thing, bytes);
            else
                done = ThingSerializer.readProperties6(thing, bytes);
            
            if (!done) return null;
            
            thing.width = bytes.readUnsignedByte();
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
            
            var i:uint = 0;
            
            if (thing.frames > 1)
            {
                thing.isAnimation = true;
                
                var animationMode:uint = AnimationMode.ASYNCHRONOUS;
                var frameStrategy:int = FrameStrategyType.LOOP;
                var startFrame:int = -1;
                var frameDurations:Vector.<FrameDuration> = new Vector.<FrameDuration>(thing.frames, true);
                var duration:uint = FrameDuration.getDefaultDuration(thing.category);
                
                for (i = 0; i < thing.frames; i++)
                    frameDurations[i] = new FrameDuration(duration, duration);
                
                thing.animator = Animator.create(thing.frames,
                                                 startFrame,
                                                 frameStrategy,
                                                 animationMode,
                                                 frameDurations);
            }
            
            var totalSprites:uint = thing.getTotalSprites();
            if (totalSprites > 4096)
                throw new Error("The Object Data has more than 4096 sprites.");
            
            thing.spriteIndex = new Vector.<uint>(totalSprites, true);
            var sprites:Vector.<SpriteData> = new Vector.<SpriteData>(totalSprites, true);
            
            for (i = 0; i < totalSprites; i++)
            {
                var spriteId:uint = bytes.readUnsignedInt();
                thing.spriteIndex[i] = spriteId;
                
                var dataSize:uint = bytes.readUnsignedInt();
                if (dataSize > 4096)
                    throw new Error("Invalid sprite data size.");
                
                var pixels:ByteArray = new ByteArray();
                pixels.endian = Endian.BIG_ENDIAN;
                
                bytes.readBytes(pixels, 0, dataSize);
                
                var spriteData:SpriteData = new SpriteData();
                spriteData.id = spriteId;
                spriteData.pixels = pixels;
                sprites[i] = spriteData;
            }
            
            return ThingData.createThingData(version, thing, sprites);
        }
        
        private function decodeV2(bytes:ByteArray):ThingData
        {
            bytes.position = 0;
            bytes.readUnsignedByte(); // OBD major version
            bytes.readUnsignedByte(); // OBD minor version
            
            var versionValue:uint = bytes.readUnsignedShort(); // Client version
            var versions:Vector.<Version> = VersionStorage.getInstance().getByValue(versionValue);
            if (versions.length == 0)
                throw new Error(StringUtil.format("Unsupported version {0}.", versionValue));
            
            var category:String = ThingCategory.getCategoryByValue( bytes.readUnsignedByte() );
            if (!ThingCategory.isValid(category))
                throw new Error("Invalid object category.");
            
            var version:uint = versions[0].value;
            var thing:ThingType = new ThingType();
            thing.category = category;
            
            var done:Boolean;
            if (version <= 730)
                done = ThingSerializer.readProperties1(thing, bytes);
            else if (version <= 750)
                done = ThingSerializer.readProperties2(thing, bytes);
            else if (version <= 772)
                done = ThingSerializer.readProperties3(thing, bytes);
            else if (version <= 854)
                done = ThingSerializer.readProperties4(thing, bytes);
            else if (version <= 986)
                done = ThingSerializer.readProperties5(thing, bytes);
            else
                done = ThingSerializer.readProperties6(thing, bytes);
            
            if (!done) return null;
            
            thing.width = bytes.readUnsignedByte();
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
            
            var i:uint = 0;
            
            if (thing.frames > 1)
            {
                thing.isAnimation = true;
                
                var animationMode:uint = bytes.readUnsignedByte();
                var frameStrategy:int = bytes.readInt();
                var startFrame:int = bytes.readByte();
                var frameDurations:Vector.<FrameDuration> = new Vector.<FrameDuration>(thing.frames, true);
                
                for (i = 0; i < thing.frames; i++)
                {
                    var minimum:uint = bytes.readUnsignedInt();
                    var maximum:uint = bytes.readUnsignedInt();
                    frameDurations[i] = new FrameDuration(minimum, maximum);
                }
                
                thing.animator = Animator.create(thing.frames,
                                                 startFrame,
                                                 frameStrategy,
                                                 animationMode,
                                                 frameDurations);
            }
            
            var totalSprites:uint = thing.getTotalSprites();
            if (totalSprites > 4096)
                throw new Error("The Object Data has more than 4096 sprites.");
            
            thing.spriteIndex = new Vector.<uint>(totalSprites, true);
            var sprites:Vector.<SpriteData> = new Vector.<SpriteData>(totalSprites, true);
            
            for (i = 0; i < totalSprites; i++)
            {
                var spriteId:uint = bytes.readUnsignedInt();
                thing.spriteIndex[i] = spriteId;
                
                var pixels:ByteArray = new ByteArray();
                pixels.endian = Endian.BIG_ENDIAN;
                
                bytes.readBytes(pixels, 0, 4096);
                
                var spriteData:SpriteData = new SpriteData();
                spriteData.id = spriteId;
                spriteData.pixels = pixels;
                sprites[i] = spriteData;
            }
            
            return ThingData.createThingData(version, thing, sprites);
        }
        
        private function decodeV2_5(bytes:ByteArray):ThingData
        {
            bytes.position = 0;
            bytes.readUnsignedByte(); // OBD major version
            bytes.readUnsignedByte(); // OBD minor version
            
            var versionValue:uint = bytes.readUnsignedShort(); // Client version
            var versions:Vector.<Version> = VersionStorage.getInstance().getByValue(versionValue);
            if (versions.length == 0)
                throw new Error(StringUtil.format("Unsupported version {0}.", versionValue));
            
            var category:String = ThingCategory.getCategoryByValue( bytes.readUnsignedByte() );
            if (!ThingCategory.isValid(category))
                throw new Error("Invalid object category.");
            
            var version:uint = versions[0].value;
            var thing:ThingType = new ThingType();
            thing.category = category;
            
            if (!readProperties(thing, bytes)) return null;
            
            thing.width = bytes.readUnsignedByte();
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
            
            var i:uint = 0;
            
            if (thing.frames > 1)
            {
                thing.isAnimation = true;
                
                var animationMode:uint = bytes.readUnsignedByte();
                var frameStrategy:int = bytes.readInt();
                var startFrame:int = bytes.readByte();
                var frameDurations:Vector.<FrameDuration> = new Vector.<FrameDuration>(thing.frames, true);
                
                for (i = 0; i < thing.frames; i++)
                {
                    var minimum:uint = bytes.readUnsignedInt();
                    var maximum:uint = bytes.readUnsignedInt();
                    frameDurations[i] = new FrameDuration(minimum, maximum);
                }
                
                thing.animator = Animator.create(thing.frames,
                                                 startFrame,
                                                 frameStrategy,
                                                 animationMode,
                                                 frameDurations);
            }
            
            var totalSprites:uint = thing.getTotalSprites();
            if (totalSprites > 4096)
                throw new Error("The Object Data has more than 4096 sprites.");
            
            thing.spriteIndex = new Vector.<uint>(totalSprites, true);
            var sprites:Vector.<SpriteData> = new Vector.<SpriteData>(totalSprites, true);
            
            for (i = 0; i < totalSprites; i++)
            {
                var spriteId:uint = bytes.readUnsignedInt();
                thing.spriteIndex[i] = spriteId;
                
                var pixels:ByteArray = new ByteArray();
                pixels.endian = Endian.BIG_ENDIAN;
                
                bytes.readBytes(pixels, 0, 4096);
                
                var spriteData:SpriteData = new SpriteData();
                spriteData.id = spriteId;
                spriteData.pixels = pixels;
                sprites[i] = spriteData;
            }
            
            return ThingData.createThingData(version, thing, sprites);
        }
        
        private static function readProperties(thing:ThingType, input:IDataInput):Boolean
        {
            var flag:uint = 0;
            while (flag < LAST_FLAG) {
                
                var previusFlag:uint = flag;
                flag = input.readUnsignedByte();
                if (flag == LAST_FLAG) return true;
                
                switch (flag)
                {
                    case GROUND:
                        thing.isGround = true;
                        thing.groundSpeed = input.readUnsignedShort();
                        break;
                    
                    case GROUND_BORDER:
                        thing.isGroundBorder = true;
                        break;
                    
                    case ON_BOTTOM:
                        thing.isOnBottom = true;
                        break;
                    
                    case ON_TOP:
                        thing.isOnTop = true;
                        break;
                    
                    case CONTAINER:
                        thing.isContainer = true;
                        break;
                    
                    case STACKABLE:
                        thing.stackable = true;
                        break;
                    
                    case FORCE_USE:
                        thing.forceUse = true;
                        break;
                    
                    case MULTI_USE:
                        thing.multiUse = true;
                        break;
                    
                    case WRITABLE:
                        thing.writable = true;
                        thing.maxTextLength = input.readUnsignedShort();
                        break;
                    
                    case WRITABLE_ONCE:
                        thing.writableOnce = true;
                        thing.maxTextLength = input.readUnsignedShort();
                        break;
                    
                    case FLUID_CONTAINER:
                        thing.isFluidContainer = true;
                        break;
                    
                    case FLUID:
                        thing.isFluid = true;
                        break;
                    
                    case UNPASSABLE:
                        thing.isUnpassable = true;
                        break;
                    
                    case UNMOVEABLE:
                        thing.isUnmoveable = true;
                        break;
                    
                    case BLOCK_MISSILE:
                        thing.blockMissile = true;
                        break;
                    
                    case BLOCK_PATHFIND:
                        thing.blockPathfind = true;
                        break;
                    
                    case NO_MOVE_ANIMATION:
                        thing.noMoveAnimation = true;
                        break;
                    
                    case PICKUPABLE:
                        thing.pickupable = true;
                        break;
                    
                    case HANGABLE:
                        thing.hangable = true;
                        break;
                    
                    case HOOK_SOUTH:
                        thing.isVertical = true;
                        break;
                    
                    case HOOK_EAST:
                        thing.isHorizontal = true;
                        break;
                    
                    case ROTATABLE:
                        thing.rotatable = true;
                        break;
                    
                    case HAS_LIGHT:
                        thing.hasLight = true;
                        thing.lightLevel = input.readUnsignedShort();
                        thing.lightColor = input.readUnsignedShort();
                        break;
                    
                    case DONT_HIDE:
                        thing.dontHide = true;
                        break;
                    
                    case TRANSLUCENT:
                        thing.isTranslucent = true;
                        break;
                    
                    case HAS_OFFSET:
                        thing.hasOffset = true;
                        thing.offsetX = input.readUnsignedShort();
                        thing.offsetY = input.readUnsignedShort();
                        break;
                    
                    case HAS_ELEVATION:
                        thing.hasElevation = true;
                        thing.elevation    = input.readUnsignedShort();
                        break;
                    
                    case LYING_OBJECT:
                        thing.isLyingObject = true;
                        break;
                    
                    case ANIMATE_ALWAYS:
                        thing.animateAlways = true;
                        break;
                    
                    case MINI_MAP:
                        thing.miniMap = true;
                        thing.miniMapColor = input.readUnsignedShort();
                        break;
                    
                    case LENS_HELP:
                        thing.isLensHelp = true;
                        thing.lensHelp = input.readUnsignedShort();
                        break;
                    
                    case FULL_GROUND:
                        thing.isFullGround = true;
                        break;
                    
                    case IGNORE_LOOK:
                        thing.ignoreLook = true;
                        break;
                    
                    case CLOTH:
                        thing.cloth = true;
                        thing.clothSlot = input.readUnsignedShort();
                        break;
                    
                    case MARKET_ITEM:
                        thing.isMarketItem = true;
                        thing.marketCategory = input.readUnsignedShort();
                        thing.marketTradeAs = input.readUnsignedShort();
                        thing.marketShowAs = input.readUnsignedShort();
                        var nameLength:uint = input.readUnsignedShort();
                        thing.marketName = input.readMultiByte(nameLength, STRING_CHARSET);
                        thing.marketRestrictProfession = input.readUnsignedShort();
                        thing.marketRestrictLevel = input.readUnsignedShort();
                        break;
                    
                    case DEFAULT_ACTION:
                        thing.hasDefaultAction = true;
                        thing.defaultAction = input.readUnsignedShort();
                        break;
                    
                    case HAS_CHARGES:
                        thing.hasCharges = true;
                        break;
                    
                    case FLOOR_CHANGE:
                        thing.floorChange = true;
                        break;
                    
                    case USABLE:
                        thing.usable = true;
                        break;
                    
                    default:
                        throw new Error(Resources.getString("readUnknownFlag",
                                                            flag.toString(16),
                                                            previusFlag.toString(16),
                                                            Resources.getString(thing.category),
                                                            thing.id));
                }
            }
            
            return true;
        }
        
        private static function writeProperties(thing:ThingType, output:IDataOutput):Boolean
        {
            if (thing.isGround)
            {
                output.writeByte(GROUND);
                output.writeShort(thing.groundSpeed);
            }
            else if (thing.isGroundBorder)
                output.writeByte(GROUND_BORDER);
            else if (thing.isOnBottom)
                output.writeByte(ON_BOTTOM);
            else if (thing.isOnTop)
                output.writeByte(ON_TOP);
            
            if (thing.isContainer) output.writeByte(CONTAINER);
            
            if (thing.stackable) output.writeByte(STACKABLE);
            
            if (thing.forceUse) output.writeByte(FORCE_USE);
            
            if (thing.multiUse) output.writeByte(MULTI_USE);
            
            if (thing.writable)
            {
                output.writeByte(WRITABLE);
                output.writeShort(thing.maxTextLength);
            }
            
            if (thing.writableOnce)
            {
                output.writeByte(WRITABLE_ONCE);
                output.writeShort(thing.maxTextLength);
            }
            
            if (thing.isFluidContainer) output.writeByte(FLUID_CONTAINER);
            
            if (thing.isFluid) output.writeByte(FLUID);
            
            if (thing.isUnpassable) output.writeByte(UNPASSABLE);
            
            if (thing.isUnmoveable) output.writeByte(UNMOVEABLE);
            
            if (thing.blockMissile) output.writeByte(BLOCK_MISSILE);
            
            if (thing.blockPathfind) output.writeByte(BLOCK_PATHFIND);
            
            if (thing.noMoveAnimation) output.writeByte(NO_MOVE_ANIMATION);
            
            if (thing.pickupable) output.writeByte(PICKUPABLE);
            
            if (thing.hangable) output.writeByte(HANGABLE);
            
            if (thing.isVertical) output.writeByte(HOOK_SOUTH);
            
            if (thing.isHorizontal) output.writeByte(HOOK_EAST);
            
            if (thing.rotatable) output.writeByte(ROTATABLE);
            
            if (thing.hasLight)
            {
                output.writeByte(HAS_LIGHT);
                output.writeShort(thing.lightLevel);
                output.writeShort(thing.lightColor);
            }
            
            if (thing.dontHide) output.writeByte(DONT_HIDE);
            
            if (thing.isTranslucent) output.writeByte(TRANSLUCENT);
            
            if (thing.hasOffset)
            {
                output.writeByte(HAS_OFFSET);
                output.writeShort(thing.offsetX);
                output.writeShort(thing.offsetY);
            }
            
            if (thing.hasElevation)
            {
                output.writeByte(HAS_ELEVATION);
                output.writeShort(thing.elevation);
            }
            
            if (thing.isLyingObject) output.writeByte(LYING_OBJECT);
            
            if (thing.animateAlways) output.writeByte(ANIMATE_ALWAYS);
            
            if (thing.miniMap)
            {
                output.writeByte(MINI_MAP);
                output.writeShort(thing.miniMapColor);
            }
            
            if (thing.isLensHelp)
            {
                output.writeByte(LENS_HELP);
                output.writeShort(thing.lensHelp);
            }
            
            if (thing.isFullGround) output.writeByte(FULL_GROUND);
            
            if (thing.ignoreLook) output.writeByte(IGNORE_LOOK);
            
            if (thing.cloth)
            {
                output.writeByte(CLOTH);
                output.writeShort(thing.clothSlot);
            }
            
            if (thing.isMarketItem)
            {
                output.writeByte(MARKET_ITEM);
                output.writeShort(thing.marketCategory);
                output.writeShort(thing.marketTradeAs);
                output.writeShort(thing.marketShowAs);
                output.writeShort(thing.marketName.length);
                output.writeMultiByte(thing.marketName, STRING_CHARSET);
                output.writeShort(thing.marketRestrictProfession);
                output.writeShort(thing.marketRestrictLevel);
            }
            
            if (thing.hasDefaultAction)
            {
                output.writeByte(DEFAULT_ACTION);
                output.writeShort(thing.defaultAction);
            }
            
            if (thing.hasCharges) output.writeByte(HAS_CHARGES);
            
            if (thing.floorChange) output.writeByte(FLOOR_CHANGE);
            
            if (thing.usable) output.writeByte(USABLE);
            
            output.writeByte(LAST_FLAG); // Close flags
            return true;
        }
        
        //--------------------------------------------------------------------------
        // STATIC
        //--------------------------------------------------------------------------
        
        private static const STRING_CHARSET:String  = "iso-8859-1";
        private static const GROUND:uint            = 0x00;
        private static const GROUND_BORDER:uint     = 0x01;
        private static const ON_BOTTOM:uint         = 0x02;
        private static const ON_TOP:uint            = 0x03;
        private static const CONTAINER:uint         = 0x04;
        private static const STACKABLE:uint         = 0x05;
        private static const FORCE_USE:uint         = 0x06;
        private static const MULTI_USE:uint         = 0x07;
        private static const WRITABLE:uint          = 0x08;
        private static const WRITABLE_ONCE:uint     = 0x09;
        private static const FLUID_CONTAINER:uint   = 0x0A;
        private static const FLUID:uint             = 0x0B;
        private static const UNPASSABLE:uint        = 0x0C;
        private static const UNMOVEABLE:uint        = 0x0D;
        private static const BLOCK_MISSILE:uint     = 0x0E;
        private static const BLOCK_PATHFIND:uint    = 0x0F;
        private static const NO_MOVE_ANIMATION:uint = 0x10;
        private static const PICKUPABLE:uint        = 0x11;
        private static const HANGABLE:uint          = 0x12;
        private static const HOOK_SOUTH:uint        = 0x13;
        private static const HOOK_EAST:uint         = 0x14;
        private static const ROTATABLE:uint         = 0x15;
        private static const HAS_LIGHT:uint         = 0x16;
        private static const DONT_HIDE:uint         = 0x17;
        private static const TRANSLUCENT:uint       = 0x18;
        private static const HAS_OFFSET:uint        = 0x19;
        private static const HAS_ELEVATION:uint     = 0x1A;
        private static const LYING_OBJECT:uint      = 0x1B;
        private static const ANIMATE_ALWAYS:uint    = 0x1C;
        private static const MINI_MAP:uint          = 0x1D;
        private static const LENS_HELP:uint         = 0x1E;
        private static const FULL_GROUND:uint       = 0x1F;
        private static const IGNORE_LOOK:uint       = 0x20;
        private static const CLOTH:uint             = 0x21;
        private static const MARKET_ITEM:uint       = 0x22;
        private static const DEFAULT_ACTION:uint    = 0x23;
        private static const HAS_CHARGES:uint       = 0xFC;
        private static const FLOOR_CHANGE:uint      = 0xFD;
        private static const USABLE:uint            = 0xFE;
        private static const LAST_FLAG:uint         = 0xFE;
    }
}
