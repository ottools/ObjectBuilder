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

package nail.otlib.sprites
{
    import flash.utils.ByteArray;
    import flash.utils.Endian;
    
    public class Sprite
    {
        //--------------------------------------------------------------------------
        // PROPERTIES
        //--------------------------------------------------------------------------
        
        private var _bytes:ByteArray;
        private var _size:uint;
        private var _alphaEnabled:Boolean;
        private var _empty:Boolean;
        
        //--------------------------------------
        // Getters / Setters
        //--------------------------------------
        
        public function get bytes():ByteArray { return _bytes; }
        public function get size():uint { return _size; }
        public function set size(value:uint):void { _size = value; }
        
        public function get empty():Boolean { return _empty; }
        public function set empty(value:Boolean):void {
            if (_empty != value) {
                _empty = value;
                if (_empty) {
                    _bytes.length = 0;
                    _size = 0;
                }
            }
        }
        
        public function get alphaEnabled():Boolean { return _alphaEnabled; }
        public function set alphaEnabled(value:Boolean):void {
            if (_alphaEnabled != value) {
                setBytes(getPixels(), value);
            }
        }
        
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function Sprite(alphaEnabled:Boolean = false)
        {
            _bytes = new ByteArray();
            _bytes.endian = Endian.LITTLE_ENDIAN;
            _alphaEnabled = alphaEnabled;
            _empty = true;
        }
        
        //--------------------------------------------------------------------------
        // METHODS
        //--------------------------------------------------------------------------
        
        //--------------------------------------
        // Public
        //--------------------------------------
        
        public function setBytes(pixels:ByteArray, useAlpha:Boolean):Boolean
        {
            var length:uint = pixels.length / 4;
            if (length != 1024) return false;
            
            _bytes.clear();
            pixels.position = 0;
            
            var index:uint;
            var color:uint;
            var transparent:Boolean = true;
            var alphaCount:uint;
            var chunkSize:uint;
            var coloredPos:uint;
            var finishOffset:uint;
            
            while (index < length) {
                chunkSize = 0;
                while (index < length) {
                    pixels.position = index * 4;
                    color = pixels.readUnsignedInt();
                    transparent = (color == 0);
                    if (!transparent) break;
                    alphaCount++;
                    chunkSize++;
                    index++;
                }
                
                // Entire image is transparent
                if (alphaCount < length) {
                    // Already at the end
                    if(index < length) {
                        _bytes.writeShort(chunkSize);          // Write transparent pixels
                        coloredPos = _bytes.position;          // Save colored position 
                        _bytes.position = _bytes.position + 2; // Skip colored short
                        chunkSize = 0;
                        
                        while(index < length) {
                            pixels.position = index * 4;
                            color = pixels.readUnsignedInt();
                            transparent = (color == 0);
                            if (transparent) break;
                            
                            _bytes.writeByte(color >> 16 & 0xFF);              // Write red
                            _bytes.writeByte(color >> 8 & 0xFF);               // Write green
                            _bytes.writeByte(color & 0xFF);                    // Write blue
                            if (useAlpha) bytes.writeByte(color >> 24 & 0xFF); // Write Alpha
                            
                            chunkSize++;
                            index++; 
                        }
                        
                        finishOffset = _bytes.position;
                        _bytes.position = coloredPos; // Go back to chunksize indicator
                        _bytes.writeShort(chunkSize); // Write colored pixels
                        _bytes.position = finishOffset;
                    }
                }
            }
            
            _size = bytes.length;
            _empty = false;
            _alphaEnabled = useAlpha;
            return true;
        }
        
        public function getPixels():ByteArray
        {
            if (_alphaEnabled) {
                return getPixelsWithAlpha();
            }
            
            _bytes.position = 0;
            
            var read:uint;
            var write:uint;
            var transparentPixels:uint;
            var coloredPixels:uint;
            var i:uint;
            var pixels:ByteArray = new ByteArray();
            
            for (read = 0; read < _size; read += 4 + (3 * coloredPixels)) {
                transparentPixels = _bytes.readUnsignedShort();
                coloredPixels = _bytes.readUnsignedShort();
                
                for (i = 0; i < transparentPixels; i++) {
                    pixels[write++] = 0x00; // Alpha
                    pixels[write++] = 0x00; // Red
                    pixels[write++] = 0x00; // Green
                    pixels[write++] = 0x00; // Blue
                }
                
                for (i = 0; i < coloredPixels; i++) {
                    pixels[write++] = 0xFF; // Alpha
                    pixels[write++] = _bytes.readUnsignedByte(); // Red
                    pixels[write++] = _bytes.readUnsignedByte(); // Green
                    pixels[write++] = _bytes.readUnsignedByte(); // Blue
                }
            }
            
            while(write < SPRITE_DATA_SIZE) {
                pixels[write++] = 0x00; // Alpha
                pixels[write++] = 0x00; // Red
                pixels[write++] = 0x00; // Green
                pixels[write++] = 0x00; // Blue	
            }
            return pixels;
        }
        
        public function clone():Sprite
        {
            var sprite:Sprite = new Sprite();
            
            _bytes.position = 0;
            _bytes.readBytes(sprite._bytes);
            
            sprite._bytes.position = 0;
            sprite._size = _size;
            sprite._empty = _empty;
            sprite._alphaEnabled = _alphaEnabled;
            return sprite;
        }
        
        //--------------------------------------
        // Private
        //--------------------------------------
        
        private function getPixelsWithAlpha():ByteArray
        {
            var read:uint;
            var write:uint;
            var transparentPixels:uint;
            var coloredPixels:uint;
            var i:int;
            var alpha:uint;
            var red:uint;
            var green:uint;
            var blue:uint;
            
            _bytes.position = 0;
            var pixels:ByteArray = new ByteArray();
            
            for (read = 0; read < _size; read += 4 + (4 * coloredPixels)) {
                transparentPixels = _bytes.readUnsignedShort();
                coloredPixels = _bytes.readUnsignedShort();
                
                for (i = 0; i < transparentPixels; i++) {
                    pixels[write++] = 0x00; // Alpha
                    pixels[write++] = 0x00; // Red
                    pixels[write++] = 0x00; // Green
                    pixels[write++] = 0x00; // Blue
                }
                
                for (i = 0; i < coloredPixels; i++) {
                    red = _bytes.readUnsignedByte();   // Red
                    green = _bytes.readUnsignedByte(); // Green
                    blue = _bytes.readUnsignedByte();  // Blue
                    alpha = _bytes.readUnsignedByte(); // Alpha
                    
                    pixels[write++] = alpha; // Alpha
                    pixels[write++] = red;   // Red
                    pixels[write++] = green; // Green
                    pixels[write++] = blue;  // Blue
                }
            }
            
            while(write < SPRITE_DATA_SIZE) {
                pixels[write++] = 0x00; // Alpha
                pixels[write++] = 0x00; // Red
                pixels[write++] = 0x00; // Green
                pixels[write++] = 0x00; // Blue	
            }
            return pixels;
        }
        
        //--------------------------------------------------------------------------
        // STATIC
        //--------------------------------------------------------------------------
        
        public static const SPRITE_PIXELS:uint = 32;
        public static const SPRITE_DATA_SIZE:uint = 4096; // SPRITE_PIXELS * SPRITE_PIXELS * 4 bytes;
        
        [Embed(source="../../../../assets/alert_sprite.png")]
        public static const ALERT_IMAGE:Class;
    }
}
