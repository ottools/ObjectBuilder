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

package nail.otlib.things
{
    import nail.errors.AbstractClassError;
    
    public final class MarketCategory
    {
        //--------------------------------------------------------------------------
        //
        // CONSTRUCTOR
        //
        //--------------------------------------------------------------------------
        
        public function MarketCategory()
        {
            throw new AbstractClassError(MarketCategory);
        }
        
        //--------------------------------------------------------------------------
        //
        // STATIC
        //
        //--------------------------------------------------------------------------
        
        static public const ARMORS : uint = 1; 
        static public const AMULETS : uint = 2;
        static public const BOOTS : uint = 3;
        static public const CONTAINERS : uint = 4;
        static public const DECORATION : uint = 5;
        static public const FOOD : uint = 6;
        static public const HELMETS_HATS : uint = 7;
        static public const LEGS : uint = 8;
        static public const OTHERS : uint = 9;
        static public const POTIONS : uint = 10;
        static public const RINGS : uint = 11;
        static public const RUNES : uint = 12;
        static public const SHIELDS : uint = 13;
        static public const TOOLS : uint = 14;
        static public const VALUABLES : uint = 15;
        static public const AMMUNITION : uint = 16;
        static public const AXES : uint = 17;
        static public const CLUBS : uint = 18;
        static public const DISTANCE_WEAPONS : uint = 19;
        static public const SWORDS : uint = 20;
        static public const WANDS_RODS : uint = 21;
        static public const PREMIUM_SCROLLS : uint = 22;
        static public const CATEGORY_META_WEAPONS : uint = 255;
    }
}
