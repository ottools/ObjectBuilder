/*
*  Copyright (c) 2014 Object Builder <https://github.com/Mignari/ObjectBuilder>
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

package otlib.components
{
    import flash.display.BitmapData;
    import flash.events.Event;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.getTimer;
    
    import mx.core.UIComponent;
    
    import otlib.geom.Rect;
    import otlib.things.Animator;
    import otlib.things.FrameDuration;
    import otlib.things.ThingCategory;
    import otlib.things.ThingData;
    import otlib.things.ThingType;
    import otlib.utils.OutfitData;
    
    [Event(name="change", type="flash.events.Event")]
    [Event(name="complete", type="flash.events.Event")]
    
    public class ThingDataView extends UIComponent
    {
        //--------------------------------------------------------------------------
        // PROPERTIES
        //--------------------------------------------------------------------------
        
        private var _thingData:ThingData;
        private var _proposedThingData:ThingData;
        private var _thingDataChanged:Boolean;
        private var _spriteSheet:BitmapData;
        private var _textureIndex:Vector.<Rect>;
        private var _bitmap:BitmapData;
        private var _point:Point;
        private var _rectangle:Rectangle;
        private var _frame:int;
        private var _maxFrame:int;
        private var _playing:Boolean;
        private var _lastTime:Number;
        private var _time:Number;
        private var _patternX:uint;
        private var _patternY:uint;
        private var _patternZ:uint;
        private var _layer:uint;
        private var _outfitData:OutfitData;
        private var _drawBlendLayer:Boolean;
        
        //--------------------------------------
        // Getters / Setters
        //--------------------------------------
        
        [Bindable]
        public function get thingData():ThingData { return _proposedThingData ? _proposedThingData : _thingData; }
        public function set thingData(value:ThingData):void
        {
            if (_thingData != value) {
                _proposedThingData = value;
                _thingDataChanged = true;
                invalidateProperties();
            }
        }
        
        public function get patternX():uint { return _patternX; }
        public function set patternX(value:uint):void { _patternX = value; }
        
        public function get patternY():uint { return _patternY; }
        public function set patternY(value:uint):void { _patternY = value; }
        
        public function get patternZ():uint { return _patternZ; }
        public function set patternZ(value:uint):void { _patternZ = value; }
        
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
        
        public function get outfitData():OutfitData { return _outfitData; }
        public function set outfitData(value:OutfitData):void { _outfitData = value; }
        
        public function get drawBlendLayer():Boolean { return _drawBlendLayer; }
        public function set drawBlendLayer(value:Boolean):void { _drawBlendLayer = value; }
        
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
            if (thingData && thingData.thing.isAnimation)
                _playing = true;
        }
        
        public function pause():void
        {
            _playing = false;
        }
        
        public function stop():void
        {
            _playing = false;
            this.frame = 0;
        }
        
        public function getFrameDuration(index:int):FrameDuration
        {
            if (thingData && thingData.thing.animator)
                return thingData.thing.animator.frameDurations[index];
            
            return null;
        }
        //--------------------------------------
        // Override Protected
        //--------------------------------------
        
        override protected function commitProperties():void
        {
            super.commitProperties();
            
            if (_thingDataChanged) {
                setThingData(_proposedThingData);
                _proposedThingData = null;
                _thingDataChanged = false;
            }
        }
        
        //--------------------------------------
        // Private
        //--------------------------------------
        
        private function setThingData(thingData:ThingData):void
        {
            if (thingData) {
                
                if (thingData.category == ThingCategory.OUTFIT) {
                    if (thingData.thing.animator)
                        thingData.thing.animator.skipFirstFrame = true;
                    
                    thingData = ThingData.colorizeOutfit(thingData, _outfitData);
                }
                
                _textureIndex = new Vector.<Rect>();
                _spriteSheet = ThingData.getSpriteSheet(thingData, _textureIndex, 0);
                _bitmap = new BitmapData(thingData.thing.width * 32, thingData.thing.height * 32);
                _maxFrame = thingData.thing.frames;
                _frame = 0;
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
            
            _thingData = thingData;
            
            draw();
        }
        
        private function draw():void
        {
            graphics.clear();
            
            if (_spriteSheet)
            {
                var thing:ThingType = thingData.thing;
                var px:uint = _patternX % thing.patternX;
                var pz:uint = _patternZ % thing.patternZ;
                var index:int = thing.getTextureIndex(0, px, 0, pz, _frame);
                
                var rect:Rect = _textureIndex[index];
                _rectangle.setTo(rect.x, rect.y, rect.width, rect.height);
                _bitmap.copyPixels(_spriteSheet, _rectangle, _point);
                
                if (_drawBlendLayer && thing.layers > 1) 
                {
                    index = thing.getTextureIndex(1 % thing.layers, px, 0, pz, _frame);
                    
                    rect = _textureIndex[index];
                    _rectangle.setTo(rect.x, rect.y, rect.width, rect.height);
                    _bitmap.copyPixels(_spriteSheet, _rectangle, _point, null, null, true);
                }
                
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
            this.addEventListener(Event.ENTER_FRAME, enterFramehandler);
        }
        
        protected function enterFramehandler(event:Event):void
        {
            if (!_playing || !thingData)
                return;
            
            var elapsed:Number = getTimer();
            var animator:Animator = thingData.thing.animator;
            if (animator) {
                animator.update(elapsed);
                if (animator.isComplete) {
                    pause();
                    dispatchEvent(new Event(Event.COMPLETE));
                }
                
                this.frame = animator.frame;
            }
        }
    }
}
