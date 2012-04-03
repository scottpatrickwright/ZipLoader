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
	
	
	public class ZipLoader extends EventDispatcher 
	{
		protected static const MAX_ASSETS_TO_PROCESS_AT_A_TIME	:uint							=	32;
				
		protected var _zip										:FZip;
		protected var _zipFileUrl								:String							= "";
		
		protected var allZipAssetLoaders						:Vector.<ZipAssetLoader>		= new Vector.<ZipAssetLoader>();
		
		protected var complete									:Boolean						= false;
		protected var processing								:Boolean						= false;
		
		public function ZipLoader() 
		{
			super();
		}
		
		public function reset():void 
		{
			_zip = null;
			_zipFileUrl = "";
			complete = false;
			
			if (_zip.hasEventListener(FZipErrorEvent.PARSE_ERROR)) 	_zip.removeEventListener(FZipErrorEvent.PARSE_ERROR, onZipParseError);
			if (_zip.hasEventListener(FZipEvent.FILE_LOADED)) 		_zip.removeEventListener(FZipEvent.FILE_LOADED, onZipAssetLoaded);
			if (_zip.hasEventListener(Event.OPEN)) 					_zip.removeEventListener(Event.OPEN, onZipOpen);
			if (_zip.hasEventListener(Event.COMPLETE)) 				_zip.removeEventListener(Event.COMPLETE, onZipLoadComplete);
			
			processing = false;
		}
		
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
		
		protected function onZipLoadProgress(e:ProgressEvent):void 
		{
			dispatchEvent(e);
		}
		
		public function destroy():void
		{
			reset();
			clearLoaders();
			delete this;
		}
		
		protected function clearLoaders():void
		{
			var ldr:ZipAssetLoader;
			
			while (allZipAssetLoaders.length) 
			{
				allZipAssetLoaders.pop().destroy();
			}
		}
		
		protected function onZipAssetLoaded(e:FZipEvent):void
		{
			//TODO handle valid file types better
			if (e.file.filename.indexOf(".html") > -1) return;
			if (e.file.filename.indexOf(".txt") > -1) return;
			
			processAsset(e);
		}
		
		protected function processAsset(e:FZipEvent):void 
		{
			var file:FZipFile 						= e.file;
			var loader:ZipAssetLoader				= new ZipAssetLoader(); //custom loader allows extra props to travel with event obj
			loader.filename							= file.filename; //store filename of loaded asset so its accessible at INIT
			
			loader.contentLoaderInfo.addEventListener(Event.INIT, assetInitHandler)
			loader.loadBytes(file.content);
		}
		
		protected function assetInitHandler(e:Event):void
		{
			var ldr:ZipAssetLoader 					= e.target.loader;
			var asset:DisplayObject					= ldr.content;
			var filename:String						= ldr.filename;
			var zipAssetData:ZipAssetDataObj		= new ZipAssetDataObj(filename, asset);
			
			ldr.removeEventListener(Event.INIT, assetInitHandler);
			
			dispatchAsset(zipAssetData);
		}
		
		protected function dispatchAsset(assetData:ZipAssetDataObj):void
		{
			dispatchEvent(new ZipLoaderEvent(ZipLoaderEvent.ZIP_ASSET_READY, false, false, assetData));
		}
		
		protected function onZipLoadComplete(e:Event):void 
		{
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
			dispatchEvent(new ZipLoaderEvent(ZipLoaderEvent.ZIP_PARSE_ERROR));
		}
	
	}
}
