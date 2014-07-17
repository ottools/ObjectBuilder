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

package nail.animationeditor
{
    import flash.display.BitmapData;
    
    import nail.otlib.components.IListObject;

    public class Frame implements IListObject
    {
        //--------------------------------------------------------------------------
        // PROPERTIES
        //--------------------------------------------------------------------------
        
        public var minDuration:uint;
        public var maxDuration:uint;
        public var opacity:Number;
        public var bitmap:BitmapData;
        
        //--------------------------------------
        // Getters / Setters
        //--------------------------------------
        
        public function get id():uint { return uint.MAX_VALUE; }
        
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function Frame(bitmap:BitmapData = null)
        {
            this.minDuration = 0;
            this.maxDuration = 0;
            this.opacity = 1.0;
            this.bitmap = bitmap;
        }
        
        //--------------------------------------------------------------------------
        // METHODS
        //--------------------------------------------------------------------------
        
        //--------------------------------------
        // Public
        //--------------------------------------
        
        public function getBitmap(backgroundColor:uint = 0):BitmapData
        {
            return bitmap;
        }
        
        public function clone():Frame
        {
            var clone:Frame = new Frame();
            clone.minDuration = this.minDuration;
            clone.maxDuration = this.maxDuration;
            clone.opacity = this.opacity;
            clone.bitmap = this.bitmap ? this.bitmap.clone() : null;
            return clone;
        }
    }
}
