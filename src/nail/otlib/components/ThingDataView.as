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

package nail.otlib.components
{
    import flash.display.BitmapData;
    import flash.events.Event;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.getTimer;
    
    import mx.core.UIComponent;
    
    import nail.otlib.geom.Rect;
    import nail.otlib.things.ThingCategory;
    import nail.otlib.things.ThingData;
    import nail.otlib.things.ThingType;
    
    [Event(name="change", type="flash.events.Event")]
    public class ThingDataView extends UIComponent
    {
        //--------------------------------------------------------------------------
        // PROPERTIES
        //--------------------------------------------------------------------------
        
        private var _thingData:ThingData;
        private var _thingDataChanged:Boolean;
        private var _spriteSheet:BitmapData;
        private var _textureIndex:Vector.<Rect>;
        private var _bitmap:BitmapData;
        private var _point:Point;
        private var _rectangle:Rectangle;
        private var _frame:int;
        private var _maxFrame:int;
        private var _playing:Boolean;
        private var _duration:uint;
        private var _lastTime:Number;
        private var _time:Number;
        
        //--------------------------------------
        // Getters / Setters
        //--------------------------------------
        
        [Bindable]
        public function get thingData():ThingData { return _thingData; }
        public function set thingData(value:ThingData):void
        {
            if (_thingData != value) {
                _thingData = value;
                _thingDataChanged = true;
                invalidateProperties();
            }
        }
        
        public function get frame():int { return _frame; }
        public function set frame(value:int):void
        {
            if (_frame != value) {
                _frame = value % _maxFrame;
                _time = 0;
                draw();
                
                if (hasEventListener(Event.CHANGE))
                    dispatchEvent(new Event(Event.CHANGE));
            }
        }
        
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function ThingDataView()
        {
            _point = new Point();
            _rectangle = new Rectangle();
            _frame = -1;
            _lastTime = 0;
            _time = 0;
            
            this.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
        }
        
        //--------------------------------------------------------------------------
        // METHODS
        //--------------------------------------------------------------------------
        
        //--------------------------------------
        // Public
        //--------------------------------------
        
        public function fistFrame():void
        {
            this.frame = 0;
        }
        
        public function prevFrame():void
        {
            this.frame = Math.max(0, _frame - 1);
        }
        
        public function nextFrame():void
        {
            this.frame = _frame + 1;
        }
        
        public function lastFrame():void
        {
            this.frame = Math.max(0, _maxFrame - 1);
        }
        
        public function play():void
        {
            _playing = true;
        }
        
        public function pause():void
        {
            _playing = false;
        }
        
        //--------------------------------------
        // Override Protected
        //--------------------------------------
        
        override protected function commitProperties():void
        {
            super.commitProperties();
            
            if (_thingDataChanged) {
                setThingData(_thingData);
                _thingDataChanged = false;
            }
        }
        
        //--------------------------------------
        // Private
        //--------------------------------------
        
        private function setThingData(thingData:ThingData):void
        {
            if (thingData) {
                var thing:ThingType = thingData.thing;
                _textureIndex = new Vector.<Rect>();
                _spriteSheet = ThingData.getSpriteSheet(thingData, _textureIndex, 0);
                _bitmap = new BitmapData(thing.width * 32, thing.height * 32);
                _maxFrame = thing.frames;
                _frame = 0;
                _duration = thing.category == ThingCategory.ITEM ? 400 : 200;
                this.width = _bitmap.width;
                this.height = _bitmap.height;
            } else {
                _textureIndex = null;
                _spriteSheet = null;
                _bitmap = null;
                _maxFrame = -1;
                _frame = -1;
                _playing = false;
            }
            
            draw();
        }
        
        private function draw():void
        {
            graphics.clear();
            
            if (_spriteSheet) {
                var rect:Rect = _textureIndex[_frame];
                
                _rectangle.setTo(rect.x, rect.y, rect.width, rect.height);
                _bitmap.copyPixels(_spriteSheet, _rectangle, _point);
                
                graphics.beginBitmapFill(_bitmap);
                graphics.drawRect(0, 0, rect.width, rect.height);
            }
           
            graphics.endFill();
        }
        
        //--------------------------------------
        // Event Handlers
        //--------------------------------------
        
        protected function addedToStageHandler(event:Event):void
        {
            this.removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
            this.addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
            this.addEventListener(Event.ENTER_FRAME, enterFramehandler);
        }
        
        protected function removedFromStageHandler(event:Event):void
        {
            this.removeEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
            this.removeEventListener(Event.ENTER_FRAME, enterFramehandler);
        }
        
        protected function enterFramehandler(event:Event):void
        {
            if (!_playing)
                return;
            
            var elapsed:Number = getTimer();
            _time = (elapsed - _lastTime);
            if (_time >= _duration) {
                nextFrame();
                _lastTime = elapsed;
            }
        }
    }
}
