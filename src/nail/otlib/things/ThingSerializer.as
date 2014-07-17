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
    import flash.utils.IDataInput;
    import flash.utils.IDataOutput;
    
    import nail.errors.AbstractClassError;
    import nail.otlib.sprites.Sprite;
    import nail.resources.Resources;
    
    public final class ThingSerializer
    {
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function ThingSerializer()
        {
            throw new AbstractClassError(ThingSerializer);
        }
        
        //--------------------------------------------------------------------------
        // STATIC
        //--------------------------------------------------------------------------
        
        private static const STRING_CHARSET:String = "iso-8859-1";
        public static const LAST_FLAG:uint = 0xFF;
        
        /**
         * Read versions 7.10 - 7.30
         */
        public static function readProperties1(thing:ThingType, input:IDataInput):Boolean
        {
            var flag:uint = 0;
            while (flag < LAST_FLAG) {
                
                var previusFlag:uint = flag;
                flag = input.readUnsignedByte();
                if (flag == LAST_FLAG) return true;
                
                switch (flag)
                {
                    case ThingTypeFlags1.GROUND:
                        thing.isGround = true;
                        thing.groundSpeed = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags1.ON_BOTTOM:
                        thing.isOnBottom = true;
                        break;
                    case ThingTypeFlags1.ON_TOP:
                        thing.isOnTop = true;
                        break;
                    case ThingTypeFlags1.CONTAINER:
                        thing.isContainer = true;
                        break;
                    case ThingTypeFlags1.STACKABLE:
                        thing.stackable = true;
                        break;
                    case ThingTypeFlags1.MULTI_USE:
                        thing.multiUse = true;
                        break;
                    case ThingTypeFlags1.FORCE_USE:
                        thing.forceUse = true;
                        break;
                    case ThingTypeFlags1.WRITABLE:
                        thing.writable = true;
                        thing.maxTextLength = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags1.WRITABLE_ONCE:
                        thing.writableOnce = true;
                        thing.maxTextLength = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags1.FLUID_CONTAINER:
                        thing.isFluidContainer = true;
                        break;
                    case ThingTypeFlags1.FLUID:
                        thing.isFluid = true;
                        break;
                    case ThingTypeFlags1.UNPASSABLE:
                        thing.isUnpassable = true;
                        break;
                    case ThingTypeFlags1.UNMOVEABLE:
                        thing.isUnmoveable = true;
                        break;
                    case ThingTypeFlags1.BLOCK_MISSILE:
                        thing.blockMissile = true;
                        break;
                    case ThingTypeFlags1.BLOCK_PATHFINDER:
                        thing.blockPathfind = true;
                        break;
                    case ThingTypeFlags1.PICKUPABLE:
                        thing.pickupable = true;
                        break;
                    case ThingTypeFlags1.HAS_LIGHT:
                        thing.hasLight = true;
                        thing.lightLevel = input.readUnsignedShort();
                        thing.lightColor = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags1.FLOOR_CHANGE:
                        thing.floorChange = true;
                        break;
                    case ThingTypeFlags1.FULL_GROUND:
                        thing.isFullGround = true;
                        break;
                    case ThingTypeFlags1.HAS_ELEVATION:
                        thing.hasElevation = true;
                        thing.elevation = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags1.HAS_OFFSET:
                        thing.hasOffset = true;
                        thing.offsetX = 8;
                        thing.offsetY = 8;
                        break;
                    case ThingTypeFlags1.MINI_MAP:
                        thing.miniMap = true;
                        thing.miniMapColor = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags1.ROTATABLE:
                        thing.rotatable = true;
                        break;
                    case ThingTypeFlags1.LYING_OBJECT:
                        thing.isLyingObject = true;
                        break;
                    case ThingTypeFlags1.ANIMATE_ALWAYS:
                        thing.animateAlways = true;
                        break;
                    case ThingTypeFlags1.LENS_HELP:
                        thing.isLensHelp = true;
                        thing.lensHelp = input.readUnsignedShort();
                        break;
                    default:
                        throw new Error(Resources.getString(
                            "strings",
                            "readUnknownFlag",
                            flag.toString(16),
                            previusFlag.toString(16),
                            Resources.getString("strings", thing.category),
                            thing.id));
                }
            }
            return true;
        }
        
        /**
         * Read versions 7.40 - 7.50
         */
        public static function readProperties2(thing:ThingType, input:IDataInput):Boolean
        {
            var flag:uint = 0;
            while (flag < LAST_FLAG) {
                
                var previusFlag:uint = flag;
                flag = input.readUnsignedByte();
                if (flag == LAST_FLAG) return true;
                
                switch (flag)
                {
                    case ThingTypeFlags2.GROUND:
                        thing.isGround = true;
                        thing.groundSpeed = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags2.ON_BOTTOM:
                        thing.isOnBottom = true;
                        break;
                    case ThingTypeFlags2.ON_TOP:
                        thing.isOnTop = true;
                        break;
                    case ThingTypeFlags2.CONTAINER:
                        thing.isContainer = true;
                        break;
                    case ThingTypeFlags2.STACKABLE:
                        thing.stackable = true;
                        break;
                    case ThingTypeFlags2.MULTI_USE:
                        thing.multiUse = true;
                        break;
                    case ThingTypeFlags2.FORCE_USE:
                        thing.forceUse = true;
                        break;
                    case ThingTypeFlags2.WRITABLE:
                        thing.writable = true;
                        thing.maxTextLength = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags2.WRITABLE_ONCE:
                        thing.writableOnce = true;
                        thing.maxTextLength = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags2.FLUID_CONTAINER:
                        thing.isFluidContainer = true;
                        break;
                    case ThingTypeFlags2.FLUID:
                        thing.isFluid = true;
                        break;
                    case ThingTypeFlags2.UNPASSABLE:
                        thing.isUnpassable = true;
                        break;
                    case ThingTypeFlags2.UNMOVEABLE:
                        thing.isUnmoveable = true;
                        break;
                    case ThingTypeFlags2.BLOCK_MISSILE:
                        thing.blockMissile = true;
                        break;
                    case ThingTypeFlags2.BLOCK_PATHFINDER:
                        thing.blockPathfind = true;
                        break;
                    case ThingTypeFlags2.PICKUPABLE:
                        thing.pickupable = true;
                        break;
                    case ThingTypeFlags2.HAS_LIGHT:
                        thing.hasLight = true;
                        thing.lightLevel = input.readUnsignedShort();
                        thing.lightColor = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags2.FLOOR_CHANGE:
                        thing.floorChange = true;
                        break;
                    case ThingTypeFlags2.FULL_GROUND:
                        thing.isFullGround = true;
                        break;
                    case ThingTypeFlags2.HAS_ELEVATION:
                        thing.hasElevation = true;
                        thing.elevation = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags2.HAS_OFFSET:
                        thing.offsetX = 8;
                        thing.offsetY = 8;
                        break;
                    case ThingTypeFlags2.MINI_MAP:
                        thing.miniMap = true;
                        thing.miniMapColor = input.readUnsignedShort(); 
                        break;
                    case ThingTypeFlags2.ROTATABLE:
                        thing.rotatable = true;
                        break;
                    case ThingTypeFlags2.LYING_OBJECT:
                        thing.isLyingObject = true;
                        break;
                    case ThingTypeFlags2.HANGABLE:
                        thing.hangable = true;
                        break;
                    case ThingTypeFlags2.VERTICAL:
                        thing.isVertical = true;
                        break;
                    case ThingTypeFlags2.HORIZONTAL:
                        thing.isHorizontal = true;
                        break;
                    case ThingTypeFlags2.ANIMATE_ALWAYS:
                        thing.animateAlways = true;
                        break;
                    case ThingTypeFlags2.LENS_HELP:
                        thing.isLensHelp = true;
                        thing.lensHelp = input.readUnsignedShort(); 
                        break;
                    default:
                        throw new Error(Resources.getString(
                            "strings",
                            "readUnknownFlag",
                            flag.toString(16),
                            previusFlag.toString(16),
                            Resources.getString("strings", thing.category),
                            thing.id));
                }
            }
            return true;
        }
        
        /**
         * Read versions 7.55 - 7.72
         */
        public static function readProperties3(thing:ThingType, input:IDataInput):Boolean
        {
            var flag:uint = 0;
            while (flag < LAST_FLAG) {
                
                var previusFlag:uint = flag;
                flag = input.readUnsignedByte();
                if (flag == LAST_FLAG) return true;
                
                switch (flag)
                {
                    case ThingTypeFlags3.GROUND:
                        thing.isGround = true;
                        thing.groundSpeed = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags3.GROUND_BORDER:
                        thing.isGroundBorder = true;
                        break;
                    case ThingTypeFlags3.ON_BOTTOM:
                        thing.isOnBottom = true;
                        break;
                    case ThingTypeFlags3.ON_TOP:
                        thing.isOnTop = true;
                        break;
                    case ThingTypeFlags3.CONTAINER:
                        thing.isContainer = true;
                        break;
                    case ThingTypeFlags3.STACKABLE:
                        thing.stackable = true;
                        break;
                    case ThingTypeFlags3.MULTI_USE:
                        thing.multiUse = true;
                        break;
                    case ThingTypeFlags3.FORCE_USE:
                        thing.forceUse = true;
                        break;
                    case ThingTypeFlags3.WRITABLE:
                        thing.writable = true;
                        thing.maxTextLength = input.readUnsignedShort(); 
                        break;
                    case ThingTypeFlags3.WRITABLE_ONCE:
                        thing.writableOnce = true;
                        thing.maxTextLength = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags3.FLUID_CONTAINER:
                        thing.isFluidContainer = true;
                        break;
                    case ThingTypeFlags3.FLUID:
                        thing.isFluid = true;
                        break;
                    case ThingTypeFlags3.UNPASSABLE:
                        thing.isUnpassable = true;
                        break;
                    case ThingTypeFlags3.UNMOVEABLE:
                        thing.isUnmoveable = true;
                        break;
                    case ThingTypeFlags3.BLOCK_MISSILE:
                        thing.blockMissile = true;
                        break;
                    case ThingTypeFlags3.BLOCK_PATHFINDER:
                        thing.blockPathfind = true;
                        break;
                    case ThingTypeFlags3.PICKUPABLE:
                        thing.pickupable = true;
                        break;
                    case ThingTypeFlags3.HANGABLE:
                        thing.hangable = true;
                        break;
                    case ThingTypeFlags3.VERTICAL:
                        thing.isVertical = true;
                        break;
                    case ThingTypeFlags3.HORIZONTAL:
                        thing.isHorizontal = true;
                        break;
                    case ThingTypeFlags3.ROTATABLE:
                        thing.rotatable = true;
                        break;
                    case ThingTypeFlags3.HAS_LIGHT:
                        thing.hasLight = true;
                        thing.lightLevel = input.readUnsignedShort();
                        thing.lightColor = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags3.FLOOR_CHANGE:
                        thing.floorChange = true;
                        break;
                    case ThingTypeFlags3.HAS_OFFSET:
                        thing.hasOffset = true;
                        thing.offsetX = input.readUnsignedShort();
                        thing.offsetY = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags3.HAS_ELEVATION:
                        thing.hasElevation = true;
                        thing.elevation = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags3.LYING_OBJECT:
                        thing.isLyingObject = true;
                        break;
                    case ThingTypeFlags3.ANIMATE_ALWAYS:
                        thing.animateAlways = true;
                        break;
                    case ThingTypeFlags3.MINI_MAP:
                        thing.miniMap = true;
                        thing.miniMapColor = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags3.LENS_HELP:
                        thing.isLensHelp = true;
                        thing.lensHelp = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags3.FULL_GROUND:
                        thing.isFullGround = true;
                        break;
                    default:
                        throw new Error(Resources.getString(
                            "strings",
                            "readUnknownFlag",
                            flag.toString(16),
                            previusFlag.toString(16),
                            Resources.getString("strings", thing.category),
                            thing.id));
                }
            }
            return true;
        }
        
        /**
         * Read versions 7.80 - 8.54
         */
        public static function readProperties4(thing:ThingType, input:IDataInput):Boolean
        {
            var flag:uint = 0;
            while (flag < LAST_FLAG) {
                
                var previusFlag:uint = flag;
                flag = input.readUnsignedByte();
                if (flag == LAST_FLAG) return true;
                
                switch (flag)
                {
                    case ThingTypeFlags4.GROUND:
                        thing.isGround = true;
                        thing.groundSpeed = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags4.GROUND_BORDER:
                        thing.isGroundBorder = true;
                        break;
                    case ThingTypeFlags4.ON_BOTTOM:
                        thing.isOnBottom = true;
                        break;
                    case ThingTypeFlags4.ON_TOP:
                        thing.isOnTop = true;
                        break;
                    case ThingTypeFlags4.CONTAINER:
                        thing.isContainer = true;
                        break;
                    case ThingTypeFlags4.STACKABLE:
                        thing.stackable = true;
                        break;
                    case ThingTypeFlags4.FORCE_USE:
                        thing.forceUse = true;
                        break;
                    case ThingTypeFlags4.MULTI_USE:
                        thing.multiUse = true;
                        break;
                    case ThingTypeFlags4.HAS_CHARGES:
                        thing.hasCharges = true;
                        break;
                    case ThingTypeFlags4.WRITABLE:
                        thing.writable = true;
                        thing.maxTextLength = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags4.WRITABLE_ONCE:
                        thing.writableOnce = true;
                        thing.maxTextLength = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags4.FLUID_CONTAINER:
                        thing.isFluidContainer = true;
                        break;
                    case ThingTypeFlags4.FLUID:
                        thing.isFluid = true;
                        break;
                    case ThingTypeFlags4.UNPASSABLE:
                        thing.isUnpassable = true;
                        break;
                    case ThingTypeFlags4.UNMOVEABLE:
                        thing.isUnmoveable = true;
                        break;
                    case ThingTypeFlags4.BLOCK_MISSILE:
                        thing.blockMissile = true;
                        break;
                    case ThingTypeFlags4.BLOCK_PATHFIND:
                        thing.blockPathfind = true;
                        break;
                    case ThingTypeFlags4.PICKUPABLE:
                        thing.pickupable = true;
                        break;
                    case ThingTypeFlags4.HANGABLE:
                        thing.hangable = true;
                        break;
                    case ThingTypeFlags4.VERTICAL:
                        thing.isVertical = true;
                        break;
                    case ThingTypeFlags4.HORIZONTAL:
                        thing.isHorizontal = true;
                        break;
                    case ThingTypeFlags4.ROTATABLE:
                        thing.rotatable = true;
                        break;
                    case ThingTypeFlags4.HAS_LIGHT:
                        thing.hasLight = true;
                        thing.lightLevel = input.readUnsignedShort();
                        thing.lightColor = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags4.DONT_HIDE:
                        thing.dontHide = true;
                        break;
                    case ThingTypeFlags4.FLOOR_CHANGE:
                        thing.floorChange = true;
                        break;
                    case ThingTypeFlags4.HAS_OFFSET:
                        thing.hasOffset = true;
                        thing.offsetX = input.readUnsignedShort();
                        thing.offsetY = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags4.HAS_ELEVATION:
                        thing.hasElevation = true;
                        thing.elevation = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags4.LYING_OBJECT:
                        thing.isLyingObject = true;
                        break;
                    case ThingTypeFlags4.ANIMATE_ALWAYS:
                        thing.animateAlways = true;
                        break;
                    case ThingTypeFlags4.MINI_MAP:
                        thing.miniMap = true;
                        thing.miniMapColor = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags4.LENS_HELP:
                        thing.isLensHelp = true;
                        thing.lensHelp = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags4.FULL_GROUND:
                        thing.isFullGround = true;
                        break;
                    case ThingTypeFlags4.IGNORE_LOOK:
                        thing.ignoreLook = true;
                        break;
                    default:
                        throw new Error(Resources.getString(
                            "strings",
                            "readUnknownFlag",
                            flag.toString(16),
                            previusFlag.toString(16),
                            Resources.getString("strings", thing.category),
                            thing.id));
                }
            }
            return true;
        }
        
        /**
         * Read versions 8.60 - 9.86
         */
        public static function readProperties5(thing:ThingType, input:IDataInput):Boolean
        {
            var flag:uint = 0;
            while (flag < LAST_FLAG) {
                
                var previusFlag:uint = flag;
                flag = input.readUnsignedByte();
                if (flag == LAST_FLAG) return true;
                
                switch (flag)
                {
                    case ThingTypeFlags5.GROUND:
                        thing.isGround = true;
                        thing.groundSpeed = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags5.GROUND_BORDER:
                        thing.isGroundBorder = true;
                        break;
                    case ThingTypeFlags5.ON_BOTTOM:
                        thing.isOnBottom = true;
                        break;
                    case ThingTypeFlags5.ON_TOP:
                        thing.isOnTop = true;
                        break;
                    case ThingTypeFlags5.CONTAINER:
                        thing.isContainer = true;
                        break;
                    case ThingTypeFlags5.STACKABLE:
                        thing.stackable = true;
                        break;
                    case ThingTypeFlags5.FORCE_USE:
                        thing.forceUse = true;
                        break;
                    case ThingTypeFlags5.MULTI_USE:
                        thing.multiUse = true;
                        break;
                    case ThingTypeFlags5.WRITABLE:
                        thing.writable = true;
                        thing.maxTextLength = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags5.WRITABLE_ONCE:
                        thing.writableOnce = true;
                        thing.maxTextLength = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags5.FLUID_CONTAINER:
                        thing.isFluidContainer = true;
                        break;
                    case ThingTypeFlags5.FLUID:
                        thing.isFluid = true;
                        break;
                    case ThingTypeFlags5.UNPASSABLE:
                        thing.isUnpassable = true;
                        break;
                    case ThingTypeFlags5.UNMOVEABLE:
                        thing.isUnmoveable = true;
                        break;
                    case ThingTypeFlags5.BLOCK_MISSILE:
                        thing.blockMissile = true;
                        break;
                    case ThingTypeFlags5.BLOCK_PATHFIND:
                        thing.blockPathfind = true;
                        break;
                    case ThingTypeFlags5.PICKUPABLE:
                        thing.pickupable = true;
                        break;
                    case ThingTypeFlags5.HANGABLE:
                        thing.hangable = true;
                        break;
                    case ThingTypeFlags5.VERTICAL:
                        thing.isVertical = true;
                        break;
                    case ThingTypeFlags5.HORIZONTAL:
                        thing.isHorizontal = true;
                        break;
                    case ThingTypeFlags5.ROTATABLE:
                        thing.rotatable = true;
                        break;
                    case ThingTypeFlags5.HAS_LIGHT:
                        thing.hasLight = true;
                        thing.lightLevel = input.readUnsignedShort();
                        thing.lightColor = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags5.DONT_HIDE:
                        thing.dontHide = true;
                        break;
                    case ThingTypeFlags5.TRANSLUCENT:
                        thing.isTranslucent = true;
                        break;
                    case ThingTypeFlags5.HAS_OFFSET:
                        thing.hasOffset = true;
                        thing.offsetX = input.readUnsignedShort();
                        thing.offsetY = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags5.HAS_ELEVATION:
                        thing.hasElevation = true;
                        thing.elevation = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags5.LYING_OBJECT:
                        thing.isLyingObject = true;
                        break;
                    case ThingTypeFlags5.ANIMATE_ALWAYS:
                        thing.animateAlways = true;
                        break;
                    case ThingTypeFlags5.MINI_MAP:
                        thing.miniMap = true;
                        thing.miniMapColor = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags5.LENS_HELP:
                        thing.isLensHelp = true;
                        thing.lensHelp = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags5.FULL_GROUND:
                        thing.isFullGround = true;
                        break;
                    case ThingTypeFlags5.IGNORE_LOOK:
                        thing.ignoreLook = true;
                        break;
                    case ThingTypeFlags5.CLOTH:
                        thing.cloth = true;
                        thing.clothSlot = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags5.MARKET_ITEM:
                        thing.isMarketItem = true;
                        thing.marketCategory = input.readUnsignedShort();
                        thing.marketTradeAs = input.readUnsignedShort();
                        thing.marketShowAs = input.readUnsignedShort();
                        var nameLength:uint = input.readUnsignedShort();
                        thing.marketName = input.readMultiByte(nameLength, STRING_CHARSET);
                        thing.marketRestrictProfession = input.readUnsignedShort();
                        thing.marketRestrictLevel = input.readUnsignedShort();
                        break;
                    default:
                        throw new Error(Resources.getString(
                            "strings",
                            "readUnknownFlag",
                            flag.toString(16),
                            previusFlag.toString(16),
                            Resources.getString("strings", thing.category),
                            thing.id));
                }
            }
            return true;
        }
        
        /**
         * Read versions 10.10+
         */
        public static function readProperties6(thing:ThingType, input:IDataInput):Boolean
        {
            var flag:uint = 0;
            while (flag < LAST_FLAG) {
                
                var previusFlag:uint = flag;
                flag = input.readUnsignedByte();
                if (flag == LAST_FLAG) return true;
                
                switch (flag)
                {
                    case ThingTypeFlags6.GROUND:
                        thing.isGround = true;
                        thing.groundSpeed = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags6.GROUND_BORDER:
                        thing.isGroundBorder = true;
                        break;
                    case ThingTypeFlags6.ON_BOTTOM:
                        thing.isOnBottom = true;
                        break;
                    case ThingTypeFlags6.ON_TOP:
                        thing.isOnTop = true;
                        break;
                    case ThingTypeFlags6.CONTAINER:
                        thing.isContainer = true;
                        break;
                    case ThingTypeFlags6.STACKABLE:
                        thing.stackable = true;
                        break;
                    case ThingTypeFlags6.FORCE_USE:
                        thing.forceUse = true;
                        break;
                    case ThingTypeFlags6.MULTI_USE:
                        thing.multiUse = true;
                        break;
                    case ThingTypeFlags6.WRITABLE:
                        thing.writable = true;
                        thing.maxTextLength = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags6.WRITABLE_ONCE:
                        thing.writableOnce = true;
                        thing.maxTextLength = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags6.FLUID_CONTAINER:
                        thing.isFluidContainer = true;
                        break;
                    case ThingTypeFlags6.FLUID:
                        thing.isFluid = true;
                        break;
                    case ThingTypeFlags6.UNPASSABLE:
                        thing.isUnpassable = true;
                        break;
                    case ThingTypeFlags6.UNMOVEABLE:
                        thing.isUnmoveable = true;
                        break;
                    case ThingTypeFlags6.BLOCK_MISSILE:
                        thing.blockMissile = true;
                        break;
                    case ThingTypeFlags6.BLOCK_PATHFIND:
                        thing.blockPathfind = true;
                        break;
                    case ThingTypeFlags6.NO_MOVE_ANIMATION:
                        thing.noMoveAnimation = true;
                        break;
                    case ThingTypeFlags6.PICKUPABLE:
                        thing.pickupable = true;
                        break;
                    case ThingTypeFlags6.HANGABLE:
                        thing.hangable = true;
                        break;
                    case ThingTypeFlags6.VERTICAL:
                        thing.isVertical = true;
                        break;
                    case ThingTypeFlags6.HORIZONTAL:
                        thing.isHorizontal = true;
                        break;
                    case ThingTypeFlags6.ROTATABLE:
                        thing.rotatable = true;
                        break;
                    case ThingTypeFlags6.HAS_LIGHT:
                        thing.hasLight = true;
                        thing.lightLevel = input.readUnsignedShort();
                        thing.lightColor = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags6.DONT_HIDE:
                        thing.dontHide = true;
                        break;
                    case ThingTypeFlags6.TRANSLUCENT:
                        thing.isTranslucent = true;
                        break;
                    case ThingTypeFlags6.HAS_OFFSET:
                        thing.hasOffset = true;
                        thing.offsetX = input.readUnsignedShort();
                        thing.offsetY = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags6.HAS_ELEVATION:
                        thing.hasElevation = true;
                        thing.elevation    = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags6.LYING_OBJECT:
                        thing.isLyingObject = true;
                        break;
                    case ThingTypeFlags6.ANIMATE_ALWAYS:
                        thing.animateAlways = true;
                        break;
                    case ThingTypeFlags6.MINI_MAP:
                        thing.miniMap = true;
                        thing.miniMapColor = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags6.LENS_HELP:
                        thing.isLensHelp = true;
                        thing.lensHelp = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags6.FULL_GROUND:
                        thing.isFullGround = true;
                        break;
                    case ThingTypeFlags6.IGNORE_LOOK:
                        thing.ignoreLook = true;
                        break;
                    case ThingTypeFlags6.CLOTH:
                        thing.cloth = true;
                        thing.clothSlot = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags6.MARKET_ITEM:
                        thing.isMarketItem = true;
                        thing.marketCategory = input.readUnsignedShort();
                        thing.marketTradeAs = input.readUnsignedShort();
                        thing.marketShowAs = input.readUnsignedShort();
                        var nameLength:uint = input.readUnsignedShort();
                        thing.marketName = input.readMultiByte(nameLength, STRING_CHARSET);
                        thing.marketRestrictProfession = input.readUnsignedShort();
                        thing.marketRestrictLevel = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags6.DEFAULT_ACTION:
                        thing.hasDefaultAction = true;
                        thing.defaultAction = input.readUnsignedShort();
                        break;
                    case ThingTypeFlags6.USABLE:
                        thing.usable = true;
                        break;
                    default:
                        throw new Error(Resources.getString(
                            "strings",
                            "readUnknownFlag",
                            flag.toString(16),
                            previusFlag.toString(16),
                            Resources.getString("strings", thing.category),
                            thing.id));
                }
            }
            return true;
        }
        
        /**
         * Read sprites.
         */
        public static function readSprites(thing:ThingType, input:IDataInput, extended:Boolean, readPatternZ:Boolean):Boolean
        {
            thing.width = input.readUnsignedByte();
            thing.height = input.readUnsignedByte();
            
            if (thing.width > 1 || thing.height > 1)
                thing.exactSize = input.readUnsignedByte();
            else 
                thing.exactSize = Sprite.SPRITE_PIXELS;
            
            thing.layers = input.readUnsignedByte();
            thing.patternX = input.readUnsignedByte();
            thing.patternY = input.readUnsignedByte();
            thing.patternZ = readPatternZ ? input.readUnsignedByte() : 1;
            thing.frames = input.readUnsignedByte();
            if (thing.frames > 1) {
                thing.isAnimation = true;
            }
            
            var totalSprites:uint = thing.width * thing.height * thing.layers * thing.patternX * thing.patternY * thing.patternZ * thing.frames;
            if (totalSprites > 4096) {
                throw new Error("A thing type has more than 4096 sprites.");
            }
            
            thing.spriteIndex = new Vector.<uint>(totalSprites);
            for (var i:uint = 0; i < totalSprites; i++) {
                if (extended)
                    thing.spriteIndex[i] = input.readUnsignedInt();
                else 
                    thing.spriteIndex[i] = input.readUnsignedShort();
            }
            return true;
        }
        
        /**
         * Write versions 7.10 - 7.30
         */
        public static function writeProperties1(thing:ThingType, output:IDataOutput):Boolean
        {
            if (thing.isGround) {
                output.writeByte(ThingTypeFlags1.GROUND);
                output.writeShort(thing.groundSpeed);
            } else if (thing.isOnBottom) {
                output.writeByte(ThingTypeFlags1.ON_BOTTOM);
            } else if (thing.isOnTop) {
                output.writeByte(ThingTypeFlags1.ON_TOP);
            }
            
            if (thing.isContainer) output.writeByte(ThingTypeFlags1.CONTAINER);
            if (thing.stackable) output.writeByte(ThingTypeFlags1.STACKABLE);
            if (thing.multiUse) output.writeByte(ThingTypeFlags1.MULTI_USE);
            if (thing.forceUse) output.writeByte(ThingTypeFlags1.FORCE_USE);
            if (thing.writable) {
                output.writeByte(ThingTypeFlags1.WRITABLE);
                output.writeShort(thing.maxTextLength);
            }
            if (thing.writableOnce) {
                output.writeByte(ThingTypeFlags1.WRITABLE_ONCE);
                output.writeShort(thing.maxTextLength);
            }
            if (thing.isFluidContainer) output.writeByte(ThingTypeFlags1.FLUID_CONTAINER);
            if (thing.isFluid) output.writeByte(ThingTypeFlags1.FLUID);
            if (thing.isUnpassable) output.writeByte(ThingTypeFlags1.UNPASSABLE);
            if (thing.isUnmoveable) output.writeByte(ThingTypeFlags1.UNMOVEABLE);
            if (thing.blockMissile) output.writeByte(ThingTypeFlags1.BLOCK_MISSILE);
            if (thing.blockPathfind) output.writeByte(ThingTypeFlags1.BLOCK_PATHFINDER);
            if (thing.pickupable) output.writeByte(ThingTypeFlags1.PICKUPABLE);
            if (thing.hasLight) {
                output.writeByte(ThingTypeFlags1.HAS_LIGHT);
                output.writeShort(thing.lightLevel);
                output.writeShort(thing.lightColor);
            }
            if (thing.floorChange) output.writeByte(ThingTypeFlags1.FLOOR_CHANGE);
            if (thing.isFullGround) output.writeByte(ThingTypeFlags1.FULL_GROUND);
            if (thing.hasElevation) {
                output.writeByte(ThingTypeFlags1.HAS_ELEVATION);
                output.writeShort(thing.elevation);
            }
            if (thing.hasOffset) {
                output.writeByte(ThingTypeFlags1.HAS_OFFSET);
            }
            if (thing.miniMap) {
                output.writeByte(ThingTypeFlags1.MINI_MAP);
                output.writeShort(thing.miniMapColor);
            }
            if (thing.rotatable) output.writeByte(ThingTypeFlags1.ROTATABLE);
            if (thing.isLyingObject) output.writeByte(ThingTypeFlags1.LYING_OBJECT);
            if (thing.animateAlways) output.writeByte(ThingTypeFlags1.ANIMATE_ALWAYS);
            if (thing.isLensHelp) {
                output.writeByte(ThingTypeFlags1.LENS_HELP);
                output.writeShort(thing.lensHelp);
            }
            output.writeByte(LAST_FLAG); // Close flags
            return true;
        }
        
        /**
         * Write versions 7.40 - 7.50
         */
        public static function writeProperties2(thing:ThingType, output:IDataOutput):Boolean
        {
            if (thing.isGround) {
                output.writeByte(ThingTypeFlags2.GROUND);
                output.writeShort(thing.groundSpeed);
            } else if (thing.isOnBottom) {
                output.writeByte(ThingTypeFlags2.ON_BOTTOM);
            } else if (thing.isOnTop) {
                output.writeByte(ThingTypeFlags2.ON_TOP);
            }
            
            if (thing.isContainer) output.writeByte(ThingTypeFlags2.CONTAINER);
            if (thing.stackable) output.writeByte(ThingTypeFlags2.STACKABLE);
            if (thing.multiUse) output.writeByte(ThingTypeFlags2.MULTI_USE);
            if (thing.forceUse) output.writeByte(ThingTypeFlags2.FORCE_USE);
            if (thing.writable) {
                output.writeByte(ThingTypeFlags2.WRITABLE);
                output.writeShort(thing.maxTextLength);
            }
            if (thing.writableOnce) {
                output.writeByte(ThingTypeFlags2.WRITABLE_ONCE);
                output.writeShort(thing.maxTextLength);
            }
            if (thing.isFluidContainer) output.writeByte(ThingTypeFlags2.FLUID_CONTAINER);
            if (thing.isFluid) output.writeByte(ThingTypeFlags2.FLUID);
            if (thing.isUnpassable) output.writeByte(ThingTypeFlags2.UNPASSABLE);
            if (thing.isUnmoveable) output.writeByte(ThingTypeFlags2.UNMOVEABLE);
            if (thing.blockMissile) output.writeByte(ThingTypeFlags2.BLOCK_MISSILE);
            if (thing.blockPathfind) output.writeByte(ThingTypeFlags2.BLOCK_PATHFINDER);
            if (thing.pickupable) output.writeByte(ThingTypeFlags2.PICKUPABLE);
            if (thing.hasLight) {
                output.writeByte(ThingTypeFlags2.HAS_LIGHT);
                output.writeShort(thing.lightLevel);
                output.writeShort(thing.lightColor);
            }
            if (thing.floorChange) output.writeByte(ThingTypeFlags2.FLOOR_CHANGE);
            if (thing.isFullGround) output.writeByte(ThingTypeFlags2.FULL_GROUND);
            if (thing.hasElevation) {
                output.writeByte(ThingTypeFlags2.HAS_ELEVATION);
                output.writeShort(thing.elevation);
            }
            if (thing.hasOffset) {
                output.writeByte(ThingTypeFlags2.HAS_OFFSET);
            }
            if (thing.miniMap) {
                output.writeByte(ThingTypeFlags2.MINI_MAP);
                output.writeShort(thing.miniMapColor);
            }
            if (thing.rotatable) output.writeByte(ThingTypeFlags2.ROTATABLE);
            if (thing.isLyingObject) output.writeByte(ThingTypeFlags2.LYING_OBJECT);
            if (thing.hangable) output.writeByte(ThingTypeFlags2.HANGABLE);
            if (thing.isVertical) output.writeByte(ThingTypeFlags2.VERTICAL);
            if (thing.isHorizontal) output.writeByte(ThingTypeFlags2.HORIZONTAL);
            if (thing.animateAlways) output.writeByte(ThingTypeFlags2.ANIMATE_ALWAYS);
            if (thing.isLensHelp) {
                output.writeByte(ThingTypeFlags2.LENS_HELP);
                output.writeShort(thing.lensHelp);
            }
            output.writeByte(LAST_FLAG); // Close flags
            return true;
        }
        
        /**
         * Write versions 7.55 - 7.72
         */
        public static function writeProperties3(thing:ThingType, output:IDataOutput):Boolean
        {
            if (thing.isGround) {
                output.writeByte(ThingTypeFlags3.GROUND);
                output.writeShort(thing.groundSpeed);
            } else if (thing.isGroundBorder) { 
                output.writeByte(ThingTypeFlags3.GROUND_BORDER);
            } else if (thing.isOnBottom) {
                output.writeByte(ThingTypeFlags3.ON_BOTTOM);
            } else if (thing.isOnTop) {
                output.writeByte(ThingTypeFlags3.ON_TOP);
            }
            
            if (thing.isContainer) output.writeByte(ThingTypeFlags3.CONTAINER);
            if (thing.stackable) output.writeByte(ThingTypeFlags3.STACKABLE);
            if (thing.multiUse) output.writeByte(ThingTypeFlags3.MULTI_USE);
            if (thing.forceUse) output.writeByte(ThingTypeFlags3.FORCE_USE);
            if (thing.writable) {
                output.writeByte(ThingTypeFlags3.WRITABLE);
                output.writeShort(thing.maxTextLength);
            }
            if (thing.writableOnce) {
                output.writeByte(ThingTypeFlags3.WRITABLE_ONCE);
                output.writeShort(thing.maxTextLength);
            }
            if (thing.isFluidContainer) output.writeByte(ThingTypeFlags3.FLUID_CONTAINER);
            if (thing.isFluid) output.writeByte(ThingTypeFlags3.FLUID);
            if (thing.isUnpassable) output.writeByte(ThingTypeFlags3.UNPASSABLE);
            if (thing.isUnmoveable) output.writeByte(ThingTypeFlags3.UNMOVEABLE);
            if (thing.blockMissile) output.writeByte(ThingTypeFlags3.BLOCK_MISSILE);
            if (thing.blockPathfind) output.writeByte(ThingTypeFlags3.BLOCK_PATHFINDER);
            if (thing.pickupable) output.writeByte(ThingTypeFlags3.PICKUPABLE);
            if (thing.hangable) output.writeByte(ThingTypeFlags3.HANGABLE);
            if (thing.isVertical) output.writeByte(ThingTypeFlags3.VERTICAL);
            if (thing.isHorizontal) output.writeByte(ThingTypeFlags3.HORIZONTAL);
            if (thing.rotatable) output.writeByte(ThingTypeFlags3.ROTATABLE);
            if (thing.hasLight) {
                output.writeByte(ThingTypeFlags3.HAS_LIGHT);
                output.writeShort(thing.lightLevel);
                output.writeShort(thing.lightColor);
            }
            if (thing.floorChange) output.writeByte(ThingTypeFlags3.FLOOR_CHANGE);
            if (thing.hasOffset) {
                output.writeByte(ThingTypeFlags3.HAS_OFFSET);
                output.writeShort(thing.offsetX);
                output.writeShort(thing.offsetY);
            }
            if (thing.hasElevation) {
                output.writeByte(ThingTypeFlags3.HAS_ELEVATION);
                output.writeShort(thing.elevation);
            }
            if (thing.isLyingObject) output.writeByte(ThingTypeFlags3.LYING_OBJECT);
            if (thing.animateAlways) output.writeByte(ThingTypeFlags3.ANIMATE_ALWAYS);
            if (thing.miniMap) {
                output.writeByte(ThingTypeFlags3.MINI_MAP);
                output.writeShort(thing.miniMapColor);
            }
            if (thing.isLensHelp) {
                output.writeByte(ThingTypeFlags3.LENS_HELP);
                output.writeShort(thing.lensHelp);
            }
            if (thing.isFullGround) output.writeByte(ThingTypeFlags3.FULL_GROUND);
            output.writeByte(LAST_FLAG); // Close flags
            return true;
        }
        
        /**
         * Write versions 7.80 - 8.54
         */
        public static function writeProperties4(thing:ThingType, output:IDataOutput):Boolean
        {
            if (thing.isGround) {
                output.writeByte(ThingTypeFlags4.GROUND);
                output.writeShort(thing.groundSpeed);
            } else if (thing.isGroundBorder) { 
                output.writeByte(ThingTypeFlags4.GROUND_BORDER);
            } else if (thing.isOnBottom) {
                output.writeByte(ThingTypeFlags4.ON_BOTTOM);
            } else if (thing.isOnTop) {
                output.writeByte(ThingTypeFlags4.ON_TOP);
            }
            
            if (thing.isContainer) output.writeByte(ThingTypeFlags4.CONTAINER);
            if (thing.stackable) output.writeByte(ThingTypeFlags4.STACKABLE);
            if (thing.forceUse) output.writeByte(ThingTypeFlags4.FORCE_USE);
            if (thing.multiUse) output.writeByte(ThingTypeFlags4.MULTI_USE);
            if (thing.hasCharges) output.writeByte(ThingTypeFlags4.HAS_CHARGES);
            if (thing.writable) {
                output.writeByte(ThingTypeFlags4.WRITABLE);
                output.writeShort(thing.maxTextLength);
            }
            if (thing.writableOnce) {
                output.writeByte(ThingTypeFlags4.WRITABLE_ONCE);
                output.writeShort(thing.maxTextLength);
            }
            if (thing.isFluidContainer) output.writeByte(ThingTypeFlags4.FLUID_CONTAINER);
            if (thing.isFluid) output.writeByte(ThingTypeFlags4.FLUID);
            if (thing.isUnpassable) output.writeByte(ThingTypeFlags4.UNPASSABLE);
            if (thing.isUnmoveable) output.writeByte(ThingTypeFlags4.UNMOVEABLE);
            if (thing.blockMissile) output.writeByte(ThingTypeFlags4.BLOCK_MISSILE);
            if (thing.blockPathfind) output.writeByte(ThingTypeFlags4.BLOCK_PATHFIND);
            if (thing.pickupable) output.writeByte(ThingTypeFlags4.PICKUPABLE);
            if (thing.hangable) output.writeByte(ThingTypeFlags4.HANGABLE);
            if (thing.isVertical) output.writeByte(ThingTypeFlags4.VERTICAL);
            if (thing.isHorizontal) output.writeByte(ThingTypeFlags4.HORIZONTAL);
            if (thing.rotatable) output.writeByte(ThingTypeFlags4.ROTATABLE);
            if (thing.hasLight) {
                output.writeByte(ThingTypeFlags4.HAS_LIGHT);
                output.writeShort(thing.lightLevel);
                output.writeShort(thing.lightColor);
            }
            if (thing.dontHide) output.writeByte(ThingTypeFlags4.DONT_HIDE);
            if (thing.floorChange) output.writeByte(ThingTypeFlags4.FLOOR_CHANGE);
            if (thing.hasOffset) {
                output.writeByte(ThingTypeFlags4.HAS_OFFSET);
                output.writeShort(thing.offsetX);
                output.writeShort(thing.offsetY);
            }
            if (thing.hasElevation) {
                output.writeByte(ThingTypeFlags4.HAS_ELEVATION);
                output.writeShort(thing.elevation);
            }
            if (thing.isLyingObject) output.writeByte(ThingTypeFlags4.LYING_OBJECT);
            if (thing.animateAlways) output.writeByte(ThingTypeFlags4.ANIMATE_ALWAYS);
            if (thing.miniMap) {
                output.writeByte(ThingTypeFlags4.MINI_MAP);
                output.writeShort(thing.miniMapColor);
            }
            if (thing.isLensHelp) {
                output.writeByte(ThingTypeFlags4.LENS_HELP);
                output.writeShort(thing.lensHelp);
            }
            if (thing.isFullGround) output.writeByte(ThingTypeFlags4.FULL_GROUND);
            if (thing.ignoreLook) output.writeByte(ThingTypeFlags4.IGNORE_LOOK);
            output.writeByte(LAST_FLAG); // Close flags
            return true;
        }
        
        /**
         * Write versions 8.60 - 9.86
         */
        public static function writeProperties5(thing:ThingType, output:IDataOutput):Boolean
        {
            if (thing.isGround) {
                output.writeByte(ThingTypeFlags5.GROUND);
                output.writeShort(thing.groundSpeed);
            } else if (thing.isGroundBorder) { 
                output.writeByte(ThingTypeFlags5.GROUND_BORDER);
            } else if (thing.isOnBottom) {
                output.writeByte(ThingTypeFlags5.ON_BOTTOM);
            } else if (thing.isOnTop) {
                output.writeByte(ThingTypeFlags5.ON_TOP);
            }
            
            if (thing.isContainer) output.writeByte(ThingTypeFlags5.CONTAINER);
            if (thing.stackable) output.writeByte(ThingTypeFlags5.STACKABLE);
            if (thing.forceUse) output.writeByte(ThingTypeFlags5.FORCE_USE);
            if (thing.multiUse) output.writeByte(ThingTypeFlags5.MULTI_USE);
            if (thing.writable) {
                output.writeByte(ThingTypeFlags5.WRITABLE);
                output.writeShort(thing.maxTextLength);
            }
            if (thing.writableOnce) {
                output.writeByte(ThingTypeFlags5.WRITABLE_ONCE);
                output.writeShort(thing.maxTextLength);
            }
            if (thing.isFluidContainer) output.writeByte(ThingTypeFlags5.FLUID_CONTAINER);
            if (thing.isFluid) output.writeByte(ThingTypeFlags5.FLUID);
            if (thing.isUnpassable) output.writeByte(ThingTypeFlags5.UNPASSABLE);
            if (thing.isUnmoveable) output.writeByte(ThingTypeFlags5.UNMOVEABLE);
            if (thing.blockMissile) output.writeByte(ThingTypeFlags5.BLOCK_MISSILE);
            if (thing.blockPathfind) output.writeByte(ThingTypeFlags5.BLOCK_PATHFIND);
            if (thing.pickupable) output.writeByte(ThingTypeFlags5.PICKUPABLE);
            if (thing.hangable) output.writeByte(ThingTypeFlags5.HANGABLE);
            if (thing.isVertical) output.writeByte(ThingTypeFlags5.VERTICAL);
            if (thing.isHorizontal) output.writeByte(ThingTypeFlags5.HORIZONTAL);
            if (thing.rotatable) output.writeByte(ThingTypeFlags5.ROTATABLE);
            if (thing.hasLight) {
                output.writeByte(ThingTypeFlags5.HAS_LIGHT);
                output.writeShort(thing.lightLevel);
                output.writeShort(thing.lightColor);
            }
            if (thing.dontHide) output.writeByte(ThingTypeFlags5.DONT_HIDE);
            if (thing.isTranslucent) output.writeByte(ThingTypeFlags5.TRANSLUCENT);
            if (thing.hasOffset) {
                output.writeByte(ThingTypeFlags5.HAS_OFFSET);
                output.writeShort(thing.offsetX);
                output.writeShort(thing.offsetY);
            }
            if (thing.hasElevation) {
                output.writeByte(ThingTypeFlags5.HAS_ELEVATION);
                output.writeShort(thing.elevation);
            }
            if (thing.isLyingObject) output.writeByte(ThingTypeFlags5.LYING_OBJECT);
            if (thing.animateAlways) output.writeByte(ThingTypeFlags5.ANIMATE_ALWAYS);
            if (thing.miniMap) {
                output.writeByte(ThingTypeFlags5.MINI_MAP);
                output.writeShort(thing.miniMapColor);
            }
            if (thing.isLensHelp) {
                output.writeByte(ThingTypeFlags5.LENS_HELP);
                output.writeShort(thing.lensHelp);
            }
            if (thing.isFullGround) output.writeByte(ThingTypeFlags5.FULL_GROUND);
            if (thing.ignoreLook) output.writeByte(ThingTypeFlags5.IGNORE_LOOK);
            if (thing.cloth) {
                output.writeByte(ThingTypeFlags5.CLOTH);
                output.writeShort(thing.clothSlot);
            }
            if (thing.isMarketItem) {
                output.writeByte(ThingTypeFlags5.MARKET_ITEM);
                output.writeShort(thing.marketCategory);
                output.writeShort(thing.marketTradeAs);
                output.writeShort(thing.marketShowAs);
                output.writeShort(thing.marketName.length);
                output.writeMultiByte(thing.marketName, STRING_CHARSET);
                output.writeShort(thing.marketRestrictProfession);
                output.writeShort(thing.marketRestrictLevel);
            }
            output.writeByte(LAST_FLAG); // Close flags
            return true;
        }
        
        /**
         * Write versions 10.10+
         */
        public static function writeProperties6(thing:ThingType, output:IDataOutput):Boolean
        {
            if (thing.isGround) {
                output.writeByte(ThingTypeFlags6.GROUND);
                output.writeShort(thing.groundSpeed);
            } else if (thing.isGroundBorder) { 
                output.writeByte(ThingTypeFlags6.GROUND_BORDER);
            } else if (thing.isOnBottom) {
                output.writeByte(ThingTypeFlags6.ON_BOTTOM);
            } else if (thing.isOnTop) {
                output.writeByte(ThingTypeFlags6.ON_TOP);
            }
            
            if (thing.isContainer) output.writeByte(ThingTypeFlags6.CONTAINER);
            if (thing.stackable) output.writeByte(ThingTypeFlags6.STACKABLE);
            if (thing.forceUse) output.writeByte(ThingTypeFlags6.FORCE_USE);
            if (thing.multiUse) output.writeByte(ThingTypeFlags6.MULTI_USE);
            if (thing.writable) {
                output.writeByte(ThingTypeFlags6.WRITABLE);
                output.writeShort(thing.maxTextLength);
            }
            if (thing.writableOnce) {
                output.writeByte(ThingTypeFlags6.WRITABLE_ONCE);
                output.writeShort(thing.maxTextLength);
            }
            if (thing.isFluidContainer) output.writeByte(ThingTypeFlags6.FLUID_CONTAINER);
            if (thing.isFluid) output.writeByte(ThingTypeFlags6.FLUID);
            if (thing.isUnpassable) output.writeByte(ThingTypeFlags6.UNPASSABLE);
            if (thing.isUnmoveable) output.writeByte(ThingTypeFlags6.UNMOVEABLE);
            if (thing.blockMissile) output.writeByte(ThingTypeFlags6.BLOCK_MISSILE);
            if (thing.blockPathfind) output.writeByte(ThingTypeFlags6.BLOCK_PATHFIND);
            if (thing.noMoveAnimation) output.writeByte(ThingTypeFlags6.NO_MOVE_ANIMATION);
            if (thing.pickupable) output.writeByte(ThingTypeFlags6.PICKUPABLE);
            if (thing.hangable) output.writeByte(ThingTypeFlags6.HANGABLE);
            if (thing.isVertical) output.writeByte(ThingTypeFlags6.VERTICAL);
            if (thing.isHorizontal) output.writeByte(ThingTypeFlags6.HORIZONTAL);
            if (thing.rotatable) output.writeByte(ThingTypeFlags6.ROTATABLE);
            if (thing.hasLight) {
                output.writeByte(ThingTypeFlags6.HAS_LIGHT);
                output.writeShort(thing.lightLevel);
                output.writeShort(thing.lightColor);
            }
            if (thing.dontHide) output.writeByte(ThingTypeFlags6.DONT_HIDE);
            if (thing.isTranslucent) output.writeByte(ThingTypeFlags6.TRANSLUCENT);
            if (thing.hasOffset) {
                output.writeByte(ThingTypeFlags6.HAS_OFFSET);
                output.writeShort(thing.offsetX);
                output.writeShort(thing.offsetY);
            }
            if (thing.hasElevation) {
                output.writeByte(ThingTypeFlags6.HAS_ELEVATION);
                output.writeShort(thing.elevation);
            }
            if (thing.isLyingObject) output.writeByte(ThingTypeFlags6.LYING_OBJECT);
            if (thing.animateAlways) output.writeByte(ThingTypeFlags6.ANIMATE_ALWAYS);
            if (thing.miniMap) {
                output.writeByte(ThingTypeFlags6.MINI_MAP);
                output.writeShort(thing.miniMapColor);
            }
            if (thing.isLensHelp) {
                output.writeByte(ThingTypeFlags6.LENS_HELP);
                output.writeShort(thing.lensHelp);
            }
            if (thing.isFullGround) output.writeByte(ThingTypeFlags6.FULL_GROUND);
            if (thing.ignoreLook) output.writeByte(ThingTypeFlags6.IGNORE_LOOK);
            if (thing.cloth) {
                output.writeByte(ThingTypeFlags6.CLOTH);
                output.writeShort(thing.clothSlot);
            }
            if (thing.isMarketItem) {
                output.writeByte(ThingTypeFlags6.MARKET_ITEM);
                output.writeShort(thing.marketCategory);
                output.writeShort(thing.marketTradeAs);
                output.writeShort(thing.marketShowAs);
                output.writeShort(thing.marketName.length);
                output.writeMultiByte(thing.marketName, STRING_CHARSET);
                output.writeShort(thing.marketRestrictProfession);
                output.writeShort(thing.marketRestrictLevel);
            }
            if (thing.hasDefaultAction) {
                output.writeByte(ThingTypeFlags6.DEFAULT_ACTION);
                output.writeShort(thing.defaultAction); 
            }
            if (thing.usable) {
                output.writeByte(ThingTypeFlags6.USABLE);
            }
            output.writeByte(LAST_FLAG); // Close flags
            return true;
        }
        
        /**
         * Write sprites.
         */
        public static function writeSprites(thing:ThingType, output:IDataOutput, extended:Boolean, writePatternZ:Boolean):Boolean
        {
            output.writeByte(thing.width);  // Write width	
            output.writeByte(thing.height); // Write height	
            
            if (thing.width > 1 || thing.height > 1) {
                output.writeByte(thing.exactSize); // Write exact size
            }
            
            output.writeByte(thing.layers);   // Write layers
            output.writeByte(thing.patternX); // Write pattern X
            output.writeByte(thing.patternY); // Write pattern Y
            if (writePatternZ) output.writeByte(thing.patternZ); // Write pattern Z
            output.writeByte(thing.frames);   // Write frames
            
            var spriteIndex:Vector.<uint> = thing.spriteIndex;
            var length:uint = spriteIndex.length;
            for (var i:uint = 0; i < length; i++) {
                // Write sprite index
                if (extended)
                    output.writeUnsignedInt(spriteIndex[i]); 
                else
                    output.writeShort(spriteIndex[i]);
            }
            return true;
        }
    }
}
