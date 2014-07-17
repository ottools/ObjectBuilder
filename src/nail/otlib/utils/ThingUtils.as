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

package nail.otlib.utils
{
    import flash.utils.describeType;
    
    import nail.errors.AbstractClassError;
    import nail.otlib.things.ThingCategory;
    import nail.otlib.things.ThingType;
    import nail.resources.Resources;
    
    public final class ThingUtils
    {
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function ThingUtils()
        {
            throw new AbstractClassError(ThingUtils);
        }
        
        //--------------------------------------------------------------------------
        // STATIC
        //--------------------------------------------------------------------------
        
        public static function copyThing(thing:ThingType):ThingType
        {
            if (!thing) return null;
            
            var newThing:ThingType = new ThingType();
            var description:XMLList = describeType(thing)..variable;
            for each (var property:XML in description) {
                var name:String = property.@name;
                newThing[name] = thing[name];
            }
            
            if (thing.spriteIndex) {
                newThing.spriteIndex = thing.spriteIndex.concat();
            }
            return newThing;
        }
        
        public static function createThing(category:String, id:uint = 0):ThingType
        {
            if (!ThingCategory.getCategory(category)) {
                throw new Error(Resources.getString("strings", "invalidCategory"));
            }
            
            var thing:ThingType = new ThingType();
            thing.category = category;
            thing.id = id;
            thing.width = 1;
            thing.height = 1;
            thing.layers = 1;
            thing.frames = 1;
            thing.patternX = 1;
            thing.patternY = 1;
            thing.patternZ = 1;
            thing.exactSize = 32;
            
            switch(category) {
                case ThingCategory.OUTFIT:
                    thing.patternX = 4;
                    thing.frames = 3;
                    break;
                case ThingCategory.MISSILE:
                    thing.patternX = 3;
                    thing.patternY = 3;
                    break;
            }
            
            thing.spriteIndex = createSpriteIndexList(thing);
            return thing;
        }
        
        public static function createAlertThing(category:String):ThingType
        {
            var thing:ThingType = createThing(category);
            if (thing) {
                var spriteIndex:Vector.<uint> = thing.spriteIndex;
                var length:uint = spriteIndex.length;
                for (var i:uint = 0; i < length; i++) {
                    spriteIndex[i] = 0xFFFFFFFF;
                }
            }
            return thing;
        }
        
        public static function isValid(thing:ThingType):Boolean
        {
            if (thing && thing.width != 0 && thing.height != 0) return true;
            return false;
        }
        
        public static function createSpriteIndexList(thing:ThingType):Vector.<uint>
        {
            if (thing)
                return new Vector.<uint>(thing.width *
                                         thing.height *
                                         thing.patternX *
                                         thing.patternY *
                                         thing.patternZ *
                                         thing.layers *
                                         thing.frames);
            return null;
        }
    }
}
