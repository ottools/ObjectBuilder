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
	
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	
	import nail.objectbuilder.commands.CommandType;
	import nail.objectbuilder.commands.ErrorCommand;
	import nail.objectbuilder.commands.FindResultCommand;
	import nail.objectbuilder.commands.MessageCommand;
	import nail.objectbuilder.commands.SetAssetsInfoCommand;
	import nail.objectbuilder.commands.SetSpriteListCommand;
	import nail.objectbuilder.commands.SetThingCommand;
	import nail.objectbuilder.commands.SetThingListCommand;
	import nail.objectbuilder.utils.ObUtils;
	import nail.otlib.assets.AssetsInfo;
	import nail.otlib.assets.AssetsVersion;
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
	
	[ResourceBundle("controls")]
	
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
		private var _resources : IResourceManager;
		
		//--------------------------------------------------------------------------
		//
		// CONSTRUCTOR
		//
		//--------------------------------------------------------------------------
		
		public function ObjectBuilderWorker()
		{
			_resources = ResourceManager.getInstance();
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
			registerCommand(CommandType.DUPLICATE_THING, onDuplicateThing);
			registerCommand(CommandType.REMOVE_THING, onRemoveThing);
			registerCommand(CommandType.FIND_THING, onFindThing);
			registerCommand(CommandType.GET_THING_LIST, onGetThingList);
			registerCommand(CommandType.GET_SPRITE_LIST, onGetSpriteList);
			registerCommand(CommandType.REPLACE_SPRITE, onReplaceSprite);
			registerCommand(CommandType.IMPORT_SPRITE, onImportSprite);
			registerCommand(CommandType.NEW_SPRITE, onNewSprite);
			registerCommand(CommandType.REMOVE_SPRITES, onRemoveSprites);
		}
		
		//--------------------------------------
		// Private
		//--------------------------------------
		
		private function onCreateNewAssets(versionValue:uint, enableSpritesU32:Boolean) : void
		{
			var version : AssetsVersion;
			var thing : ThingType;
			
			if (versionValue == 0)
			{
				throw new ArgumentError(_resources.getString("controls", "error.invalid-version"));
			}
			
			version = AssetsVersion.getVersionByValue(versionValue);
			if (version == null)
			{
				throw new Error(StringUtil.substitute(_resources.getString("controls", "error.unsupported-version"), versionValue));
			}
			
			_version = version;
			_enableSpritesU32 = enableSpritesU32;
			
			createStorage();
			
			if (!_sprites.createNew(version, enableSpritesU32))
			{
				throw new Error(_resources.getString("controls", "error.not-create-spr"));
			}
			
			// Create things.
			if (!_things.createNew(version))
			{
				throw new Error(_resources.getString("controls", "error.not-create-dat"));
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
			_things.addEventListener(ErrorEvent.ERROR, thingsErrorHandler);
			
			
			_sprites = new SpriteStorage();
			_sprites.addEventListener(Event.COMPLETE, spritesCompleteHandler);
			_sprites.addEventListener(Event.CHANGE, spritesChangeHandler);
			_sprites.addEventListener(ProgressEvent.PROGRESS, spritesProgressHandler);
			_sprites.addEventListener(ErrorEvent.ERROR, spritesErrorHandler);
		}
		
		private function onLoadAssets(datPath:String, sprPath:String, versionValue:uint, enableSpritesU32:Boolean) : void
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
			
			if (versionValue == 0)
			{
				throw new ArgumentError(_resources.getString("controls", "error.invalid-version"));
			}
			
			_datFile = new File(datPath);
			_sprFile = new File(sprPath);
			_version = AssetsVersion.getVersionByValue(versionValue);
			_enableSpritesU32 = enableSpritesU32;
			
			title = _resources.getString("controls", "log.loading");
			sendCommand(new Command(CommandType.SHOW_PROGRESS_BAR, title));
			
			createStorage();
			setSharedProperty("compiled", true);
			
			_things.load(_datFile, _version, _enableSpritesU32);
		}
		
		private function onGetAssetsInfo() : void
		{
			this.sendAssetsInfo();
		}
		
		private function onCompileAssets(datPath:String, sprPath:String, versionValue:uint, enableSpritesU32:Boolean) : void
		{
			var dat : File;
			var spr : File;
			var version : AssetsVersion;
			var title : String;
			
			if (isNullOrEmpty(datPath))
			{
				throw new ArgumentError("Parameter datPath cannot be null or empty.");
			}
			
			if (isNullOrEmpty(sprPath))
			{
				throw new ArgumentError("Parameter sprPath cannot be null or empty.");
			}
			
			if (versionValue == 0)
			{
				throw new ArgumentError(_resources.getString("controls", "error.invalid-version"));
			}
			
			if (_things == null || !_things.loaded)
			{
				throw new Error(_resources.getString("controls", "error.metadata-not-loaded"));
			}
			
			if (_sprites == null || !_sprites.loaded)
			{
				throw new Error(_resources.getString("controls", "error.sprites-not-loaded"));
			}
			
			dat = new File(datPath);
			spr = new File(sprPath);
			version = AssetsVersion.getVersionByValue(versionValue);
			
			title = _resources.getString("controls", "log.compiling");
			sendCommand(new Command(CommandType.SHOW_PROGRESS_BAR, title));
			
			if (_things.compile(dat, version, enableSpritesU32) &&
				_sprites.compile(spr, version, enableSpritesU32, this._enableSpritesU32 != enableSpritesU32))
			{
				assetsCompileComplete();
			}
			
			if (FileUtils.compare(dat, _datFile) && 
				FileUtils.compare(spr, _sprFile))
			{
				_enableSpritesU32 = enableSpritesU32;
				sendAssetsInfo();
			}
		}
		
		private function onNewThing(category:String) : void
		{
			var thing : ThingType;
			var message : String;
			
			if (ThingCategory.getCategory(category) == null)
			{
				throw new Error(_resources.getString("controls", "error.invalid-category"));
			}
			
			thing = ThingUtils.createThing(category);
			if (_things.addThing(thing, category))
			{
				// Update preview and list.
				onGetThing(thing.id, category);
				
				// Send new thing message.
				message = StringUtil.substitute(_resources.getString("controls", "log.added-new-thing"),
					ObUtils.toLocale(category),
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
				throw new Error(_resources.getString("controls", "error.invalid-category"));
			}
			
			thing = _things.getThingType(id,  category);
			if (thing == null)
			{
				throw new Error(StringUtil.substitute(_resources.getString("controls", "error.thing-not-found"),
					ObUtils.toLocale(category), id));
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
					throw new Error(StringUtil.substitute(_resources.getString("controls", "error.sprite-not-found"), spriteId));
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
						message = _resources.getString("controls", "error.sprite-not-found");
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
					message = StringUtil.substitute(_resources.getString("controls", "log.added-sprite"), _sprites.spritesCount);
				}
				else
				{
					message = StringUtil.substitute(_resources.getString("controls", "log.added-sprites"), ids);
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
				message = StringUtil.substitute(_resources.getString("controls", "log.saved-thing"),
					ObUtils.toLocale(thing.category), thing.id);
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
				message = _resources.getString("controls", "log.replaced-thing");
			}
			else 
			{
				done = _things.addThing(thing, thing.category);
				message = _resources.getString("controls", "log.added-new-thing");
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
				
				// Send import message.
				message = StringUtil.substitute(message, ObUtils.toLocale(thing.category), thing.id);
				sendCommand(new MessageCommand(message, "log"));
				
				if (spritesAdded.length > 0)
				{
					if (spritesAdded.length == 1)
					{
						message = StringUtil.substitute(_resources.getString("controls", "log.added-sprite"), _sprites.spritesCount);
					}
					else
					{
						message = StringUtil.substitute(_resources.getString("controls", "log.added-sprites"), spritesAdded);
					}
					
					// Set sprite list to last sprite.
					this.sendSpriteList(_sprites.spritesCount);
					
					// Send sprites added message.
					sendCommand(new MessageCommand(message, "log"));
				}
			}
		}
		
		private function onDuplicateThing(id:uint, category:String) : void
		{
			var thing : ThingType;
			var copy : ThingType;
			var message : String;
			
			if (ThingCategory.getCategory(category) == null)
			{
				throw new Error(_resources.getString("controls", "error.invalid-category"));
			}
			
			thing = _things.getThingType(id, category);
			if (thing == null)
			{
				throw new Error(StringUtil.substitute(_resources.getString("controls", "error.thing-not-found"),
					ObUtils.toLocale(category),
					id));
			}
			
			copy = ThingUtils.copyThing(thing);
			if (_things.addThing(copy, category))
			{
				// Update preview.
				onGetThing(copy.id, category);
				
				// Send duplicated thing message.
				message = StringUtil.substitute(_resources.getString("controls", "log.duplicated-thing"),
					ObUtils.toLocale(category),
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
				
				message = StringUtil.substitute(_resources.getString("controls", "log.removed-thing"),
					ObUtils.toLocale(category),
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
				throw new ArgumentError(StringUtil.substitute(_resources.getString("controls", "error.invalid-sprite-id"), id));
			}
			
			if (pixels == null) 
			{
				throw new ArgumentError("Parameter pixels cannot be null.");
			}
			
			if (_sprites.replaceSprite(id, pixels))
			{
				message = StringUtil.substitute(_resources.getString("controls", "log.replaced-sprite"), id);
				sendCommand(new MessageCommand(message, "log"));
				this.sendSpriteList(id);
			}
		}
		
		private function onImportSprite(pixelsList:Vector.<ByteArray>) : void
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
			
			length = ids.length;
			(length > 0)
			{
				if (length == 1)
				{
					message = StringUtil.substitute(_resources.getString("controls", "log.added-sprite"), _sprites.spritesCount);
				}
				else
				{
					message = StringUtil.substitute(_resources.getString("controls", "log.added-sprites"), ids);
				}
				
				this.sendSpriteList(_sprites.spritesCount);
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
				message = StringUtil.substitute(_resources.getString("controls", "log.added-sprite"), _sprites.spritesCount);
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
				message = _resources.getString("controls", "log.remove-sprites");
			}
			else 
			{
				message = _resources.getString("controls", "log.remove-sprite");
			}
			sendCommand(new MessageCommand(StringUtil.substitute(message, list), "log"));
		}
		
		private function assetsLoadComplete() : void
		{
			sendCommand(new Command(CommandType.HIDE_PROGRESS_BAR));
			sendCommand(new Command(CommandType.LOAD_COMPLETE));
			sendCommand(new MessageCommand(_resources.getString("controls", "log.load-complete"), "Info"));
		}
		
		private function assetsCompileComplete() : void
		{
			setSharedProperty("compiled", true);
			sendCommand(new Command(CommandType.HIDE_PROGRESS_BAR));
			sendCommand(new MessageCommand(_resources.getString("controls", "log.compile-complete"), "Info"));
		}
		
		public function sendAssetsInfo() : void
		{
			var info : AssetsInfo;
			
			if (_things == null || !_things.loaded)
			{
				throw new Error(_resources.getString("controls", "error.metadata-not-loaded"));
			}
			
			if (_sprites == null || !_sprites.loaded)
			{
				throw new Error(_resources.getString("controls", "error.sprites-not-loaded"));
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
			
			if (_things == null || !_things.loaded)
			{
				throw new Error(_resources.getString("controls", "error.metadata-not-loaded"));
			}
			
			first = _things.getCategoryMinId(category);
			last = _things.getCategoryCount(category);
			min = Math.max(first, target - 50);
			max = min == first ? Math.min(last, target + 100) : Math.min(last, target + 50);
			min = max == last ? Math.max(first, min - 50) : min;
			list = new Vector.<ThingListItem>();
			
			for (i = min; i <= max; i++)
			{
				thing = _things.getThingType(i, category);
				if (thing == null)
				{
					throw new Error("thing not found");
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
			var min : uint;
			var max : uint
			var list : Vector.<SpriteData>;
			var i : int;
			var pixels : ByteArray;
			var spriteData : SpriteData;
			
			if (_sprites == null || !_sprites.loaded)
			{
				throw new Error(_resources.getString("controls", "error.sprites-not-loaded"));
			}
			
			min = Math.max(0, target - 50);
			max = min == 0 ? Math.min(_sprites.spritesCount, target + 100) : Math.min(_sprites.spritesCount, target + 50);
			min = max == _sprites.spritesCount ? Math.max(0, min - 50) : min;
			list = new Vector.<SpriteData>();
			
			for (i = min; i <= max; i++)
			{
				pixels = _sprites.getPixels(i);
				if (pixels == null)
				{
					throw new Error(StringUtil.substitute(_resources.getString("controls", "error.sprite-not-found"), i));
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
				sendCommand(new MessageCommand(_resources.getString("controls", "alert.sprites-limit-reached"),
					_resources.getString("controls", "label.warning")));
				return false;
			}
			return true;
		}
		
		private function getBitmapPixels(thing:ThingType) : ByteArray
		{
			var size : uint;
			var width : uint;
			var height : uint;
			var w : uint;
			var h : uint;
			var bitmap : BitmapData;
			var index : uint;
			var px : int;
			var py : int;
			
			size = Sprite.SPRITE_PIXELS;
			width = thing.width;
			height = thing.height;
			bitmap = new BitmapData(width * size, height * size, true, 0xFF636363);
			
			for (w = 0; w < width; w++)
			{
				for (h = 0; h < height; h++)
				{
					index = ThingData.getSpriteIndex(thing, w, h, 0, 0, 0, 0, 0);
					px = (width - w - 1) * size;
					py = (height - h - 1) * size;
					_sprites.copyPixels(thing.spriteIndex[index], bitmap, px, py);
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
				_sprites.load(_sprFile, _version, _enableSpritesU32);
			}
		}
		
		protected function thingsChangeHandler(event:Event) : void
		{
			setSharedProperty("compiled", false);
			sendAssetsInfo();
		}
		
		protected function thingsProgressHandler(event:ProgressEvent) : void
		{
			sendProgress(1, event.bytesLoaded, event.bytesTotal);
		}
		
		protected function thingsErrorHandler(event:ErrorEvent) : void
		{
			sendError(event.text, "", event.errorID);
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
			sendProgress(2, event.bytesLoaded, event.bytesTotal);
		}
		
		protected function spritesErrorHandler(event:ErrorEvent) : void
		{
			sendError(event.text, "", event.errorID);
		}
	}
}
