package com.dummyTerminal.ZipUtils 
{
	import flash.display.DisplayObject;
	import flash.events.EventDispatcher;
	import deng.fzip.FZip;
	import deng.fzip.FZipFile;
	import deng.fzip.FZipEvent;
	import deng.fzip.FZipErrorEvent;
	import com.dummyTerminal.ZipUtils.ZipLoaderEvent;
	import flash.display.Loader;
	import flash.events.*;
	import flash.media.Sound;
	import flash.net.URLRequest;
	import flash.events.ProgressEvent;
		
	/*
	*
	* To support loading sound files from the zip: an object that supports 'loading' a sound from a Byte Array is required.
	* this functionality is only supported in Flash Player 11.2 & higher (At the time of writing it is in Beta release only)
	* Method: Sound.loadCompressedDataFromByteArray() should provide required functionality
	* Recommend inspecting the extention of the filename for audio file types and switching at processAsset() to appropriate loader type
	* Which will allow you to extract & dispatch the properly typed media at the loader Init event handler
	* 
	*/
	
	public class ZipLoader extends EventDispatcher 
	{
		protected static const VALID_FILE_EXTENSIONS			:Array							= [".png", ".gif", ".jpg", ".swf"]; //audio & video not currently supported
		
		protected var _zip										:FZip;
		protected var _zipFileUrl								:String							= "";
		
		protected var allZipAssetLoaders						:Vector.<ZipAssetLoader>		= new Vector.<ZipAssetLoader>();
		
		protected var totalFiles								:uint							= 0;
		protected var filesProcessed							:uint							= 0;
		
		protected var complete									:Boolean						= false;
		protected var processing								:Boolean						= false;
		protected var loadComplete								:Boolean						= false;
		
		public function ZipLoader() 
		{
			super();
		}
		
		/*
		 *  Public Interface
		 */////////////////////////////////////////////////////////
		
		public function loadZipFile(zipFileUrl:String = null):void 
		{
			if (processing) return;
			
			processing = true;
			_zip = new FZip();
			
			_zip.addEventListener(Event.OPEN, onZipOpen);
			_zip.addEventListener(ProgressEvent.PROGRESS, onZipLoadProgress);
			_zip.addEventListener(Event.COMPLETE, onZipLoadComplete);
			_zip.addEventListener(FZipEvent.FILE_LOADED, onZipAssetLoaded);
			_zip.addEventListener(FZipErrorEvent.PARSE_ERROR, onZipParseError);
						
			_zip.load(new URLRequest(zipFileUrl));
		}
		
		public function reset():void 
		{
			_zip = null;
			_zipFileUrl = "";
			complete = false;
			loadComplete = false;
			
			if (_zip.hasEventListener(FZipErrorEvent.PARSE_ERROR)) 	_zip.removeEventListener(FZipErrorEvent.PARSE_ERROR, onZipParseError);
			if (_zip.hasEventListener(FZipEvent.FILE_LOADED)) 		_zip.removeEventListener(FZipEvent.FILE_LOADED, onZipAssetLoaded);
			if (_zip.hasEventListener(Event.OPEN)) 					_zip.removeEventListener(Event.OPEN, onZipOpen);
			if (_zip.hasEventListener(Event.COMPLETE)) 				_zip.removeEventListener(Event.COMPLETE, onZipLoadComplete);
			
			clearLoaders();
			
			processing = false;
		}
		
		public function destroy():void
		{
			reset();
			delete this;
		}
		
		/*
		 * Event Handlers
		 */////////////////////////////////////////////////////////
		
		protected function onZipLoadProgress(e:ProgressEvent):void 
		{
			dispatchEvent(e);
		}
				
		protected function clearLoaders():void
		{
			while (allZipAssetLoaders.length) 
			{
				allZipAssetLoaders.pop().destroy();
			}
		}
		
		protected function onZipAssetLoaded(e:FZipEvent):void
		{
			//trace("zipAssetLoaded " + filesProcessed);
			
			if (!isValidFileExtension(e.file.filename))
			{
				trace("@ZipLoader: Unsupported file type: " + e.file.filename + " supported file types are " + VALID_FILE_EXTENSIONS);
				filesProcessed ++;
				return;
			}
			processAsset(e);
		}
		
		protected function processAsset(e:FZipEvent):void 
		{
			var file:FZipFile 						= e.file;
			var loader:ZipAssetLoader				= new ZipAssetLoader(); //custom loader allows extra props to travel with event obj
			loader.filename							= file.filename; //store filename of loaded asset so its accessible at INIT
			
			loader.contentLoaderInfo.addEventListener(Event.INIT, assetInitHandler)
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, assetIOErrorHandler)
			loader.loadBytes(file.content);
		}
		
		protected function dispatchAsset(assetData:ZipAssetDataObj):void
		{
			dispatchEvent(new ZipLoaderEvent(ZipLoaderEvent.ZIP_ASSET_READY, false, false, assetData));
		}
		
		protected function assetInitHandler(e:Event):void
		{
			var ldr:ZipAssetLoader 					= e.target.loader;
			var asset:DisplayObject					= ldr.content;
			var filename:String						= ldr.filename;
			var zipAssetData:ZipAssetDataObj		= new ZipAssetDataObj(filename, asset);
			
			ldr.removeEventListener(Event.INIT, assetInitHandler);
			
			dispatchAsset(zipAssetData);
			
			//trace("total files: " + totalFiles + " filesProcessed: " + filesProcessed);
			
			filesProcessed ++;
			if (totalFiles == filesProcessed && loadComplete) onZipComplete();
		}
		
		private function assetIOErrorHandler(e:IOErrorEvent):void 
		{
			trace("assetIOErrorHandler() " + e.text);
		}
		
		protected function onZipLoadComplete(e:Event):void 
		{
			totalFiles = _zip.getFileCount();
			loadComplete = true;
			dispatchEvent(new ZipLoaderEvent(ZipLoaderEvent.ZIP_LOAD_COMPLETE));
		}
		
		protected function onZipComplete(e:Event = null):void 
		{
			complete = true;
			dispatchEvent(new ZipLoaderEvent(ZipLoaderEvent.ZIP_PARSE_COMPLETE));
		}
		
		protected function onZipOpen(e:Event):void 
		{
			dispatchEvent(new ZipLoaderEvent(ZipLoaderEvent.ZIP_OPEN));
		}
				
		protected function onZipParseError(e:FZipErrorEvent):void 
		{
			trace("zip paresing error: " + e.text);
			dispatchEvent(new ZipLoaderEvent(ZipLoaderEvent.ZIP_PARSE_ERROR));
		}
		
		/*
		 *  Utilities
		 */////////////////////////////////////////////////////////
		
		protected function isValidFileExtension(filename:String):Boolean
		{
			var result:Boolean = false;
			var extension:String = filename.substr(filename.lastIndexOf("."), 4);
			
			for (var i:int = 0; i < VALID_FILE_EXTENSIONS.length; i++) 
			{
				if (VALID_FILE_EXTENSIONS[i] == extension)
				{
					result = true;
					break;
				}
			}
			
			//trace("does " + filename + " have a valid ext?: " + result);
			
			return result;
		}
	}

}
