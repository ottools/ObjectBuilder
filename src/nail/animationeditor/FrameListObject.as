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
    
    public class FrameListObject implements IListObject
    {
        //--------------------------------------------------------------------------
        //
        // PROPERTIES
        //
        //--------------------------------------------------------------------------
        
        private var _bitmap:BitmapData; 
        
        //--------------------------------------
        // Getters / Setters
        //--------------------------------------
        
        public function get id():uint { return uint.MAX_VALUE; }
        
        //--------------------------------------------------------------------------
        //
        // CONSTRUCTOR
        //
        //--------------------------------------------------------------------------
        
        public function FrameListObject(bitmap:BitmapData)
        {
            _bitmap = bitmap;
        }
        
        //--------------------------------------------------------------------------
        //
        // METHODS
        //
        //--------------------------------------------------------------------------
        
        //--------------------------------------
        // Public
        //--------------------------------------
        
        public function getBitmap(backgroundColor:uint = 0):BitmapData
        {
            return _bitmap;
        }
        
        public function clone():FrameListObject
        {
           return new FrameListObject(_bitmap.clone());
        }
    }
}
