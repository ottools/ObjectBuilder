/*
*  Copyright (c) 2014 <nailsonnego@gmail.com>
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
    import mx.core.UIComponent;
    
    [Style(name="lineColor", inherit="no", type="uint", format="Color")]
    
    public class Ruler extends UIComponent
    {
        //--------------------------------------------------------------------------
        // PROPERTIES
        //--------------------------------------------------------------------------
        
        private var m_zoom:Number = 1.0;
        
        //--------------------------------------
        // Getters / Setters 
        //--------------------------------------
        
        public function get zoom():Number { return m_zoom; }
        public function set zoom(value:Number):void
        {
            if (m_zoom != value)
            {
                m_zoom = value;
                invalidateDisplayList();
            }
        }
        
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function Ruler()
        {
            super();
        }
        
        //--------------------------------------------------------------------------
        // METHODS
        //--------------------------------------------------------------------------
        
        //--------------------------------------
        // Override Protected
        //--------------------------------------
        
        override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
        {
            super.updateDisplayList(unscaledWidth, unscaledHeight);
            
            var lineColor:Number = getStyle("lineColor");
            if (isNaN(lineColor))
                lineColor = 0x000000;
            
            graphics.clear();
            graphics.lineStyle(1, lineColor);
            
            var size:Number = (32 * m_zoom);
            var w:int = int(width / size) + 1;
            var h:int = int(height / size) + 1;
            var i:int = 0;
            var v:Number = NaN;
            
            for (i = 0; i < w; i++)
            {
                var x:int = (i * size) + 15;
                
                graphics.moveTo(x, 0);
                graphics.lineTo(x, 15);
                
                v = x + (8 * m_zoom);
                graphics.moveTo(v, 10);
                graphics.lineTo(v, 15);
                
                v = x + (16 * m_zoom);
                graphics.moveTo(v, 8);
                graphics.lineTo(v, 15);
                
                v = x + (24 * m_zoom);
                graphics.moveTo(v, 10);
                graphics.lineTo(v, 15);
            }
            
            for (i = 0; i < h; i++)
            {
                var y:int = (i * size) + 15;
                
                graphics.moveTo(0, y);
                graphics.lineTo(15, y);
                
                v = y + (8 * m_zoom);
                graphics.moveTo(10, v);
                graphics.lineTo(15, v);
                
                v = y + (16 * m_zoom);
                graphics.moveTo(8, v);
                graphics.lineTo(15, v);
                
                v = y + (24 * m_zoom);
                graphics.moveTo(10, v);
                graphics.lineTo(15, v);
            }
            
            graphics.endFill();
        }
    }
}
