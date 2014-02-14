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

package nail.objectbuilder.core
{
	import nail.errors.AbstractClassError;

	public final class Icons
	{
		//--------------------------------------------------------------------------
		//
		// CONSTRUCTOR
		//
		//--------------------------------------------------------------------------
		
		public function Icons()
		{
			throw new AbstractClassError(Icons);
		}
		
		//--------------------------------------------------------------------------
		//
		// STATIC
		//
		//--------------------------------------------------------------------------
		
		[Embed(source="../assets/export.png", mimeType="image/png")]
		static public const EXPORT : Class;
		
		[Embed(source="../assets/import.png", mimeType="image/png")]
		static public const IMPORT : Class;
		
		[Embed(source="../assets/duplicate.png", mimeType="image/png")]
		static public const DUPLICATE : Class;
		
		[Embed(source="../assets/new.png", mimeType="image/png")]
		static public const NEW : Class;
		
		[Embed(source="../assets/delete.png", mimeType="image/png")]
		static public const DELETE : Class;
		
		[Embed(source="../assets/edit.png", mimeType="image/png")]
		static public const EDIT : Class;
		
		[Embed(source="../assets/replace.png", mimeType="image/png")]
		static public const REPLACE : Class;
		
		[Embed(source="../assets/open.png", mimeType="image/png")]
		static public const OPEN : Class;
		
		[Embed(source="../assets/open_white.png", mimeType="image/png")]
		static public const OPEN_WHITE : Class;
		
		[Embed(source="../assets/save.png", mimeType="image/png")]
		static public const SAVE : Class;
		
		[Embed(source="../assets/save_white.png", mimeType="image/png")]
		static public const SAVE_WHITE : Class;
		
		[Embed(source="../assets/info.png", mimeType="image/png")]
		static public const INFO : Class;
		
		[Embed(source="../assets/log.png", mimeType="image/png")]
		static public const LOG : Class;
		
		[Embed(source="../assets/log_white.png", mimeType="image/png")]
		static public const LOG_WHITE : Class;
	}
}
