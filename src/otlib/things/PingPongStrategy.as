///////////////////////////////////////////////////////////////////////////////////
// 
//  Copyright (c) 2014 <nailsonnego@gmail.com>
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

package otlib.things
{
    import otlib.resources.Resources;

    public class PingPongStrategy implements IFrameStrategy
    {
        //--------------------------------------------------------------------------
        // PROPERTIES
        //--------------------------------------------------------------------------
        
        private var _currentDirection:uint;
        
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function PingPongStrategy()
        {
            super();
        }
        
        //--------------------------------------------------------------------------
        // METHODS
        //--------------------------------------------------------------------------
        
        //--------------------------------------
        // Public
        //--------------------------------------
        
        public function toString():String
        {
            return Resources.getString("pingPong");
        }
        
        public function getNextFrame(currentFrame:uint, totalFrames:uint):uint
        {
            var count:int = _currentDirection == FRAME_FORWARD ? 1 : -1;
            var nextFrame:int = currentFrame + count;
            
            if (currentFrame + count < 0 || nextFrame >= totalFrames)
            {
                _currentDirection = _currentDirection == FRAME_FORWARD ? FRAME_BACKWARD : FRAME_FORWARD;
                count *= -1;
            }
            
            return currentFrame + count;
        }
        
        public function clone():IFrameStrategy
        {
            var clone:PingPongStrategy = new PingPongStrategy();
            clone._currentDirection = _currentDirection;
            return clone;
        }
        
        public function reset():void
        {
            _currentDirection = FRAME_FORWARD;
        }
        
        private static const FRAME_FORWARD:uint = 0;
        private static const FRAME_BACKWARD:uint = 1;
    }
}
