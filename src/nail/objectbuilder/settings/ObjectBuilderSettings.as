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

package nail.objectbuilder.settings
{
	import flash.filesystem.File;
	
	import nail.codecs.ImageFormat;
	import nail.objectbuilder.utils.SupportedLanguages;
	import nail.otlib.assets.AssetsVersion;
	import nail.otlib.utils.OTFormat;
	import nail.settings.Settings;
	import nail.utils.FileUtils;
	
	public class ObjectBuilderSettings extends Settings
	{
		//--------------------------------------------------------------------------
		//
		// PROPERTIES
		//
		//--------------------------------------------------------------------------
		
		public var lastDirectory : String;
		public var lastImportExportDirectory : String;
		public var lastExportThingFormat : String;
		public var datSignature : int;
		public var sprSignature : int;
		public var lastExportSpriteFormat : String;
		public var autosaveThingChanges : Boolean;
		public var maximized : Boolean;
		public var previewContainerWidth : Number = 0;
		public var thingListContainerWidth : Number = 0;
		public var spritesContainerWidth : Number = 0;
		public var showThingList : Boolean;
		public var language : String;
		public var extended : Boolean;
		public var transparency : Boolean;
		public var savingSpriteSheet : Number = 0;
		
		//--------------------------------------------------------------------------
		//
		// CONSTRUCTOR
		//
		//--------------------------------------------------------------------------
		
		public function ObjectBuilderSettings()
		{
			super();
		}
		
		//--------------------------------------------------------------------------
		//
		// METHODS
		//
		//--------------------------------------------------------------------------
		
		//--------------------------------------
		// Public
		//--------------------------------------
		
		public function getLastDirectory() : File
		{
			var directory : File;
			
			if (isNullOrEmpty(lastDirectory))
			{
				return null;
			}
			
			try
			{
				directory = new File(lastDirectory);
			} 
			catch(error:Error) 
			{
				return null;
			}
			return directory;
		}
		
		public function setLastDirectory(file:File) : void
		{
			if (file != null)
			{
				this.lastDirectory = FileUtils.getDirectory(file).nativePath;
			}
		}
		
		public function getLastImportExportDirectory() : File
		{
			var directory : File;
			
			if (isNullOrEmpty(lastImportExportDirectory))
			{
				return null;
			}
			
			try
			{
				directory = new File(lastImportExportDirectory);
			} 
			catch(error:Error) 
			{
				return null;
			}
			return directory;
		}
		
		public function setLastImportExportDirectory(file:File) : void
		{
			if (file != null)
			{
				this.lastImportExportDirectory = FileUtils.getDirectory(file).nativePath;
			}
		}
		
		public function getLastExportThingFormat() : String
		{
			if (!isNullOrEmpty(lastExportThingFormat))
			{
				if (ImageFormat.hasImageFormat(lastExportThingFormat) || lastExportThingFormat == OTFormat.OBD)
				{
					return lastExportThingFormat;
				}
			}
			return null;
		}
		
		public function setLastExportThingFormat(format:String) : void
		{
			format = format == null ? "" : format.toLowerCase();
			this.lastExportThingFormat = format;
		}
		
		public function getLastExportThingVersion() : AssetsVersion
		{
			return AssetsVersion.getVersionBySignatures(datSignature, sprSignature);
		}
		
		public function setLastExportThingVersion(version:AssetsVersion) : void
		{
			this.datSignature = version == null ? 0 : version.datSignature;
			this.sprSignature = version == null ? 0 : version.sprSignature;
		}
		
		public function getLastExportSpriteFormat() : String
		{
			if (ImageFormat.hasImageFormat(lastExportSpriteFormat))
			{
				return lastExportSpriteFormat;
			}
			return null;
		}
		
		public function setLastExportSpriteFormat(format:String) : void
		{
			format = format == null ? "" : format.toLowerCase();
			this.lastExportSpriteFormat = format;
		}
		
		public function getLanguage() : Array
		{
			if (isNullOrEmpty(language) || language == "null")
			{
				return [SupportedLanguages.EN_US];
			}
			return [language];
		}
	}
}
