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

package nail.objectbuilder.commands
{
	import nail.otlib.assets.AssetsVersion;
	import nail.otlib.things.ThingType;
	import nail.utils.FileData;
	import nail.workers.Command;
	
	public class ExportThingCommand extends Command
	{
		//--------------------------------------------------------------------------
		//
		// CONSTRUCTOR
		//
		//--------------------------------------------------------------------------
		
		public function ExportThingCommand(fileDataList:Vector.<FileData>, category:String, version:AssetsVersion, spriteSheetFlag:uint)
		{
			var list : Array;
			var length : uint;
			var i : uint;
			var fileData : FileData;
			var thing : ThingType;
			
			list = [];
			length = fileDataList.length;
			for (i = 0; i < length; i++)
			{
				fileData = fileDataList[i];
				thing = fileData.data as ThingType;
				list[i] = {id:thing.id, file:fileData.file.nativePath};
			}
			
			super(CommandType.EXPORT_THING, list, category, version.datSignature, version.sprSignature, spriteSheetFlag);
		}
	}
}
