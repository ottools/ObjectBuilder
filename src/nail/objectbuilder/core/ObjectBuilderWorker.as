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

package nail.objectbuilder.core
{
    import flash.display.BitmapData;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.filesystem.File;
    import flash.geom.Rectangle;
    import flash.net.registerClassAlias;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    
    import nail.codecs.ImageCodec;
    import nail.codecs.ImageFormat;
    import nail.errors.NullArgumentError;
    import nail.errors.NullOrEmptyArgumentError;
    import nail.logging.Log;
    import nail.objectbuilder.commands.CommandType;
    import nail.objectbuilder.commands.FindResultCommand;
    import nail.objectbuilder.commands.HideProgressBarCommand;
    import nail.objectbuilder.commands.NeedToReloadCommand;
    import nail.objectbuilder.commands.ProgressBarID;
    import nail.objectbuilder.commands.ProgressCommand;
    import nail.objectbuilder.commands.ShowProgressBarCommand;
    import nail.objectbuilder.commands.files.SetFilesInfoCommand;
    import nail.objectbuilder.commands.sprites.SetSpriteListCommand;
    import nail.objectbuilder.commands.things.SetThingDataCommand;
    import nail.objectbuilder.commands.things.SetThingListCommand;
    import nail.objectbuilder.utils.ObUtils;
    import nail.otlib.core.Version;
    import nail.otlib.core.Versions;
    import nail.otlib.events.ProgressEvent;
    import nail.otlib.loaders.PathHelper;
    import nail.otlib.loaders.SpriteDataLoader;
    import nail.otlib.loaders.ThingDataLoader;
    import nail.otlib.sprites.Sprite;
    import nail.otlib.sprites.SpriteData;
    import nail.otlib.sprites.SpriteStorage;
    import nail.otlib.things.ThingCategory;
    import nail.otlib.things.ThingData;
    import nail.otlib.things.ThingProperty;
    import nail.otlib.things.ThingType;
    import nail.otlib.things.ThingTypeStorage;
    import nail.otlib.utils.ChangeResult;
    import nail.otlib.utils.OTFormat;
    import nail.otlib.utils.ThingListItem;
    import nail.otlib.utils.ThingUtils;
    import nail.resources.Resources;
    import nail.utils.FileUtil;
    import nail.utils.SaveHelper;
    import nail.utils.StringUtil;
    import nail.utils.VectorUtils;
    import nail.workers.ApplicationWorker;
    import nail.workers.Command;
    
    import otlib.utils.FilesInfo;
    
    [ResourceBundle("strings")]
    
    public class ObjectBuilderWorker extends ApplicationWorker
    {
        //--------------------------------------------------------------------------
        // PROPERTIES
        //--------------------------------------------------------------------------
        
        private var _things:ThingTypeStorage;
        private var _sprites:SpriteStorage;
        private var _datFile:File;
        private var _sprFile:File;
        private var _version:Version;
        private var _extended:Boolean;
        private var _transparency:Boolean;
        private var _errorMessage:String;
        private var _compiled:Boolean;
        private var _isTemporary:Boolean;
        
        //--------------------------------------
        // Getters / Setters
        //--------------------------------------
        
        public function get compiled():Boolean { return _compiled; }
        public function set compiled(value:Boolean):void
        {
            if (_compiled != value) {
                _compiled = value;
                setSharedProperty("compiled", value);
            }
        }
        
        public function get isTemporary():Boolean { return _isTemporary; }
        public function set isTemporary(value:Boolean):void
        {
            if (_isTemporary != value) {
                _isTemporary = value;
                setSharedProperty("isTemporary", value);
            }
        }
        
        public function get thingsListAmount():uint
        {
            var value:* = getSharedProperty("objectsListAmount");
            if (value !== undefined) {
                return value;
            }
            return 100;
        }
        
        public function get spritesListAmount():uint
        {
            var value:* = getSharedProperty("spritesListAmount");
            if (value !== undefined) {
                return value;
            }
            return 100;
        }
        
        //--------------------------------------------------------------------------
        // CONSTRUCTOR
        //--------------------------------------------------------------------------
        
        public function ObjectBuilderWorker()
        {
            Versions.instance.load(File.applicationDirectory.resolvePath("versions.xml"));
            this.stage.frameRate = 60;
        }
        
        //--------------------------------------------------------------------------
        // METHODS
        //--------------------------------------------------------------------------
        
        //--------------------------------------
        // Public
        //--------------------------------------
        
        public function onGetThing(id:uint, category:String):void
        {
            var thingData:ThingData = getThingData(id, category);
            if (thingData) {
                sendCommand(new SetThingDataCommand(thingData));
            }
        }
        
        public function onGetThingList(id:uint, category:String):void
        {
            this.sendThingList(Vector.<uint>([id]), category);
        }
        
        public function onCompile():void
        {
            this.onCompileAs(_datFile.nativePath,
                _sprFile.nativePath,
                _version,
                _extended,
                _transparency);
        }
        
        public function setSelectedThingIds(value:Vector.<uint>, category:String):void
        {
            if (value && value.length > 0) {
                if (value.length > 1) value.sort(Array.NUMERIC | Array.DESCENDING);
                var max:uint = _things.getMaxId(category);
                if (value[0] > max) {
                    value = Vector.<uint>([max]);
                }
                this.onGetThing(value[0], category);
                this.sendThingList(value, category);
            }
        }
        
        public function setSelectedSpriteIds(value:Vector.<uint>):void
        {
            if (value && value.length > 0) {
                if (value.length > 1) value.sort(Array.NUMERIC | Array.DESCENDING);
                if (value[0] > _sprites.spritesCount) {
                    value = Vector.<uint>([_sprites.spritesCount]);
                }
                this.sendSpriteList(value);
            }
        }
        
        //--------------------------------------
        // Override Protected
        //--------------------------------------
        
        override public function register():void
        {
            // Register classes.
            registerClassAlias("Version", Version);
            registerClassAlias("FilesInfo", FilesInfo);
            registerClassAlias("ThingType", ThingType);
            registerClassAlias("ThingData", ThingData);
            registerClassAlias("ThingProperty", ThingProperty);
            registerClassAlias("ThingListItem", ThingListItem);
            registerClassAlias("SpriteData", SpriteData);
            registerClassAlias("ByteArray", ByteArray);
            registerClassAlias("LoaderHelper", PathHelper);
            
            // File commands
            registerCallback(CommandType.CREATE_NEW_FILES, onCreateNewFiles);
            registerCallback(CommandType.LOAD_FILES, onLoadFiles);
            registerCallback(CommandType.FILES_INFO, onGetFilesInfo);
            registerCallback(CommandType.COMPILE, onCompile);
            registerCallback(CommandType.COMPILE_AS, onCompileAs);
            registerCallback(CommandType.UNLOAD_FILES, onUnloadFiles);
            
            // Thing commands
            registerCallback(CommandType.NEW_THING, onNewThing);
            registerCallback(CommandType.UPDATE_THING, onUpdateThing);
            registerCallback(CommandType.IMPORT_THINGS, onImportThings);
            registerCallback(CommandType.IMPORT_THINGS_FROM_FILES, onImportThingsFromFiles);
            registerCallback(CommandType.EXPORT_THINGS, onExportThing);
            registerCallback(CommandType.REPLACE_THINGS, onReplaceThings);
            registerCallback(CommandType.REPLACE_THINGS_FROM_FILES, onReplaceThingsFromFiles);
            registerCallback(CommandType.DUPLICATE_THINGS, onDuplicateThing);
            registerCallback(CommandType.REMOVE_THINGS, onRemoveThings);
            registerCallback(CommandType.GET_THING, onGetThing);
            registerCallback(CommandType.GET_THING_LIST, onGetThingList);
            registerCallback(CommandType.GET_SPRITE_LIST, onGetSpriteList);
            registerCallback(CommandType.FIND_THING, onFindThing);
            
            // Sprite commands
            registerCallback(CommandType.NEW_SPRITE, onNewSprite);
            registerCallback(CommandType.IMPORT_SPRITES, onAddSprites);
            registerCallback(CommandType.IMPORT_SPRITES_FROM_FILES, onImportSpritesFromFiles);
            registerCallback(CommandType.EXPORT_SPRITES, onExportSprites);
            registerCallback(CommandType.REPLACE_SPRITES, onReplaceSprites);
            registerCallback(CommandType.REPLACE_SPRITES_FROM_FILES, onReplaceSpritesFromFiles);
            registerCallback(CommandType.REMOVE_SPRITES, onRemoveSprites);
            registerCallback(CommandType.FIND_SPRITES, onFindSprites);
            
            // General commands
            registerCallback(CommandType.NEED_TO_RELOAD, onNeedToReload);
        }
        
        //--------------------------------------
        // Private
        //--------------------------------------
        
        private function onCreateNewFiles(version:Version, extended:Boolean, transparency:Boolean):void
        {
            if (!version)
                throw new NullArgumentError("version");
            
            this.onUnloadFiles();
            
            _version = version;
            _extended = (extended || _version.value >= 960);
            _transparency = transparency;
            
            this.createStorage();
            
            // Create sprites.
            if (!_sprites.createNew(version, _extended, transparency)) {
                throw new Error(Resources.getString("strings", "notCreateSpr"));
            }
            
            // Create things.
            if (!_things.createNew(version)) {
                throw new Error(Resources.getString("strings", "notCreateDat"));
            }
            
            this.compiled = false;
            this.isTemporary = true;
            this.assetsLoadComplete();
            
            // Update preview.
            var thing:ThingType = _things.getItemType(ThingTypeStorage.MIN_ITEM_ID);
            this.onGetThing(thing.id, thing.category);
            
            // Send sprites.
            this.onGetSpriteList(1);
        }
        
        private function createStorage():void
        {
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
        
        private function onLoadFiles(datPath:String,
                                     sprPath:String,
                                     version:Version,
                                     extended:Boolean,
                                     transparency:Boolean):void
        {
            if (isNullOrEmpty(datPath))
                throw new NullOrEmptyArgumentError("datPath");
            
            if (isNullOrEmpty(sprPath))
                throw new NullOrEmptyArgumentError("sprPath");
            
            if (!version)
                throw new NullArgumentError("version");
            
            this.onUnloadFiles();
            
            _datFile = new File(datPath);
            _sprFile = new File(sprPath);
            _version = version;
            _extended = (extended || _version.value >= 960);
            _transparency = transparency;
            
            var title:String = Resources.getString("strings", "loading");
            sendCommand(new ShowProgressBarCommand(ProgressBarID.DAT_SPR, title));
            
            createStorage();
            
            _things.load(_datFile, _version, _extended);
        }
        
        private function onGetFilesInfo():void
        {
            this.sendFilesInfo();
        }
        
        private function onCompileAs(datPath:String,
                                     sprPath:String,
                                     version:Version,
                                     extended:Boolean,
                                     transparency:Boolean):void
        {
            if (isNullOrEmpty(datPath))
                throw new NullOrEmptyArgumentError("datPath");
            
            if (isNullOrEmpty(sprPath))
                throw new NullOrEmptyArgumentError("sprPath");
            
            if (!version)
                throw new NullArgumentError("version");
            
            if (!_things || !_things.loaded)
                throw new Error(Resources.getString("strings", "metadataNotLoaded"));
            
            if (!_sprites || !_sprites.loaded)
                throw new Error(Resources.getString("strings", "spritesNotLoaded"));
            
            var dat:File = new File(datPath);
            var spr:File = new File(sprPath);
            var structureChanged:Boolean = (_extended != extended || _transparency != transparency);
            var title:String = Resources.getString("strings", "compiling");
            
            sendCommand(new ShowProgressBarCommand(ProgressBarID.DAT_SPR, title));
            
            if (!_things.compile(dat, version, extended) ||
                !_sprites.compile(spr, version, extended, transparency)) {
                return;
            }
            
            assetsCompileComplete();
            
            if (!_datFile || !_sprFile) {
                _datFile = dat;
                _sprFile = spr;
            }
            
            // If extended or alpha channel was changed need to reload.
            if (FileUtil.compare(dat, _datFile) && FileUtil.compare(spr, _sprFile)) {
                if (structureChanged)
                    sendCommand(new NeedToReloadCommand(extended, transparency));
                else
                    sendFilesInfo();
            }
        }
        
        private function onUnloadFiles():void
        {
            if (_things) {
                _things.removeEventListener(Event.COMPLETE, thingsCompleteHandler);
                _things.removeEventListener(Event.CHANGE, thingsChangeHandler);
                _things.removeEventListener(ProgressEvent.PROGRESS, thingsProgressHandler);
                _things.removeEventListener(ErrorEvent.ERROR, thingsErrorHandler);
                _things = null;
            }
            
            if (_sprites) {
                _sprites.removeEventListener(Event.COMPLETE, spritesCompleteHandler);
                _sprites.removeEventListener(Event.CHANGE, spritesChangeHandler);
                _sprites.removeEventListener(ProgressEvent.PROGRESS, spritesProgressHandler);
                _sprites.removeEventListener(ErrorEvent.ERROR, spritesErrorHandler);
                _sprites = null;
            }
            
            this.compiled = true;
            this.isTemporary = false;
            
            _datFile = null;
            _sprFile = null;
            _version = null;
            _extended = false;
            _transparency = false;
            _errorMessage = null;
        }
        
        private function onNewThing(category:String):void
        {
            if (!ThingCategory.getCategory(category)) {
                throw new Error(Resources.getString("strings", "invalidCategory"));
            }
            
            //============================================================================
            // Add thing
            
            var thing:ThingType = ThingUtils.createThing(category);
            var result:ChangeResult = _things.addThing(thing, category);
            if (!result.done) {
                Log.error(result.message);
                return;
            }
            
            //============================================================================
            // Send changes
            
            // Send thing to preview.
            onGetThing(thing.id, category);
            
            // Send message to log.
            var message:String = Resources.getString(
                "strings",
                "logAdded",
                toLocale(category),
                thing.id);
            
            Log.info(message);
        }
        
        private function onUpdateThing(thingData:ThingData, replaceSprites:Boolean):void
        {
            if (!thingData) {
                throw new NullArgumentError("thingData");
            }
            
            var result:ChangeResult;
            var thing:ThingType = thingData.thing;
            
            if (!_things.hasThingType(thing.category, thing.id)) {
                throw new Error(Resources.getString(
                    "strings",
                    "thingNotFound",
                    toLocale(thing.category),
                    thing.id));
            }
            
            //============================================================================
            // Update sprites
            
            var sprites:Vector.<SpriteData> = thingData.sprites;
            var length:uint = sprites.length;
            var spritesIds:Vector.<uint> = new Vector.<uint>();
            var addedSpriteList:Array = [];
            var currentThing:ThingType = _things.getThingType(thing.id, thing.category);
            
            for (var i:uint = 0; i < length; i++) {
                var spriteData:SpriteData = sprites[i];
                var id:uint = thing.spriteIndex[i];
                
                if (id == uint.MAX_VALUE) {
                    if (spriteData.isEmpty()) {
                        thing.spriteIndex[i] = 0;
                    } else {
                        
                        if (replaceSprites) {
                            result = _sprites.replaceSprite(currentThing.spriteIndex[i], spriteData.pixels);
                        } else {
                            result = _sprites.addSprite(spriteData.pixels);
                        }
                        
                        if (!result.done) {
                            Log.error(result.message);
                            return;
                        }
                        
                        spriteData = result.list[0];
                        thing.spriteIndex[i] = spriteData.id;
                        spritesIds[spritesIds.length] = spriteData.id;
                        addedSpriteList[addedSpriteList.length] = spriteData;
                    }
                } else {
                    if (!_sprites.hasSpriteId(id)) {
                        Log.error(Resources.getString("strings", "spriteNotFound", id));
                        return;
                    }
                }
            }
            
            //============================================================================
            // Update thing
            
            result = _things.replaceThing(thing, thing.category, thing.id);
            if (!result.done) {
                Log.error(result.message);
                return;
            }
            
            //============================================================================
            // Send changes
            
            var message:String;
            
            // Sprites change message
            if (spritesIds.length > 0) {
                message = Resources.getString(
                    "strings",
                    replaceSprites ? "logReplaced" : "logAdded",
                    toLocale("sprite", spritesIds.length > 1),
                    spritesIds);
                
                Log.info(message);
                
                this.setSelectedSpriteIds(spritesIds);
            }
            
            // Thing change message
            onGetThing(thingData.id, thingData.category);
            onGetThingList(thingData.id, thingData.category);
            message = Resources.getString(
                "strings",
                "logChanged",
                toLocale(thing.category),
                thing.id);
            
            Log.info(message);
        }
        
        private function onExportThing(list:Vector.<PathHelper>,
                                       category:String,
                                       version:Version,
                                       spriteSheetFlag:uint):void
        {
            if (!list)
                throw new NullArgumentError("list");
            
            if (!ThingCategory.getCategory(category))
                throw new ArgumentError(Resources.getString("strings", "invalidCategory"));
            
            if (!version)
                throw new NullArgumentError("version");
            
            var length:uint = list.length;
            if (length == 0) return;
            
            //============================================================================
            // Export things
            
            sendCommand(new ShowProgressBarCommand(ProgressBarID.DEFAULT, Resources.getString("strings", "exportingObjects")));
            
            var helper:SaveHelper = new SaveHelper();
            var backgoundColor:uint = _transparency ? 0x00FF00FF : 0xFFFF00FF;
            var bytes:ByteArray;
            var bitmap:BitmapData;
            
            for (var i:uint = 0; i < length; i++) {
                var pathHelper:PathHelper = list[i];
                var thingData:ThingData = getThingData(pathHelper.id, category);
                var file:File = new File(pathHelper.nativePath);
                var name:String = FileUtil.getName(file);
                var format:String = file.extension;
                
                if (ImageFormat.hasImageFormat(format)) {
                    bitmap = ThingData.getSpriteSheet(thingData, null, backgoundColor);
                    bytes = ImageCodec.encode(bitmap, format);
                    if (spriteSheetFlag != 0) {
                        helper.addFile(ObUtils.getPatternsString(thingData.thing, spriteSheetFlag), name, "txt", file);
                    }
                } else if (format == OTFormat.OBD) {
                    bytes = ThingData.serialize(thingData, version);
                }
                helper.addFile(bytes, name, format, file);
            }
            helper.addEventListener(flash.events.ProgressEvent.PROGRESS, progressHandler);
            helper.addEventListener(Event.COMPLETE, completeHandler);
            helper.save();
            
            function progressHandler(event:flash.events.ProgressEvent):void
            {
                sendCommand(new ProgressCommand(ProgressBarID.DEFAULT, event.bytesLoaded, event.bytesTotal));
            }
            
            function completeHandler(event:Event):void
            {
                sendCommand(new HideProgressBarCommand(ProgressBarID.DEFAULT));
            }
        }
        
        private function onReplaceThings(list:Vector.<ThingData>):void
        {
            if (!list) {
                throw new NullArgumentError("list");
            }
            
            var length:uint = list.length;
            if (length == 0) return;
            
            //============================================================================
            // Add sprites
            
            var result:ChangeResult;
            var spritesIds:Vector.<uint> = new Vector.<uint>();
            for (var i:uint = 0; i < length; i++) {
                var thing:ThingType = list[i].thing;
                var sprites:Vector.<SpriteData> = list[i].sprites;
                var len:uint = sprites.length;
                
                for (var k:uint = 0; k < len; k++) {
                    var spriteData:SpriteData = sprites[k];
                    var id:uint = spriteData.id;
                    if (spriteData.isEmpty()) {
                        id = 0;
                    } else if (!_sprites.hasSpriteId(id) || !_sprites.compare(id, spriteData.pixels)) {
                        result = _sprites.addSprite(spriteData.pixels);
                        if (!result.done) {
                            Log.error(result.message);
                            return;
                        }
                        id = _sprites.spritesCount;
                        spritesIds[spritesIds.length] = id;
                    }
                    thing.spriteIndex[k] = id;
                }
            }
            
            //============================================================================
            // Replace things
            
            var thingsToReplace:Vector.<ThingType> = new Vector.<ThingType>(length, true);
            var thingsIds:Vector.<uint> = new Vector.<uint>(length, true);
            for (i = 0; i < length; i++) {
                thingsToReplace[i] = list[i].thing;
                thingsIds[i] = list[i].id;
            }
            result = _things.replaceThings(thingsToReplace);
            if (!result.done) {
                Log.error(result.message);
                return;
            }
            
            //============================================================================
            // Send changes
            
            var message:String;
            
            // Added sprites message
            if (spritesIds.length > 0) {
                onGetSpriteList(_sprites.spritesCount);
                message = Resources.getString(
                    "strings",
                    "logAdded",
                    toLocale("sprite", spritesIds.length > 1),
                    spritesIds);
                
                Log.info(message);
            }
            
            var category:String = list[0].thing.category;
            this.setSelectedThingIds(thingsIds, category);
            
            message = Resources.getString(
                "strings",
                "logReplaced",
                toLocale(category, thingsIds.length > 1),
                thingsIds);
            
            Log.info(message);
        }
        
        private function onReplaceThingsFromFiles(list:Vector.<PathHelper>):void
        {
            if (!list) {
                throw new NullArgumentError("list");
            }
            
            var length:uint = list.length;
            if (length == 0) return;
            
            //============================================================================
            // Load things
            
            var loader:ThingDataLoader = new ThingDataLoader();
            loader.addEventListener(ProgressEvent.PROGRESS, progressHandler);
            loader.addEventListener(Event.COMPLETE, completeHandler);
            loader.addEventListener(ErrorEvent.ERROR, errorHandler);
            loader.loadFiles(list);
            
            sendCommand(new ShowProgressBarCommand(ProgressBarID.DEFAULT, Resources.getString("strings", "loading")));
            
            function progressHandler(event:ProgressEvent):void
            {
                sendCommand(new ProgressCommand(event.id, event.loaded, event.total));
            }
            
            function completeHandler(event:Event):void
            {
                sendCommand(new HideProgressBarCommand(ProgressBarID.DEFAULT));
                onReplaceThings(loader.thingDataList);
            }
            
            function errorHandler(event:ErrorEvent):void
            {
                sendCommand(new HideProgressBarCommand(ProgressBarID.DEFAULT));
                Log.error(event.text);
            }
        }
        
        private function onImportThings(list:Vector.<ThingData>):void
        {
            if (!list) {
                throw new NullArgumentError("list");
            }
            
            var length:uint = list.length;
            if (length == 0) return;
            
            //============================================================================
            // Add sprites
            
            var result:ChangeResult;
            var spritesIds:Vector.<uint> = new Vector.<uint>();
            for (var i:uint = 0; i < length; i++) {
                var thing:ThingType = list[i].thing;
                var sprites:Vector.<SpriteData> = list[i].sprites;
                var len:uint = sprites.length;
                
                for (var k:uint = 0; k < len; k++) {
                    var spriteData:SpriteData = sprites[k];
                    var id:uint = spriteData.id;
                    if (spriteData.isEmpty()) {
                        id = 0;
                    } else if (!_sprites.hasSpriteId(id) || !_sprites.compare(id, spriteData.pixels)) {
                        result = _sprites.addSprite(spriteData.pixels);
                        if (!result.done) {
                            Log.error(result.message);
                            return;
                        }
                        id = _sprites.spritesCount;
                        spritesIds[spritesIds.length] = id;
                    }
                    thing.spriteIndex[k] = id;
                }
            }
            
            //============================================================================
            // Add things
            
            var thingsToAdd:Vector.<ThingType> = new Vector.<ThingType>(length, true);
            for (i = 0; i < length; i++) {
                thingsToAdd[i] = list[i].thing;
            }
            result = _things.addThings(thingsToAdd);
            if (!result.done) {
                Log.error(result.message);
                return;
            }
            
            var addedThings:Array = result.list;
            
            //============================================================================
            // Send changes
            
            var message:String;
            
            if (spritesIds.length > 0) {
                onGetSpriteList(_sprites.spritesCount);
                message = Resources.getString(
                    "strings",
                    "logAdded",
                    toLocale("sprite", spritesIds.length > 1),
                    spritesIds);
                
                Log.info(message);
            }
            
            var thingsIds:Vector.<uint> = new Vector.<uint>(length, true);
            for (i = 0; i < length; i++) {
                thingsIds[i] = addedThings[i].id;
            }
            
            var category:String = list[0].thing.category;
            this.setSelectedThingIds(thingsIds, category);
            
            message = Resources.getString(
                "strings",
                "logAdded",
                toLocale(category, thingsIds.length > 1),
                thingsIds);
            
            Log.info(message);
        }
        
        private function onImportThingsFromFiles(list:Vector.<PathHelper>):void
        {
            if (!list) {
                throw new NullArgumentError("list");
            }
            
            var length:uint = list.length;
            if (length == 0) return;
            
            //============================================================================
            // Load things
            
            var loader:ThingDataLoader = new ThingDataLoader();
            loader.addEventListener(ProgressEvent.PROGRESS, progressHandler);
            loader.addEventListener(Event.COMPLETE, completeHandler);
            loader.addEventListener(ErrorEvent.ERROR, errorHandler);
            loader.loadFiles(list);
            
            sendCommand(new ShowProgressBarCommand(ProgressBarID.DEFAULT, Resources.getString("strings", "loading")));
            
            function progressHandler(event:ProgressEvent):void
            {
                sendCommand(new ProgressCommand(event.id, event.loaded, event.total));
            }
            
            function completeHandler(event:Event):void
            {
                sendCommand(new HideProgressBarCommand(ProgressBarID.DEFAULT));
                onImportThings(loader.thingDataList);
            }
            
            function errorHandler(event:ErrorEvent):void
            {
                sendCommand(new HideProgressBarCommand(ProgressBarID.DEFAULT));
                Log.error(event.text);
            }
        }
        
        private function onDuplicateThing(list:Vector.<uint>, category:String):void
        {
            if (!list) {
                throw new NullArgumentError("list");
            }
            
            if (!ThingCategory.getCategory(category)) {
                throw new Error(Resources.getString("strings", "invalidCategory"));
            }
            
            var length:uint = list.length;
            if (length == 0) return;
            
            //============================================================================
            // Duplicate things
            
            list.sort(Array.NUMERIC);
            
            var thingsCopyList:Vector.<ThingType> = new Vector.<ThingType>();
            
            for (var i:uint = 0; i < length; i++) {
                var thing:ThingType = _things.getThingType(list[i], category);
                if (!thing) {
                    throw new Error(Resources.getString(
                        "strings",
                        "thingNotFound",
                        Resources.getString("strings", category),
                        list[i]));
                }
                thingsCopyList[i] = thing.clone();
            }
            
            var result:ChangeResult = _things.addThings(thingsCopyList);
            if (!result.done) {
                Log.error(result.message);
                return;
            }
            
            var addedThings:Array = result.list;
            
            //============================================================================
            // Send changes
            
            length = addedThings.length;
            var thingIds:Vector.<uint> = new Vector.<uint>(length, true);
            for (i = 0; i < length; i++) {
                thingIds[i] = addedThings[i].id;
            }
            
            this.setSelectedThingIds(thingIds, category);
            
            thingIds.sort(Array.NUMERIC);
            var message:String = StringUtil.substitute(Resources.getString(
                "strings",
                "logDuplicated"),
                toLocale(category, thingIds.length > 1),
                list);
            
            Log.info(message);
        }
        
        private function onRemoveThings(list:Vector.<uint>, category:String, removeSprites:Boolean):void
        {
            if (!list) {
                throw new NullArgumentError("list");
            }
            
            if (!ThingCategory.getCategory(category)) {
                throw new ArgumentError(Resources.getString("strings", "invalidCategory"));
            }
            
            var length:uint = list.length;
            if (length == 0) return;
            
            //============================================================================
            // Remove things
            
            var result:ChangeResult = _things.removeThings(list, category);
            if (!result.done) {
                Log.error(result.message);
                return;
            }
            
            var removedThingList:Array = result.list;
            
            //============================================================================
            // Remove sprites
            
            var removedSpriteList:Array;
            
            if (removeSprites) {
                var sprites:Object = {};
                var id:uint;
                
                length = removedThingList.length;
                for (var i:uint = 0; i < length; i++) {
                    var spriteIndex:Vector.<uint> = removedThingList[i].spriteIndex;
                    var len:uint = spriteIndex.length;
                    for (var k:uint = 0; k < len; k++) {
                        id = spriteIndex[k];
                        if (id != 0) {
                            sprites[id] = id;
                        }
                    }
                }
                
                var spriteIds:Vector.<uint> = new Vector.<uint>();
                for each(id in sprites) {
                    spriteIds[spriteIds.length] = id;
                }
                
                result = _sprites.removeSprites(spriteIds);
                if (!result.done) {
                    Log.error(result.message);
                    return;
                }
                
                removedSpriteList = result.list;
            }
            
            //============================================================================
            // Send changes
            
            var message:String;
            
            length = removedThingList.length;
            var thingIds:Vector.<uint> = new Vector.<uint>(length, true);
            for (i = 0; i < length; i++) {
                thingIds[i] = removedThingList[i].id;
            }
            
            this.setSelectedThingIds(thingIds, category);
            
            thingIds.sort(Array.NUMERIC);
            message = Resources.getString(
                "strings",
                "logRemoved",
                toLocale(category, thingIds.length > 1),
                thingIds);
            
            Log.info(message);
            
            // Sprites changes
            if (removeSprites && spriteIds.length != 0) {
                spriteIds.sort(Array.NUMERIC);
                onGetSpriteList(spriteIds[0]);
                message = Resources.getString(
                    "strings",
                    "logRemoved",
                    toLocale("sprite", spriteIds.length > 1),
                    spriteIds);
                
                Log.info(message);
            }
        }
        
        private function onFindThing(category:String, properties:Vector.<ThingProperty>):void
        {
            if (!ThingCategory.getCategory(category)) {
                throw new ArgumentError(Resources.getString("strings", "invalidCategory"));
            }
            
            if (!properties) {
                throw new NullArgumentError("properties");
            }
            
            var list:Array = [];
            var things:Array = _things.findThingTypeByProperties(category, properties);
            var length:uint = things.length;
            
            for (var i:uint = 0; i < length; i++) {
                var listItem : ThingListItem = new ThingListItem();
                listItem.thing = things[i];
                listItem.pixels = getBitmapPixels(listItem.thing);
                list[i] = listItem;
            }
            sendCommand(new FindResultCommand(FindResultCommand.THINGS, list));
        }
        
        private function onGetSpriteList(target:uint):void
        {
            this.sendSpriteList(Vector.<uint>([target]));
        }
        
        private function onReplaceSprites(sprites:Vector.<SpriteData>):void
        {
            if (!sprites) {
                throw new NullArgumentError("sprites");
            }
            
            var length:uint = sprites.length;
            if (length == 0) return;
            
            //============================================================================
            // Replace sprites
            
            var result:ChangeResult = _sprites.replaceSprites(sprites);
            if (!result.done) {
                Log.error(result.message);
                return;
            }
            
            //============================================================================
            // Send changes
            
            var spriteIds:Vector.<uint> = new Vector.<uint>(length, true);
            for (var i:uint = 0; i < length; i++) {
                spriteIds[i] = sprites[i].id;
            }
            
            this.setSelectedSpriteIds(spriteIds);
                
            var message:String = Resources.getString(
                "strings",
                "logReplaced",
                toLocale("sprite", sprites.length > 1),
                spriteIds);
            
            Log.info(message);
        }
        
        private function onReplaceSpritesFromFiles(list:Vector.<PathHelper>):void
        {
            if (!list) {
                throw new NullArgumentError("list");
            }
            
            if (list.length == 0) return;
            
            //============================================================================
            // Load sprites
            
            var loader:SpriteDataLoader = new SpriteDataLoader();
            loader.addEventListener(Event.COMPLETE, completeHandler);
            loader.addEventListener(ProgressEvent.PROGRESS, progressHandler);
            loader.loadFiles(list);
            
            sendCommand(new ShowProgressBarCommand(ProgressBarID.DEFAULT, Resources.getString("strings", "loading")));
            
            function progressHandler(event:ProgressEvent):void
            {
                sendCommand(new ProgressCommand(event.id, event.loaded, event.total));
            }
            
            function completeHandler(event:Event):void
            {
                sendCommand(new HideProgressBarCommand(ProgressBarID.DEFAULT));
                onReplaceSprites(loader.spriteDataList);
            }
        }
        
        private function onAddSprites(sprites:Vector.<ByteArray>):void
        {
            if (!sprites) {
                throw new NullArgumentError("sprites");
            }
            
            if (sprites.length == 0) return;
            
            //============================================================================
            // Add sprites
            
            var result:ChangeResult = _sprites.addSprites(sprites);
            if (!result.done) {
                Log.error(result.message);
                return;
            }
            
            var spriteAddedList:Array = result.list;
            
            //============================================================================
            // Send changes to application
            
            var ids:Array = [];
            var length:uint = spriteAddedList.length;
            for (var i:uint = 0; i < length; i++) {
                ids[i] = spriteAddedList[i].id;
            }
            
            this.onGetSpriteList(ids[0]);
            
            ids.sort(Array.NUMERIC);
            var message:String = Resources.getString(
                "strings",
                "logRemoved",
                toLocale("sprite", ids.length > 1),
                ids);
            
            Log.info(message);
        }
        
        private function onImportSpritesFromFiles(list:Vector.<PathHelper>):void
        {
            if (!list) {
                throw new NullArgumentError("list");
            }
            
            if (list.length == 0) return;
            
            //============================================================================
            // Load sprites
            
            var loader:SpriteDataLoader = new SpriteDataLoader();
            loader.addEventListener(ProgressEvent.PROGRESS, progressHandler);
            loader.addEventListener(Event.COMPLETE, completeHandler);
            loader.addEventListener(ErrorEvent.ERROR, errorHandler);
            loader.loadFiles(list);
            
            sendCommand(new ShowProgressBarCommand(ProgressBarID.DEFAULT, Resources.getString("strings", "loading")));
            
            function progressHandler(event:ProgressEvent):void
            {
                sendCommand(new ProgressCommand(event.id, event.loaded, event.total));
            }
            
            function completeHandler(event:Event):void
            {
                sendCommand(new HideProgressBarCommand(ProgressBarID.DEFAULT));
                
                var spriteDataList:Vector.<SpriteData> = loader.spriteDataList;
                var length:uint = spriteDataList.length;
                var sprites:Vector.<ByteArray> = new Vector.<ByteArray>(length, true);
                
                VectorUtils.sortOn(spriteDataList, "id", Array.NUMERIC | Array.DESCENDING);
                
                for (var i:uint = 0; i < length; i++) {
                    sprites[i] = spriteDataList[i].pixels;
                }
                
                onAddSprites(sprites);
            }
            
            function errorHandler(event:ErrorEvent):void
            {
                sendCommand(new HideProgressBarCommand(ProgressBarID.DEFAULT));
                Log.error(event.text);
            }
        }
        
        private function onExportSprites(list:Vector.<PathHelper>):void
        {
            if (!list) {
                throw new NullArgumentError("list");
            }
            
            var length:uint = list.length;
            if (length == 0) return;
            
            //============================================================================
            // Save sprites
            
            sendCommand(new ShowProgressBarCommand(ProgressBarID.DEFAULT, Resources.getString("strings", "exportingSprites")));
            
            var helper:SaveHelper = new SaveHelper();
            var backgoundColor:uint = _transparency ? 0x00FF00FF : 0xFFFF00FF;
            
            for (var i:uint = 0; i < length; i++) {
                var pathHelper:PathHelper = list[i];
                var file:File = new File(pathHelper.nativePath);
                var name:String = FileUtil.getName(file);
                var format:String = file.extension;
                
                if (ImageFormat.hasImageFormat(format) && pathHelper.id != 0) {
                    var bitmap:BitmapData = _sprites.getBitmap(pathHelper.id, backgoundColor);
                    if (bitmap) {
                        var bytes:ByteArray = ImageCodec.encode(bitmap, format);
                        helper.addFile(bytes, name, format, file);
                    }
                }
            }
            helper.addEventListener(flash.events.ProgressEvent.PROGRESS, progressHandler);
            helper.addEventListener(Event.COMPLETE, completeHandler);
            helper.save();
            
            function progressHandler(event:flash.events.ProgressEvent):void
            {
                sendCommand(new ProgressCommand(ProgressBarID.DEFAULT, event.bytesLoaded, event.bytesTotal));
            }
            
            function completeHandler(event:Event):void
            {
                sendCommand(new HideProgressBarCommand(ProgressBarID.DEFAULT));
            }
        }
        
        private function onNewSprite():void
        {
            if (_sprites.isFull) {
                Log.error(Resources.getString("strings", "spritesLimitReached"));
                return;
            }
            
            //============================================================================
            // Add sprite
            
            var rect:Rectangle = new Rectangle(0, 0, Sprite.SPRITE_PIXELS, Sprite.SPRITE_PIXELS);
            var pixels:ByteArray = new BitmapData(rect.width, rect.height, true, 0).getPixels(rect);
            var result:ChangeResult = _sprites.addSprite(pixels);
            if (!result.done) {
                Log.error(result.message);
                return;
            }
            
            //============================================================================
            // Send changes
            
            this.onGetSpriteList(_sprites.spritesCount);
            var message:String = Resources.getString(
                "strings",
                "logAdded",
                Resources.getString("strings", "sprite"),
                _sprites.spritesCount);
            Log.info(message);
        }
        
        private function onRemoveSprites(list:Vector.<uint>):void
        {
            if (!list) {
                throw new NullArgumentError("list");
            }
            
            //============================================================================
            // Removes sprites
            
            var result:ChangeResult = _sprites.removeSprites(list);
            if (!result.done) {
                Log.error(result.message);
                return;
            }
            
            //============================================================================
            // Send changes
            
            // Select sprites
            this.setSelectedSpriteIds(list);
            
            // Send message to log
            var message:String = Resources.getString(
                "strings",
                "logRemoved",
                toLocale("sprite", list.length > 1),
                list);
                
            Log.info(message);
        }
        
        private function onNeedToReload(enableSpritesU32:Boolean, enableAlphaChannel:Boolean):void
        {
            onLoadFiles(_datFile.nativePath,
                _sprFile.nativePath,
                _version,
                enableSpritesU32,
                enableAlphaChannel);
        }
        
        private function onFindSprites(unusedSprites:Boolean, emptySprites:Boolean):void
        {
            var spriteFoundList:Array = [];
            
            if (unusedSprites || emptySprites) {
                var length:uint;
                var i:uint;
                var spriteData:SpriteData;
                
                if (unusedSprites) {
                    var ids:Vector.<Boolean> = new Vector.<Boolean>(_sprites.spritesCount + 1, true);
                    var list:Dictionary;
                    var thing:ThingType;
                    var sprites:Vector.<uint>;
                    
                    // Scan items
                    list = _things.items;
                    for each (thing in list) {
                        sprites = thing.spriteIndex;
                        length = sprites.length;
                        for (i = 0; i < length; i++) {
                            ids[sprites[i]] = true;
                        }
                    }
                    
                    // Scan outfits
                    list = _things.outfits;
                    for each (thing in list) {
                        sprites = thing.spriteIndex;
                        length = sprites.length;
                        for (i = 0; i < length; i++) {
                            ids[sprites[i]] = true;
                        }
                    }
                    
                    // Scan effects
                    list = _things.effects;
                    for each (thing in list) {
                        sprites = thing.spriteIndex;
                        length = sprites.length;
                        for (i = 0; i < length; i++) {
                            ids[sprites[i]] = true;
                        }
                    }
                    
                    // Scan missiles
                    list = _things.missiles;
                    for each (thing in list) {
                        sprites = thing.spriteIndex;
                        length = sprites.length;
                        for (i = 0; i < length; i++) {
                            ids[sprites[i]] = true;
                        }
                    }
                    
                    length = ids.length;
                    for (i = 1; i < length; i++) {
                        if (!ids[i]) {
                            
                            if (_sprites.isEmptySprite(i) == false || emptySprites) {
                                spriteData = new SpriteData();
                                spriteData.id = i;
                                spriteData.pixels = _sprites.getPixels(i);
                                spriteFoundList[spriteFoundList.length] = spriteData;
                                sendCommand(new ProgressCommand(ProgressBarID.FIND, i, length));
                            }
                        }
                    }
                } else if (emptySprites) {
                    
                    length = _sprites.spritesCount;
                    for (i = 1; i <= length; i++) {
                        if (_sprites.isEmptySprite(i)) {
                            spriteData = new SpriteData();
                            spriteData.id = i;
                            spriteData.pixels = _sprites.getPixels(i);
                            spriteFoundList[spriteFoundList.length] = spriteData;
                            sendCommand(new ProgressCommand(ProgressBarID.FIND, i, length));
                        }
                    }
                }
            }
            
            sendCommand(new FindResultCommand(FindResultCommand.SPRITES, spriteFoundList));
        }
        
        private function assetsLoadComplete():void
        {
            this.compiled = true;
            sendCommand(new HideProgressBarCommand(ProgressBarID.DAT_SPR));
            sendCommand(new Command(CommandType.LOAD_COMPLETE));
            Log.info(Resources.getString("strings", "loadComplete"));
        }
        
        private function assetsCompileComplete():void
        {
            this.compiled = true;
            this.isTemporary = false;
            sendCommand(new HideProgressBarCommand(ProgressBarID.DAT_SPR));
            Log.info(Resources.getString("strings", "compileComplete"));
        }
        
        public function sendFilesInfo():void
        {
            if (!_things || !_things.loaded) {
                throw new Error(Resources.getString("strings", "metadataNotLoaded"));
            }
            
            if (!_sprites || !_sprites.loaded) {
                throw new Error(Resources.getString("strings", "spritesNotLoaded"));
            }
            
            var info:FilesInfo = new FilesInfo();
            info.clientVersion = _version.value;
            info.clientVersionStr = _version.valueStr;
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
            info.extended = (_extended || _version.value >= 960);
            info.transparency = _transparency;
            
            sendCommand(new SetFilesInfoCommand(info));
        }
        
        private function sendThingList(selectedIds:Vector.<uint>, category:String):void
        {
            if (!_things || !_things.loaded) {
                throw new Error(Resources.getString("strings", "metadataNotLoaded"));
            }
            
            var first:uint = _things.getMinId(category);
            var last:uint = _things.getMaxId(category);
            var length:uint = selectedIds.length;
            
            if (length > 1) {
                selectedIds.sort(Array.NUMERIC | Array.DESCENDING);
                if (selectedIds[length - 1] > last) {
                    selectedIds = Vector.<uint>([last]);
                }
            }
            
            var target:uint = length == 0 ? 0 : selectedIds[0];
            var min:uint = Math.max(first, ObUtils.hundredFloor(target));
            var diff:uint = (category != ThingCategory.ITEM && min == first) ? 1 : 0;
            var max:uint = Math.min((min - diff) + (thingsListAmount - 1), last);
            var list:Vector.<ThingListItem> = new Vector.<ThingListItem>();
            
            for (var i:uint = min; i <= max; i++) {
                var thing:ThingType = _things.getThingType(i, category);
                if (!thing) {
                    throw new Error(Resources.getString(
                        "strings",
                        "thingNotFound",
                        Resources.getString("strings", category),
                        i));
                }
                
                var listItem:ThingListItem = new ThingListItem();
                listItem.thing = thing;
                listItem.pixels = getBitmapPixels(thing);
                list.push(listItem);
            }
            
            sendCommand(new SetThingListCommand(selectedIds, list));
        }
        
        private function sendSpriteList(selectedIds:Vector.<uint>):void
        {
            if (!selectedIds) {
                throw new NullArgumentError("selectedIds");
            }
            
            if (!_sprites || !_sprites.loaded) {
                throw new Error(Resources.getString("strings", "spritesNotLoaded"));
            }
            
            var length:uint = selectedIds.length;
            if (length > 1) {
                selectedIds.sort(Array.NUMERIC | Array.DESCENDING);
                if (selectedIds[length - 1] > _sprites.spritesCount) {
                    selectedIds = Vector.<uint>([_sprites.spritesCount]);
                }
            }
            
            var target:uint = length == 0 ? 0 : selectedIds[0];
            var first:uint = 0;
            var last:uint = _sprites.spritesCount;
            var min:uint = Math.max(first, ObUtils.hundredFloor(target));
            var max:uint = Math.min(min + (spritesListAmount - 1), last);
            var list:Vector.<SpriteData> = new Vector.<SpriteData>();
            
            for (var i:uint = min; i <= max; i++) {
                var pixels:ByteArray = _sprites.getPixels(i);
                if (!pixels) {
                    throw new Error(Resources.getString("strings", "spriteNotFound", i));
                }
                
                var spriteData:SpriteData = new SpriteData();
                spriteData.id = i;
                spriteData.pixels = pixels;
                list.push(spriteData);
            }
            
            sendCommand(new SetSpriteListCommand(selectedIds, list));
        }
        
        private function getBitmapPixels(thing:ThingType):ByteArray
        {
            var size:uint = Sprite.SPRITE_PIXELS;
            var width:uint = thing.width;
            var height:uint = thing.height;
            var layers:uint = thing.layers;
            var bitmap:BitmapData = new BitmapData(width * size, height * size, true, 0xFF636363);
            var x:uint;
            
            if (thing.category == ThingCategory.OUTFIT) {
                layers = 1;
                x = thing.frames > 1 ? 2 : 0;
            }
            
            for (var l:uint = 0; l < layers; l++) {
                for (var w:uint = 0; w < width; w++) {
                    for (var h:uint = 0; h < height; h++) {
                        var index:uint = ThingData.getSpriteIndex(thing, w, h, l, x, 0, 0, 0);
                        var px:int = (width - w - 1) * size;
                        var py:int = (height - h - 1) * size;
                        _sprites.copyPixels(thing.spriteIndex[index], bitmap, px, py);
                    }
                }
            }
            return bitmap.getPixels(bitmap.rect);
        }
        
        private function getThingData(id:uint, category:String):ThingData
        {
            if (!ThingCategory.getCategory(category)) {
                throw new Error(Resources.getString("strings", "invalidCategory"));
            }
            
            var thing:ThingType = _things.getThingType(id,  category);
            if (!thing) {
                throw new Error(Resources.getString(
                    "strings",
                    "thingNotFound",
                    Resources.getString("strings", category),
                    id));
            }
            
            var sprites:Vector.<SpriteData> = new Vector.<SpriteData>();
            var spriteIndex:Vector.<uint> = thing.spriteIndex;
            var length:uint = spriteIndex.length;
            
            for (var i:uint = 0; i < length; i++) {
                var spriteId:uint = spriteIndex[i];
                var pixels:ByteArray = _sprites.getPixels(spriteId);
                if (!pixels) {
                    Log.error(Resources.getString("strings", "spriteNotFound", spriteId));
                    pixels = _sprites.alertSprite.getPixels();
                }
                
                var spriteData:SpriteData = new SpriteData();
                spriteData.id = spriteId;
                spriteData.pixels = pixels;
                sprites.push(spriteData);
            }
            return ThingData.createThingData(thing, sprites);
        }
        
        private function toLocale(bundle:String, plural:Boolean = false):String
        {
            return Resources.getString("strings", bundle + (plural ? "s" : "")).toLowerCase();
        }
        
        //--------------------------------------
        // Event Handlers
        //--------------------------------------
        
        protected function thingsCompleteHandler(event:Event):void
        {
            if (_sprites && !_sprites.loaded) {
                _sprites.load(_sprFile, _version, _extended, _transparency);
            }
        }
        
        protected function thingsChangeHandler(event:Event):void
        {
            this.compiled = false;
            sendFilesInfo();
        }
        
        protected function thingsProgressHandler(event:ProgressEvent):void
        {
            sendCommand(new ProgressCommand(event.id, event.loaded, event.total));
        }
        
        protected function thingsErrorHandler(event:ErrorEvent):void
        {
            // Try load as extended.
            if (!_things.loaded && !_extended) {
                _errorMessage = event.text;
                onLoadFiles(_datFile.nativePath,
                    _sprFile.nativePath,
                    _version,
                    true,
                    _transparency);
            } else {
                if (_errorMessage) {
                    Log.error(_errorMessage);
                    _errorMessage = null;
                } else {
                    Log.error(event.text);
                }
            }
        }
        
        protected function spritesCompleteHandler(event:Event):void
        {
            if (_things && _things.loaded) {
                this.assetsLoadComplete();
            }
        }
        
        protected function spritesChangeHandler(event:Event):void
        {
            this.compiled = false;
            sendFilesInfo();
        }
        
        protected function spritesProgressHandler(event:ProgressEvent):void
        {
            sendCommand(new ProgressCommand(event.id, event.loaded, event.total));
        }
        
        protected function spritesErrorHandler(event:ErrorEvent):void
        {
            Log.error(event.text, "", event.errorID);
        }
    }
}
