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

package nail.otlib.events
{
    import flash.events.Event;
    
    import nail.otlib.things.ThingType;
    
    public class ThingTypeStorageEvent extends Event
    {
        //--------------------------------------------------------------------------
        //
        // PROPERTIES
        //
        //--------------------------------------------------------------------------
        
        public var thing:ThingType;
        public var loaded:uint;
        public var total:uint;
        
        //--------------------------------------------------------------------------
        //
        // CONSTRUCTOR
        //
        //--------------------------------------------------------------------------
        
        public function ThingTypeStorageEvent(type:String, thing:ThingType = null, loaded:uint = 0, total:uint = 0)
        {
            super(type);
            
            this.thing = thing;
            this.loaded = loaded;
            this.total = total;
        }
        
        //--------------------------------------------------------------------------
        //
        // METHODS
        //
        //--------------------------------------------------------------------------
        
        //--------------------------------------
        // Override Public
        //--------------------------------------
        
        override public function clone():Event
        {
            return new ThingTypeStorageEvent(this.type, this.thing, this.loaded, this.total);
        }
        
        //--------------------------------------------------------------------------
        //
        // STATIC
        //
        //--------------------------------------------------------------------------
        
        public static const FIND_PROGRESS : String = "findProgress";
    }
}
