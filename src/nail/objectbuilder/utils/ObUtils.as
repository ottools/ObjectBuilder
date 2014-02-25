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

package nail.objectbuilder.utils
{
	import mx.resources.ResourceManager;
	
	import nail.errors.AbstractClassError;
	import nail.otlib.things.ThingCategory;

	[ResourceBundle("controls")]
	
	public final class ObUtils
	{
		//--------------------------------------------------------------------------
		//
		// CONSTRUCTOR
		//
		//--------------------------------------------------------------------------
		
		public function ObUtils()
		{
			throw new AbstractClassError(ObUtils);
		}
		
		//--------------------------------------------------------------------------
		//
		// STATIC
		//
		//--------------------------------------------------------------------------
		
		static public function toLocale(category:String) : String
		{
			var result : String = "";
			
			if (ThingCategory.getCategory(category) != null)
			{
				switch(category)
				{
					case ThingCategory.ITEM:
						result = ResourceManager.getInstance().getString("controls", "label.item");
						break;
					case ThingCategory.OUTFIT:
						result = ResourceManager.getInstance().getString("controls", "label.outfit");
						break;
					case ThingCategory.EFFECT:
						result = ResourceManager.getInstance().getString("controls", "label.effect");
						break;
					case ThingCategory.MISSILE:
						result = ResourceManager.getInstance().getString("controls", "label.missile");
						break;
				}
			}
			return result;
		}
	}
}
