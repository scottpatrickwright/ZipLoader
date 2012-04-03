package 
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import com.dummyTerminal.ZipUtils.ZipLoader;
	import com.dummyTerminal.ZipUtils.ZipLoaderEvent;
	import com.dummyTerminal.ZipUtils.ZipAssetDataObj;
	
	/*
	 *	Author: Scott Wright
	 *  scottpatrickwright@gmail.com
	 */ 
	

	public class Main extends Sprite 
	{
		static public const ZIP_FILE_URL:String = "assets/famfamfam_silk_icons_v013.zip";
		
		private var _zip:ZipLoader;
		private var _count:int = 0;
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			
			_zip = new ZipLoader();
			
			_zip.addEventListener(ZipLoaderEvent.ZIP_ASSET_READY, zipAssetReadyHandler);
			_zip.addEventListener(ZipLoaderEvent.ZIP_LOAD_COMPLETE, zipLoadCompleteHandler);
			_zip.addEventListener(ZipLoaderEvent.ZIP_PARSE_COMPLETE, zipParseCompleteHandler);
			_zip.addEventListener(ZipLoaderEvent.ZIP_PARSE_ERROR, zipParseErrorHandler);
			
			_zip.loadZipFile(ZIP_FILE_URL);
		}
		
		private function zipParseErrorHandler(e:ZipLoaderEvent):void 
		{
			trace("@Main zipParseErrorHandler");
		}
		
		private function zipParseCompleteHandler(e:ZipLoaderEvent):void 
		{
			trace("@Main zipParseCompleteHandler");
		}
		
		private function zipLoadCompleteHandler(e:ZipLoaderEvent):void 
		{
			trace("@Main zipLoadCompleteHandler");
		}
		
		private function zipAssetReadyHandler(e:ZipLoaderEvent):void 
		{
			//trace("@Main zipAssetReadyHandler " + e.loader.filename + " ready");
			trace(e.zipAsset.filename + " is ready. it is type " + e.zipAsset.type);
			var asset:DisplayObject = e.zipAsset.content;
			
			asset.x = 18 * (_count % 32);
			asset.y = 18 * Math.floor(_count / 32) + 20;
			addChild(asset);
			
			_count ++;
			
			
		}
		
	}
	
}