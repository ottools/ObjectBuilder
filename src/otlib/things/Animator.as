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
    import flash.utils.getTimer;

    public class Animator
    {
        //--------------------------------------------------------------------------
        // PROPERTIES
        //--------------------------------------------------------------------------
        
        public var animationMode:int;
        public var frameStrategy:int;
        public var frameDurations:Vector.<FrameDuration>;
        public var frames:uint;
        public var startFrame:int;
        public var nextFrameStrategy:IFrameStrategy;
        public var skipFirstFrame:Boolean;
        
        private var _lastTime:Number = 0;
        private var _currentFrameDuration:uint;
        private var _isComplete:Boolean;
        private var _currentFrame:uint;
        
        //--------------------------------------
        // Getters / Setters
        //--------------------------------------
        
        public function get frame():int
        {
            return _currentFrame;
        }
        
        public function set frame(value:int):void
        {
            if (_currentFrame == value) return;
            
            if (this.animationMode == AnimationMode.ASYNCHRONOUS) {
                
                if (value == FRAME_ASYNCHRONOUS)
                    _currentFrame = 0;
                else if (value == FRAME_RANDOM)
                    _currentFrame = Math.floor(Math.random() * this.frames);
                else if (value >= 0 && value < this.frames)
                    _currentFrame = value;
                else
                    _currentFrame = this.getStartFrame();
                
                _isComplete = false;
                _lastTime = getTimer();
                _currentFrameDuration = this.frameDurations[_currentFrame].duration;
            
            } else {
                this.calculateSynchronous();
            }
        }
        
        public function get isComplete():Boolean
        {
            return _isComplete;
        }
        
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function Animator()
        {
        }
        
        //--------------------------------------------------------------------------
        // METHODS
        //--------------------------------------------------------------------------
        
        //--------------------------------------
        // Public
        //--------------------------------------
        
        public function update(time:Number):void
        {
            if (time != _lastTime && !_isComplete) {
                
                var elapsed:Number = time - _lastTime;
                if (elapsed >= _currentFrameDuration) {
                    var frame:uint = this.nextFrameStrategy.getNextFrame(_currentFrame, this.frames);
                    if (_currentFrame != frame) {
                        
                        var duration:int = this.frameDurations[frame].duration - (elapsed - _currentFrameDuration);
                        if (duration < 0 && this.animationMode == AnimationMode.SYNCHRONOUS) {
                            this.calculateSynchronous();
                        } else {
                            _currentFrame = skipFirstFrame && frame == 0 ? 1 % frames : frame;
                            _currentFrameDuration = Math.max(0, duration);
                        }
                        
                    } else {
                        _isComplete = true;
                    }
                    
                } else {
                    _currentFrameDuration = _currentFrameDuration - elapsed;
                }
                
                _lastTime = time;
            }
        }
        
        public function clone():Animator
        {
            if (this.animationMode == AnimationMode.SYNCHRONOUS)
                return this;
            
            var clone:Animator = new Animator();
            clone.frameStrategy = frameStrategy;
            clone.frames = frames;
            clone.startFrame = startFrame;
            clone.nextFrameStrategy = nextFrameStrategy;
            clone.animationMode = animationMode;
            clone.frameDurations = frameDurations;
            clone.nextFrameStrategy = this.nextFrameStrategy.clone();
            clone.skipFirstFrame = skipFirstFrame;
            clone.frame = FRAME_AUTOMATIC;
            return clone;
        }
        
        public function getStartFrame():uint
        {
            if (this.startFrame > -1)
                return this.startFrame;
            
            return Math.floor(Math.random() * this.frames);
        }
        
        public function reset():void
        {
            frame = FRAME_AUTOMATIC;
            nextFrameStrategy.reset();
            _isComplete = false;
        }
        
        //--------------------------------------
        // Private
        //--------------------------------------
        
        private function calculateSynchronous():void
        {
            var totalDuration:Number = 0;
            
            for (var i:uint = 0; i < frames; i++)
                totalDuration += frameDurations[i].duration;
            
            var time:Number = getTimer();
            var elapsed:Number = time % totalDuration;
            var totalTime:Number = 0;
            
            for (i = 0; i < frames; i++) {
                var duration:Number = this.frameDurations[i].duration;
                if (elapsed >= totalTime && elapsed < totalTime + duration) {
                    _currentFrame = i;
                    var timeDiff:Number = elapsed - totalTime;
                    _currentFrameDuration = duration - timeDiff;
                    break;
                }
                
                totalTime += duration;
            }
            
            _lastTime = time;
        }
        
        //--------------------------------------------------------------------------
        // STATIC
        //--------------------------------------------------------------------------
        
        public static const FRAME_AUTOMATIC:int = -1;
        public static const FRAME_RANDOM:int = 0xFE;
        public static const FRAME_ASYNCHRONOUS:int = 0xFF;
        
        public static function create(frames:uint,
                                      startFrame:int,
                                      frameStrategy:int,
                                      animationMode:int,
                                      frameDurations:Vector.<FrameDuration>):Animator
        {
            if (animationMode != AnimationMode.ASYNCHRONOUS && animationMode != AnimationMode.SYNCHRONOUS)
                throw new ArgumentError("Unexpected animation mode " + animationMode);
            
            if (frameDurations.length != frames)
                throw new ArgumentError("Frame duration differs from frame count");
            
            if (startFrame < -1 || startFrame >= frames)
                throw new ArgumentError("Invalid start frame " + startFrame);
            
            var animator:Animator = new Animator();
            animator.frameStrategy = frameStrategy;
            animator.frames = frames;
            animator.startFrame = startFrame;
            animator.animationMode = animationMode;
            animator.frameDurations = frameDurations;
            
            var strategy:IFrameStrategy;
            if (frameStrategy < 0)
                strategy = new PingPongStrategy();
            else {
                strategy = new LoopStrategy();
                LoopStrategy(strategy).loopCount = frameStrategy;
            }
                
            animator.nextFrameStrategy = strategy;
            animator.frame = FRAME_AUTOMATIC;
            return animator;
        }
    }
}
