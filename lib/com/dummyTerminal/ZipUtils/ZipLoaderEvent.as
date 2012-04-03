package com.dummyTerminal.ZipUtils 
{
	import flash.display.DisplayObject;
	import flash.events.Event;
		
	public class ZipLoaderEvent extends Event 
	{
		public static const ZIP_ASSET_READY			:String 		= "zipAssetReady";
		public static const ZIP_LOAD_COMPLETE		:String			= "zipLoadComplete";
		public static const ZIP_PARSE_COMPLETE		:String 		= "zipParseComplete";
		public static const ZIP_PARSE_ERROR			:String			= "zipParseError";
						
		private var _zipAsset:ZipAssetDataObj;
		private var _loader:ZipAssetLoader;
		
		public function ZipLoaderEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false, zipAsset:ZipAssetDataObj = null, loader:ZipAssetLoader = null) 
		{
			super(type, bubbles, cancelable);
			
			_zipAsset 		= zipAsset;
			_loader 		= loader;
		}
		
		public function get zipAsset():ZipAssetDataObj 
		{
			return _zipAsset;
		}
		
		public function get loader():ZipAssetLoader 
		{
			return _loader;
		}
		
	}

}   