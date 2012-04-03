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
		private static const MAX_ASSETS_TO_PROCESS_AT_A_TIME	:uint	=	32;
				
		private var _zip					:FZip;
		private var _currentFileIndex		:uint		= 0
		private var _zipFileUrl				:String		= "";
		
		private var complete				:Boolean	= false;
		private var processing				:Boolean	= false;
		
		public function ZipLoader() 
		{
			super();
			trace("new ZipLoader()");
		}
		
		public function reset():void 
		{
			_zip = null;
			_currentFileIndex = 0;
			_zipFileUrl = "";
			complete = false;
			
			if (_zip.hasEventListener(FZipErrorEvent.PARSE_ERROR)) 	_zip.removeEventListener(FZipErrorEvent.PARSE_ERROR, onZipParseError);
			if (_zip.hasEventListener(FZipEvent.FILE_LOADED)) 		_zip.removeEventListener(FZipEvent.FILE_LOADED, onZipAssetLoaded);
			if (_zip.hasEventListener(Event.OPEN)) 					_zip.removeEventListener(Event.OPEN, onZipOpen);
			if (_zip.hasEventListener(Event.COMPLETE)) 				_zip.removeEventListener(Event.COMPLETE, onZipLoadComplete);
			if ( hasEventListener(Event.ENTER_FRAME)) 				removeEventListener(Event.ENTER_FRAME, parseZipAssets);
			
			processing = false;
		}
		
		public function loadZipFile(zipFileUrl:String = null):void 
		{
			trace("loadZipFile(): " + zipFileUrl);
			
			if (processing) return;
			
			processing = true;
			_zip = new FZip();
			
			_zip.addEventListener(Event.OPEN, onZipOpen);
			_zip.addEventListener(ProgressEvent.PROGRESS, onZipLoadProgress);
			_zip.addEventListener(Event.COMPLETE, onZipLoadComplete);
			_zip.addEventListener(FZipEvent.FILE_LOADED, onZipAssetLoaded);
			_zip.addEventListener(FZipErrorEvent.PARSE_ERROR, onZipParseError);
			
			
			_zip.load(new URLRequest(zipFileUrl));
			trace("loading...");
		}
		
		private function onZipLoadProgress(e:ProgressEvent):void 
		{
			trace("zip load progress... bytesLoaded: " + e.bytesLoaded + " bytes total: " + e.bytesTotal) ;
			dispatchEvent(e);
		}
		
		public function destroy():void
		{
			reset();
			delete this;
		}
		
		private function onZipAssetLoaded(e:FZipEvent):void
		{
			trace("@Ziploader onZipAssetLoaded file: " + e.file.filename);
			if (e.file.filename.indexOf(".html") > -1) return;
			if (e.file.filename.indexOf(".txt") > -1) return;
			
			processAsset(e);
		}
		
		private function processAsset(e:FZipEvent):void 
		{
			trace("@ZipLoader processAsset() filename: " + e.file.filename);
			//trace("@ZipLoader processAsset() file.content: " + e.file.content);
						
			var file:FZipFile 						= e.file;
			var loader:ZipAssetLoader				= new ZipAssetLoader();
			loader.filename							= file.filename; //store filename of loaded asset so its accessible at INIT
			
			/*loader.addEventListener(Event.INIT, assetInitHandler);
			
			loader.addEventListener(Event.COMPLETE, completeHandler);
            loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
            loader.addEventListener(Event.INIT, initHandler);
            loader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            loader.addEventListener(Event.OPEN, openHandler);
            loader.addEventListener(ProgressEvent.PROGRESS, progressHandler);
            loader.addEventListener(Event.UNLOAD, unLoadHandler);
			*/
			trace("loadingBytes for " + file.filename +"...");
			loader.contentLoaderInfo.addEventListener(Event.INIT, dispatchLoader)
			loader.loadBytes(file.content);
			//dispatchLoader(loader);
						
		}
		
		 private function completeHandler(event:Event):void {
            trace("^^^^ completeHandler: " + event);
        }

        private function httpStatusHandler(event:HTTPStatusEvent):void {
            trace("^^^^ httpStatusHandler: " + event);
        }

        private function initHandler(event:Event):void {
            trace("^^^^ initHandler: " + event);
        }

        private function ioErrorHandler(event:IOErrorEvent):void {
            trace("^^^^ ioErrorHandler: " + event);
        }

        private function openHandler(event:Event):void {
            trace("^^^^ openHandler: " + event);
        }

        private function progressHandler(event:ProgressEvent):void {
            trace("^^^^ progressHandler: bytesLoaded=" + event.bytesLoaded + " bytesTotal=" + event.bytesTotal);
        }

        private function unLoadHandler(event:Event):void {
            trace("^^^^ unLoadHandler: " + event);
        }
		
		private function assetInitHandler(e:DataEvent):void
		{
			trace("@ZipLoader assetInitHandler() " + (e.target as ZipAssetLoader).filename);
			
			var asset:DisplayObject					= (e.target as ZipAssetLoader).content;
			var filename:String						= (e.target as ZipAssetLoader).filename;
			var zipAssetData:ZipAssetDataObj		= new ZipAssetDataObj(filename, asset);
			
			(e.target as ZipAssetLoader).removeEventListener(Event.INIT, assetInitHandler);
			
			dispatchAsset(zipAssetData);
		}
		
		private function dispatchAsset(assetData:ZipAssetDataObj):void
		{
			trace("@ZipLoader dispatchAsset() " + assetData.filename);
			dispatchEvent(new ZipLoaderEvent(ZipLoaderEvent.ZIP_ASSET_READY, false, false, assetData));
			
		}
		
		private function dispatchLoader(e:Event):void
		{
			var ldr:ZipAssetLoader = e.target.loader;
			dispatchEvent(new ZipLoaderEvent(ZipLoaderEvent.ZIP_ASSET_READY, false, false, null, ldr));
		}
		
		private function onZipLoadComplete(e:Event):void 
		{
			dispatchEvent(new ZipLoaderEvent(ZipLoaderEvent.ZIP_LOAD_COMPLETE));
		}
		
		private function onZipComplete(e:Event = null):void 
		{
			trace("/////////// onZipComplete ////////////");
			complete = true;
			removeEventListener(Event.ENTER_FRAME, parseZipAssets);
			dispatchEvent(new ZipLoaderEvent(ZipLoaderEvent.ZIP_PARSE_COMPLETE));
		}
		
		private function onZipOpen(e:Event):void 
		{
			trace("/////////// onZipOpen ////////////");
			startParseZip();
		}
		
		
		private function onZipParseError(e:FZipErrorEvent):void 
		{
			trace("@ZipLoader: Error on Parse Zip File: "  + e.text);
			dispatchEvent(new ZipLoaderEvent(ZipLoaderEvent.ZIP_PARSE_ERROR));
		}
		
		private function startParseZip():void 
		{
			trace("start parseing zip...")
			//start loop
			//addEventListener(Event.ENTER_FRAME, parseZipAssets); //frame loop needed to check for new asset availability as no native event is fired
		}
		
		private function parseZipAssets(e:Event = null):void 
		{
			trace("parseZipAssets...");
			var file:FZipFile;
			var loader:Loader;
			var asset:DisplayObject;
			var zipAssetData:ZipAssetDataObj;
			var type:Class;
			
			for (var i:uint = 0; i < MAX_ASSETS_TO_PROCESS_AT_A_TIME; i++) 
			{
				if (_zip.getFileCount() >= _currentFileIndex) 
				{
					trace("//// parse zip asset: " + _currentFileIndex);
					file	 			= _zip.getFileAt(_currentFileIndex);
					loader 				= new Loader();
					loader.loadBytes(file.content);
					asset				= loader.content;
					isSound(file.filename) ? type = Sound : type = DisplayObject;
					
					zipAssetData		= new ZipAssetDataObj(file.filename, asset);
										
					dispatchEvent(new ZipLoaderEvent(ZipLoaderEvent.ZIP_ASSET_READY, false, false, zipAssetData));
					_currentFileIndex ++;
					trace(file.filename + " processed");
					continue;
				} 
				onZipComplete();
				break;
				
			}
		}
		
		//searches file name for know audio extensions
		private function isSound(filename:String):Boolean
		{
			return filename.indexOf(".mp3") > -1 || filename.indexOf(".wav") > -1; 
			
		}
	}
}
