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
	import flash.display.BitmapData;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	
	import nail.objectbuilder.commands.CommandType;
	import nail.objectbuilder.commands.ErrorCommand;
	import nail.objectbuilder.commands.FindResultCommand;
	import nail.objectbuilder.commands.HideProgressBarCommand;
	import nail.objectbuilder.commands.MessageCommand;
	import nail.objectbuilder.commands.ProgressBarID;
	import nail.objectbuilder.commands.SetAssetsInfoCommand;
	import nail.objectbuilder.commands.SetSpriteListCommand;
	import nail.objectbuilder.commands.SetThingCommand;
	import nail.objectbuilder.commands.SetThingListCommand;
	import nail.objectbuilder.commands.ShowProgressBarCommand;
	import nail.objectbuilder.utils.ObUtils;
	import nail.otlib.assets.AssetsInfo;
	import nail.otlib.assets.AssetsVersion;
	import nail.otlib.events.ThingTypeStorageEvent;
	import nail.otlib.loaders.ThingDataLoader;
	import nail.otlib.sprites.Sprite;
	import nail.otlib.sprites.SpriteStorage;
	import nail.otlib.things.ThingCategory;
	import nail.otlib.things.ThingType;
	import nail.otlib.things.ThingTypeStorage;
	import nail.otlib.utils.SpriteData;
	import nail.otlib.utils.ThingData;
	import nail.otlib.utils.ThingListItem;
	import nail.otlib.utils.ThingProperty;
	import nail.otlib.utils.ThingUtils;
	import nail.utils.FileUtils;
	import nail.utils.StringUtil;
	import nail.workers.Command;
	import nail.workers.NailWorker;
	
	[ResourceBundle("strings")]
	[ResourceBundle("obstrings")]
	
	public class ObjectBuilderWorker extends NailWorker
	{
		//--------------------------------------------------------------------------
		//
		// PROPERTIES
		//
		//--------------------------------------------------------------------------
		
		private var _things : ThingTypeStorage;
		private var _sprites : SpriteStorage;
		private var _datFile : File;
		private var _sprFile : File;
		private var _version : AssetsVersion;
		private var _enableSpritesU32 : Boolean;
		private var _enableAlphaChannel : Boolean;
		private var _error : ErrorCommand;
		
		//--------------------------------------------------------------------------
		//
		// CONSTRUCTOR
		//
		//--------------------------------------------------------------------------
		
		public function ObjectBuilderWorker()
		{
			
		}
		
		//--------------------------------------------------------------------------
		//
		// METHODS
		//
		//--------------------------------------------------------------------------
		
		//--------------------------------------
		// Override Protected
		//--------------------------------------
		
		override protected function register() : void
		{
			registerClassAlias("ThingType", ThingType);
			registerClassAlias("AssetsInfo", AssetsInfo);
			registerClassAlias("SpriteData", SpriteData);
			registerClassAlias("ByteArray", ByteArray);
			registerClassAlias("ThingProperty", ThingProperty);
			registerClassAlias("ThingListItem", ThingListItem);
			registerCommand(CommandType.CREATE_NEW_ASSETS, onCreateNewAssets);
			registerCommand(CommandType.LOAD_ASSETS, onLoadAssets);
			registerCommand(CommandType.GET_ASSETS_INFO, onGetAssetsInfo);
			registerCommand(CommandType.COMPILE_ASSETS, onCompileAssets);
			registerCommand(CommandType.NEW_THING, onNewThing);
			registerCommand(CommandType.GET_THING, onGetThing);
			registerCommand(CommandType.UPDATE_THING, onChangeThing);
			registerCommand(CommandType.IMPORT_THING, onImportThing);
			registerCommand(CommandType.IMPORT_THING_FILES, onImportThingFiles);
			registerCommand(CommandType.DUPLICATE_THING, onDuplicateThing);
			registerCommand(CommandType.REMOVE_THING, onRemoveThing);
			registerCommand(CommandType.FIND_THING, onFindThing);
			registerCommand(CommandType.GET_THING_LIST, onGetThingList);
			registerCommand(CommandType.GET_SPRITE_LIST, onGetSpriteList);
			registerCommand(CommandType.REPLACE_SPRITE, onReplaceSprite);
			registerCommand(CommandType.IMPORT_SPRITES, onImportSprites);
			registerCommand(CommandType.NEW_SPRITE, onNewSprite);
			registerCommand(CommandType.REMOVE_SPRITES, onRemoveSprites);
		}
		
		//--------------------------------------
		// Private
		//--------------------------------------
		
		private function onCreateNewAssets(datSignature:uint,
										   sprSignature:uint,
										   enableSpritesU32:Boolean,
										   enableAlphaChannel:Boolean) : void
		{
			var version : AssetsVersion;
			var thing : ThingType;
			
			if (datSignature == 0 || sprSignature == 0)
			{
				throw new ArgumentError(getResourceString("obstrings", "invalidVersion"));
			}
			
			version = AssetsVersion.getVersionBySignatures(datSignature, sprSignature);
			if (version == null)
			{
				throw new ArgumentError(getResourceString("obstrings", "invalidVersion"));
			}
			
			_version = version;
			_enableSpritesU32 = enableSpritesU32;
			_enableAlphaChannel = enableAlphaChannel;
			
			createStorage();
			
			if (!_sprites.createNew(version, enableSpritesU32, enableAlphaChannel))
			{
				throw new Error(getResourceString("obstrings", "notCreateSpr"));
			}
			
			// Create things.
			if (!_things.createNew(version))
			{
				throw new Error(getResourceString("obstrings", "notCreateDat"));
			}
			
			setSharedProperty("compiled", false);
			assetsLoadComplete();
			
			// Update preview.
			thing = _things.getItemType(ThingTypeStorage.MIN_ITEM_ID);
			onGetThing(thing.id, thing.category);
			
			//Send sprites.
			sendSpriteList(1);
		}
		
		private function createStorage() : void
		{
			if (_things != null)
			{
				_things.removeEventListener(Event.COMPLETE, thingsCompleteHandler);
				_things.removeEventListener(Event.CHANGE, thingsChangeHandler);
				_things.removeEventListener(ProgressEvent.PROGRESS, thingsProgressHandler);
				_things.removeEventListener(ThingTypeStorageEvent.FIND_PROGRESS, thingFindProgressHandler);
				_things.removeEventListener(ErrorEvent.ERROR, thingsErrorHandler);
				_things = null;
			}
			
			if (_sprites != null)
			{
				_sprites.removeEventListener(Event.COMPLETE, spritesCompleteHandler);
				_sprites.removeEventListener(Event.CHANGE, spritesChangeHandler);
				_sprites.removeEventListener(ProgressEvent.PROGRESS, spritesProgressHandler);
				_sprites.removeEventListener(ErrorEvent.ERROR, spritesErrorHandler);
				_sprites = null;
			}
			
			_things = new ThingTypeStorage();
			_things.addEventListener(Event.COMPLETE, thingsCompleteHandler);
			_things.addEventListener(Event.CHANGE, thingsChangeHandler);
			_things.addEventListener(ProgressEvent.PROGRESS, thingsProgressHandler);
			_things.addEventListener(ThingTypeStorageEvent.FIND_PROGRESS, thingFindProgressHandler);
			_things.addEventListener(ErrorEvent.ERROR, thingsErrorHandler);
			
			
			_sprites = new SpriteStorage();
			_sprites.addEventListener(Event.COMPLETE, spritesCompleteHandler);
			_sprites.addEventListener(Event.CHANGE, spritesChangeHandler);
			_sprites.addEventListener(ProgressEvent.PROGRESS, spritesProgressHandler);
			_sprites.addEventListener(ErrorEvent.ERROR, spritesErrorHandler);
		}
		
		private function onLoadAssets(datPath:String,
									  sprPath:String,
									  datSignature:uint,
									  sprSignature:uint,
									  enableSpritesU32:Boolean,
									  enableAlphaChannel:Boolean) : void
		{
			var title : String;
			
			if (isNullOrEmpty(datPath))
			{
				throw new ArgumentError("Parameter datPath cannot be null or empty.");
			}
			
			if (isNullOrEmpty(sprPath))
			{
				throw new ArgumentError("Parameter sprPath cannot be null or empty.");
			}
			
			if (datSignature == 0 || sprSignature == 0)
			{
				throw new ArgumentError(getResourceString("obstrings", "invalidVersion"));
			}
			
			_datFile = new File(datPath);
			_sprFile = new File(sprPath);
			_version = AssetsVersion.getVersionBySignatures(datSignature, sprSignature);
			_enableSpritesU32 = enableSpritesU32;
			_enableAlphaChannel = enableAlphaChannel;
			
			title = getResourceString("obstrings", "loading");
			sendCommand(new ShowProgressBarCommand(ProgressBarID.DAT_SPR, title));
			
			createStorage();
			setSharedProperty("compiled", true);
			
			_things.load(_datFile, _version, _enableSpritesU32);
		}
		
		private function onGetAssetsInfo() : void
		{
			this.sendAssetsInfo();
		}
		
		private function onCompileAssets(datPath:String,
										 sprPath:String,
										 datSignature:uint,
										 sprSignature:uint,
										 enableSpritesU32:Boolean,
										 enableAlphaChannel:Boolean) : void
		{
			var dat : File;
			var spr : File;
			var version : AssetsVersion;
			var title : String;
			var forceCompile : Boolean;
			
			if (isNullOrEmpty(datPath))
			{
				throw new ArgumentError("Parameter datPath cannot be null or empty.");
			}
			
			if (isNullOrEmpty(sprPath))
			{
				throw new ArgumentError("Parameter sprPath cannot be null or empty.");
			}
			
			if (datSignature == 0 || sprSignature == 0)
			{
				throw new ArgumentError(getResourceString("obstrings", "invalidVersion"));
			}
			
			if (_things == null || !_things.loaded)
			{
				throw new Error(getResourceString("obstrings", "metadataNotLoaded"));
			}
			
			if (_sprites == null || !_sprites.loaded)
			{
				throw new Error(getResourceString("obstrings", "spritesNotLoaded"));
			}
			
			dat = new File(datPath);
			spr = new File(sprPath);
			version = AssetsVersion.getVersionBySignatures(datSignature, sprSignature);
			forceCompile = (_enableSpritesU32 != enableSpritesU32 || _enableAlphaChannel != enableAlphaChannel);
			
			title = getResourceString("obstrings", "compiling");
			sendCommand(new ShowProgressBarCommand(ProgressBarID.DAT_SPR, title));
			
			if (_things.compile(dat, version, enableSpritesU32) &&
				_sprites.compile(spr, version, enableSpritesU32, enableAlphaChannel, forceCompile))
			{
				assetsCompileComplete();
			}
			
			if (FileUtils.compare(dat, _datFile) && 
				FileUtils.compare(spr, _sprFile))
			{
				_enableSpritesU32 = enableSpritesU32;
				_enableAlphaChannel = enableAlphaChannel;
				sendAssetsInfo();
			}
		}
		
		private function onNewThing(category:String) : void
		{
			var thing : ThingType;
			var message : String;
			
			if (ThingCategory.getCategory(category) == null)
			{
				throw new Error(getResourceString("obstrings", "invalidCategory"));
			}
			
			thing = ThingUtils.createThing(category);
			if (_things.addThing(thing, category))
			{
				// Update preview and list.
				onGetThing(thing.id, category);
				
				// Send new thing message.
				message = StringUtil.substitute(getResourceString("obstrings", "addedNewThing"),
					getResourceString("strings", category),
					thing.id);
				sendCommand(new MessageCommand(message, "log"));
			}
		}
		
		private function onGetThing(id:uint, category:String) : void
		{
			var thing : ThingType;
			var spriteIndex : Vector.<uint>;
			var length : uint;
			var i :uint;
			var spriteId : uint;
			var pixels : ByteArray;
			var spriteData : SpriteData;
			var list : Vector.<SpriteData>;
			
			if (ThingCategory.getCategory(category) == null)
			{
				throw new Error(getResourceString("obstrings", "invalidCategory"));
			}
			
			thing = _things.getThingType(id,  category);
			if (thing == null)
			{
				throw new Error(StringUtil.substitute(getResourceString("obstrings", "thingNotFound"),
					getResourceString("strings", category), id));
			}
			
			list = new Vector.<SpriteData>();
			spriteIndex = thing.spriteIndex;
			length = spriteIndex.length;
			for (i = 0; i < length; i++)
			{
				spriteId = spriteIndex[i];
				pixels = _sprites.getPixels(spriteId);
				if (pixels == null)
				{
					throw new Error(StringUtil.substitute(getResourceString("obstrings", "spriteNotFound"), spriteId));
				}
				
				spriteData = new SpriteData();
				spriteData.id = spriteId;
				spriteData.pixels = pixels;
				list.push(spriteData);
			}
			
			sendCommand(new SetThingCommand(thing, list));
		}
		
		private function onChangeThing(thing:ThingType, sprites:Vector.<SpriteData>) : void
		{
			var length : uint;
			var i : uint;
			var spriteData : SpriteData;
			var spriteId : uint;
			var message : String;
			var ids : Array;
			
			ids = [];
			length = thing.spriteIndex.length;
			for (i = 0; i < length; i++)
			{
				spriteData = sprites[i];
				spriteId = thing.spriteIndex[i];
				if (spriteId != 0xFFFFFF)
				{
					if (!_sprites.hasSpriteId(spriteId))
					{
						message = getResourceString("obstrings", "spriteNotFound");
						throw new Error(StringUtil.substitute(message, spriteId));
					}
				}
				else 
				{
					if (spriteData.isEmpty())
					{
						thing.spriteIndex[i] = 0;
					}
					else if (_sprites.addSprite(spriteData.pixels))
					{
						ids[i] = _sprites.spritesCount;
						thing.spriteIndex[i] = _sprites.spritesCount;
					}
				}
			}
			
			if (ids.length > 0)
			{
				if (ids.length == 1)
				{
					message = StringUtil.substitute(getResourceString("obstrings", "addedSprite"), _sprites.spritesCount);
				}
				else
				{
					message = StringUtil.substitute(getResourceString("obstrings", "addedSprites"), ids);
				}
				
				// Set sprite list to last sprite.
				this.sendSpriteList(_sprites.spritesCount);
				
				// Send sprites added message.
				sendCommand(new MessageCommand(message, "log"));
			}
			
			if (_things.replace(thing, thing.category, thing.id))
			{
				// Update preview and list.
				onGetThing(thing.id, thing.category);
				onGetThingList(thing.id, thing.category);
				
				// Send change message
				message = StringUtil.substitute(getResourceString("obstrings", "savedThing"),
					getResourceString("strings", thing.category), thing.id);
				sendCommand(new MessageCommand(message, "log"));
			}
		}
		
		private function onImportThing(thing:ThingType, sprites:Vector.<SpriteData>, replaceId:uint) : void
		{
			var done : Boolean;
			var length : uint;
			var i :uint;
			var spriteId : uint;
			var pixels : ByteArray;
			var spritesAdded : Array;
			var message : String;
			
			if (thing == null) 
			{
				throw new ArgumentError("Parameter thing cannot be null.");
			}
			
			if (sprites == null) 
			{
				throw new ArgumentError("Parameter sprites cannot be null.");
			}
			
			if (replaceId != 0)
			{
				done = _things.replace(thing, thing.category, replaceId);
				message = getResourceString("obstrings", "replacedThing");
			}
			else 
			{
				done = _things.addThing(thing, thing.category);
				message = getResourceString("obstrings", "addedNewThing");
			}
			
			// Add sprites
			spritesAdded = [];
			length = sprites.length;
			for (i = 0; i < length; i++)
			{
				pixels = sprites[i].pixels;
				spriteId = thing.spriteIndex[i];
				
				// Only add if sprite are not equal.
				if (!_sprites.compare(spriteId, pixels))
				{
					if (_sprites.addSprite(pixels))
					{
						thing.spriteIndex[i] = _sprites.spritesCount;
						spritesAdded.push(_sprites.spritesCount);
					}
				}
			}
			
			if (done)
			{
				// Update preview.
				onGetThing(thing.id, thing.category);
				if (replaceId != 0)
				{
					onGetThingList(thing.id, thing.category);
				}
				
				// Send import message.
				message = StringUtil.substitute(message, getResourceString("strings", thing.category), thing.id);
				sendCommand(new MessageCommand(message, "log"));
				
				if (spritesAdded.length > 0)
				{
					if (spritesAdded.length == 1)
					{
						message = StringUtil.substitute(getResourceString("obstrings", "addedSprite"), _sprites.spritesCount);
					}
					else
					{
						message = StringUtil.substitute(getResourceString("obstrings", "addedSprites"), spritesAdded);
					}
					
					// Set sprite list to last sprite.
					this.sendSpriteList(_sprites.spritesCount);
					
					// Send sprites added message.
					sendCommand(new MessageCommand(message, "log"));
				}
			}
		}
		
		private function onImportThingFiles(files:Array) : void
		{
			var list : Array;
			var length : uint;
			var i : uint;
			var loader : ThingDataLoader;
			
			list = [];
			length = files.length;
			for (i = 0; i < length; i++)
			{
				list[i] = new File(files[i]);
			}
			
			sendCommand(new ShowProgressBarCommand(ProgressBarID.DEFAULT,
				getResourceString("obstrings", "loadingFiles")));
			
			loader = new ThingDataLoader();
			loader.addEventListener(ProgressEvent.PROGRESS, importThingProgressHandler);
			loader.addEventListener(Event.COMPLETE, importThingCompleteHandler);
			loader.loadFiles(list);
		}
		
		private function onDuplicateThing(id:uint, category:String) : void
		{
			var thing : ThingType;
			var copy : ThingType;
			var message : String;
			
			if (ThingCategory.getCategory(category) == null)
			{
				throw new Error(getResourceString("obstrings", "invalidCategory"));
			}
			
			thing = _things.getThingType(id, category);
			if (thing == null)
			{
				throw new Error(StringUtil.substitute(getResourceString("obstrings", "thingNotFound"),
					getResourceString("strings", category),
					id));
			}
			
			copy = ThingUtils.copyThing(thing);
			if (_things.addThing(copy, category))
			{
				// Update preview.
				onGetThing(copy.id, category);
				
				// Send duplicated thing message.
				message = StringUtil.substitute(getResourceString("obstrings", "duplicatedThing"),
					getResourceString("strings", category),
					id,
					copy.id);
				sendCommand(new MessageCommand(message, "log"));
			}
		}
		
		private function onRemoveThing(id:uint, category:String) : void
		{
			var message : String;
			var count : uint;
			var sendId : uint;
			
			if (_things.removeThing(id, category))
			{
				count = _things.getCategoryCount(category);
				sendId = id > count ? count : id;
				
				// Update preview and list.
				onGetThing(sendId, category);
				onGetThingList(sendId, category);
				
				message = StringUtil.substitute(getResourceString("obstrings", "removedThing"),
					getResourceString("strings", category),
					id);
				sendCommand(new MessageCommand(message, "log"));
			}
		}
		
		private function onFindThing(category:String, properties:Vector.<ThingProperty>) : void
		{
			var list : Array;
			var things : Array;
			var length : uint;
			var i : uint;
			var listItem : ThingListItem;
			
			list = [];
			things = _things.findThingTypeByProperties(category, properties);
			length = things.length;
			for (i = 0; i < length; i++)
			{
				listItem = new ThingListItem();
				listItem.thing = things[i];
				listItem.pixels = getBitmapPixels(listItem.thing);
				list[i] = listItem;
			}
			sendCommand(new FindResultCommand(list));
		}
		
		private function onGetThingList(target:uint, category:String) : void
		{
			this.sendThingList(target, category);
		}
		
		private function onGetSpriteList(target:uint) : void
		{
			this.sendSpriteList(target);
		}
		
		private function onReplaceSprite(id:uint, pixels:ByteArray) : void
		{
			var message : String;
			
			if (id == 0) 
			{
				throw new ArgumentError(StringUtil.substitute(getResourceString("obstrings", "invalidSpriteId"), id));
			}
			
			if (pixels == null) 
			{
				throw new ArgumentError("Parameter pixels cannot be null.");
			}
			
			if (_sprites.replaceSprite(id, pixels))
			{
				message = StringUtil.substitute(getResourceString("obstrings", "replacedSprite"), id);
				sendCommand(new MessageCommand(message, "log"));
				this.sendSpriteList(id);
			}
		}
		
		private function onImportSprites(pixelsList:Vector.<ByteArray>) : void
		{
			var ids : Array;
			var pixels : ByteArray;
			var length : uint;
			var i : uint;
			var message : String;
			
			if (pixelsList == null) 
			{
				throw new ArgumentError("Parameter pixelsList cannot be null.");
			}
			
			// Temporarily remove change events.
			_sprites.removeEventListener(Event.CHANGE, spritesChangeHandler);
			
			ids = [];
			length = pixelsList.length;
			for (i = 0; i < length; i++)
			{
				if (!checkSpriteLimite())
				{
					break;
				}
				
				pixels = pixelsList[i];
				if (_sprites.addSprite(pixels))
				{
					ids[i] = _sprites.spritesCount;
				}
			}
			
			// Again add change events.
			_sprites.addEventListener(Event.CHANGE, spritesChangeHandler);
			
			length = ids.length;
			(length > 0)
			{
				if (length == 1)
				{
					message = StringUtil.substitute(getResourceString("obstrings", "addedSprite"), _sprites.spritesCount);
				}
				else
				{
					message = StringUtil.substitute(getResourceString("obstrings", "addedSprites"), ids);
				}
				
				sendAssetsInfo();
				sendSpriteList(_sprites.spritesCount);
				sendCommand(new MessageCommand(message, "log"));
			}
		}
		
		private function onNewSprite() : void
		{
			var sprite : BitmapData;
			var message : String;
			
			if (!checkSpriteLimite())
			{
				return;
			}
			
			sprite = new BitmapData(Sprite.SPRITE_PIXELS, Sprite.SPRITE_PIXELS, true, 0x00000000);
			if (_sprites.addSprite(sprite.getPixels(sprite.rect)))
			{
				message = StringUtil.substitute(getResourceString("obstrings", "addedSprite"), _sprites.spritesCount);
				this.sendSpriteList(_sprites.spritesCount);
				sendCommand(new MessageCommand(message, "log"));
			}
		}
		
		private function onRemoveSprites(list:Vector.<uint>) : void
		{
			var length : uint;
			var i : uint;
			var id : uint;
			var message : String;
			
			if (list == null)
			{
				throw new ArgumentError("Parameter list cannot be null.");
			}
			
			length = list.length;
			for (i = 0; i < length; i++)
			{
				id = list[i];
				if (id != 0)
				{
					_sprites.removeSprite(id);
				}
			}
			
			id = Math.max(0, list[length - 1] - 1);
			sendSpriteList(id);
			
			if (length > 1)
			{
				message = getResourceString("obstrings", "removeSprites");
			}
			else 
			{
				message = getResourceString("obstrings", "removeSprite");
			}
			sendCommand(new MessageCommand(StringUtil.substitute(message, list), "log"));
		}
		
		private function assetsLoadComplete() : void
		{
			sendCommand(new HideProgressBarCommand(ProgressBarID.DAT_SPR));
			sendCommand(new Command(CommandType.LOAD_COMPLETE));
			sendCommand(new MessageCommand(getResourceString("obstrings", "loadComplete"),
				getResourceString("strings", "info")));
		}
		
		private function assetsCompileComplete() : void
		{
			setSharedProperty("compiled", true);
			sendCommand(new HideProgressBarCommand(ProgressBarID.DAT_SPR));
			sendCommand(new MessageCommand(getResourceString("obstrings", "compileComplete"),
				getResourceString("strings", "info")));
		}
		
		public function sendAssetsInfo() : void
		{
			var info : AssetsInfo;
			
			if (_things == null || !_things.loaded)
			{
				throw new Error(getResourceString("obstrings", "metadataNotLoaded"));
			}
			
			if (_sprites == null || !_sprites.loaded)
			{
				throw new Error(getResourceString("obstrings", "spritesNotLoaded"));
			}
			
			info = new AssetsInfo();
			info.version = _version.value;
			info.datSignature = _things.signature;
			info.minItemId = ThingTypeStorage.MIN_ITEM_ID;
			info.maxItemId = _things.itemsCount;
			info.minOutfitId = ThingTypeStorage.MIN_OUTFIT_ID;
			info.maxOutfitId = _things.outfitsCount;
			info.minEffectId = ThingTypeStorage.MIN_EFFECT_ID;
			info.maxEffectId = _things.effectsCount;
			info.minMissileId = ThingTypeStorage.MIN_MISSILE_ID;
			info.maxMissileId = _things.missilesCount;
			info.sprSignature = _sprites.signature;
			info.minSpriteId = 0;
			info.maxSpriteId = _sprites.spritesCount;
			info.extended = (_enableSpritesU32 || _version.value >= 960);
			info.transparency = _enableAlphaChannel;
			
			sendCommand(new SetAssetsInfoCommand(info));
		}
		
		private function sendThingList(target:uint, category:String) : void
		{
			var first : uint;
			var last : uint;
			var min : uint;
			var max : uint;
			var list : Vector.<ThingListItem>;
			var i : uint;
			var thing : ThingType;
			var listItem : ThingListItem;
			var diff : uint;
			
			if (_things == null || !_things.loaded)
			{
				throw new Error(getResourceString("obstrings", "metadataNotLoaded"));
			}
			
			first = _things.getCategoryMinId(category);
			last = _things.getCategoryCount(category);
			min = Math.max(first, ObUtils.hundredFloor(target));
			diff = (category != ThingCategory.ITEM && min == first) ? 1 : 0;
			max = Math.min((min - diff) + 99, last);
			list = new Vector.<ThingListItem>();
			
			for (i = min; i <= max; i++)
			{
				thing = _things.getThingType(i, category);
				if (thing == null)
				{
					throw new Error(StringUtil.substitute(getResourceString("obstrings", "thingNotFound"),
						getResourceString("strings", category), i));
				}
				
				listItem = new ThingListItem();
				listItem.thing = thing;
				listItem.pixels = getBitmapPixels(thing);
				list.push(listItem);
			}
			
			sendCommand(new SetThingListCommand(target, min, max, list));
		}
		
		private function sendSpriteList(target:uint) : void
		{
			var first : uint;
			var last : uint;
			var min : uint;
			var max : uint;
			var list : Vector.<SpriteData>;
			var i : int;
			var pixels : ByteArray;
			var spriteData : SpriteData;
			
			if (_sprites == null || !_sprites.loaded)
			{
				throw new Error(getResourceString("obstrings", "spritesNotLoaded"));
			}
			
			first = 0;
			last = _sprites.spritesCount;
			min = Math.max(first, ObUtils.hundredFloor(target));
			max = Math.min(min + 99, last);
			list = new Vector.<SpriteData>();
			
			for (i = min; i <= max; i++)
			{
				pixels = _sprites.getPixels(i);
				if (pixels == null)
				{
					throw new Error(StringUtil.substitute(getResourceString("obstrings", "spriteNotFound"), i));
				}
				
				spriteData = new SpriteData();
				spriteData.id = i;
				spriteData.pixels = pixels;
				list.push(spriteData);
			}
			
			sendCommand(new SetSpriteListCommand(target, min, max, list));
		}
		
		private function sendError(message:String, stack:String = "", id:uint = 0) : void
		{
			if (!isNullOrEmpty(message))
			{
				sendCommand(new ErrorCommand(message, stack, id));
			}
		}
		
		private function checkSpriteLimite() : Boolean
		{
			if (_sprites.isFull && !_enableSpritesU32)
			{
				sendCommand(new MessageCommand(getResourceString("obstrings", "spritesLimitReached"),
					getResourceString("strings", "warning")));
				return false;
			}
			return true;
		}
		
		private function getBitmapPixels(thing:ThingType) : ByteArray
		{
			var size : uint;
			var width : uint;
			var height : uint;
			var layers : uint;
			var w : uint;
			var h : uint;
			var x : uint;
			var l : uint;
			var bitmap : BitmapData;
			var index : uint;
			var px : int;
			var py : int;
			
			size = Sprite.SPRITE_PIXELS;
			width = thing.width;
			height = thing.height;
			layers = thing.layers;
			bitmap = new BitmapData(width * size, height * size, true, 0xFF636363);
			
			if (thing.category == ThingCategory.OUTFIT)
			{
				layers = 1;
				x = thing.frames > 1 ? 2 : 0;
			}
			
			for (l = 0; l < layers; l++)
			{
				for (w = 0; w < width; w++)
				{
					for (h = 0; h < height; h++)
					{
						index = ThingData.getSpriteIndex(thing, w, h, l, x, 0, 0, 0);
						px = (width - w - 1) * size;
						py = (height - h - 1) * size;
						_sprites.copyPixels(thing.spriteIndex[index], bitmap, px, py);
					}
				}
			}
			
			return bitmap.getPixels(bitmap.rect);
		}
		
		//--------------------------------------
		// Event Handlers
		//--------------------------------------
		
		protected function thingsCompleteHandler(event:Event) : void
		{
			if (_sprites != null && !_sprites.loaded)
			{
				_sprites.load(_sprFile, _version, _enableSpritesU32, _enableAlphaChannel);
			}
		}
		
		protected function thingsChangeHandler(event:Event) : void
		{
			setSharedProperty("compiled", false);
			sendAssetsInfo();
		}
		
		protected function thingsProgressHandler(event:ProgressEvent) : void
		{
			sendProgress(ProgressBarID.DAT, event.bytesLoaded, event.bytesTotal);
		}
		
		protected function thingsErrorHandler(event:ErrorEvent) : void
		{
			// Try load as extended.
			if (!_enableSpritesU32)
			{
				_error = new ErrorCommand(event.text, "", event.errorID);
				onLoadAssets(_datFile.nativePath,
					_sprFile.nativePath,
					_version.datSignature,
					_version.sprSignature,
					true,
					_enableAlphaChannel);
			}
			else 
			{
				if (_error != null)
				{
					sendError(_error.args[0], _error.args[1], _error.args[2]);
					_error = null;
				}
				else 
				{
					sendError(event.text, "", event.errorID);
				}
			}
		}	
		
		protected function importThingProgressHandler(event:ProgressEvent) : void
		{
			sendProgress(ProgressBarID.DEFAULT, event.bytesLoaded, event.bytesTotal);
		}
		
		protected function importThingCompleteHandler(event:Event) : void
		{
			var thingDataList : Vector.<ThingData>;
			var dataLength : uint;
			var d : uint;
			var thing : ThingType;
			var sprites : Vector.<SpriteData>;
			var spriteLength : uint;
			var s : uint;
			var spriteId : uint;
			var pixels : ByteArray;
			var spritesAdded : Array;
			var message : String;
			
			// Close current instance of DefaultProgressBar
			sendCommand(new HideProgressBarCommand(ProgressBarID.DEFAULT));
			
			// Open new instance of DefaultProgressBar
			sendCommand(new ShowProgressBarCommand(ProgressBarID.DEFAULT,
				getResourceString("obstrings", "importingObjects")));
			
			// Temporarily remove change events.
			_things.removeEventListener(Event.CHANGE, thingsChangeHandler);
			_sprites.removeEventListener(Event.CHANGE, spritesChangeHandler);
			
			thingDataList = ThingDataLoader(event.target).thingDataList;
			dataLength = thingDataList.length;
			spritesAdded = [];
			
			for (d = 0; d < dataLength; d++)
			{
				// Add thing
				thing = thingDataList[d].thing;
				if (_things.addThing(thing, thing.category))
				{
					// Send import message.
					message = getResourceString("obstrings", "addedNewThing");
					message = StringUtil.substitute(message, getResourceString("strings", thing.category), thing.id);
					sendCommand(new MessageCommand(message, "log"));
				}
				
				// Add sprites
				sprites = thingDataList[d].sprites;
				spriteLength = sprites.length;
				
				for (s = 0; s < spriteLength; s++)
				{
					pixels = sprites[s].pixels;
					spriteId = thing.spriteIndex[s];
					
					// Only add if sprite are not equal.
					if (!_sprites.compare(spriteId, pixels))
					{
						if (_sprites.addSprite(pixels))
						{
							thing.spriteIndex[s] = _sprites.spritesCount;
							spritesAdded.push(_sprites.spritesCount);
						}
					}
				}
				
				sendProgress(ProgressBarID.DEFAULT, d, dataLength);
			}
			
			// Again add change events.
			_things.addEventListener(Event.CHANGE, thingsChangeHandler);
			_sprites.addEventListener(Event.CHANGE, spritesChangeHandler);
			
			// Update all.
			onGetAssetsInfo();
			onGetThing(thing.id, thing.category);
			onGetThingList(thing.id, thing.category);
			onGetSpriteList(_sprites.spritesCount);
			
			// Send sprites ids to log.
			if (spritesAdded.length > 0)
			{
				if (spritesAdded.length == 1)
				{
					message = StringUtil.substitute(getResourceString("obstrings", "addedSprite"), _sprites.spritesCount);
				}
				else
				{
					message = StringUtil.substitute(getResourceString("obstrings", "addedSprites"), spritesAdded);
				}
				
				sendCommand(new MessageCommand(message, "log"));
			}
			
			// Close current instance of DefaultProgressBar
			sendCommand(new HideProgressBarCommand(ProgressBarID.DEFAULT));
		}
		
		protected function thingFindProgressHandler(event:ThingTypeStorageEvent) : void
		{
			sendProgress(ProgressBarID.FIND_THING, event.loaded, event.total);
		}
		
		protected function spritesCompleteHandler(event:Event) : void
		{
			if (_things != null && _things.loaded)
			{
				this.assetsLoadComplete();
			}
		}
		
		protected function spritesChangeHandler(event:Event) : void
		{
			setSharedProperty("compiled", false);
			sendAssetsInfo();
		}
		
		protected function spritesProgressHandler(event:ProgressEvent) : void
		{
			sendProgress(ProgressBarID.SPR, event.bytesLoaded, event.bytesTotal);
		}
		
		protected function spritesErrorHandler(event:ErrorEvent) : void
		{
			sendError(event.text, "", event.errorID);
		}
	}
}
