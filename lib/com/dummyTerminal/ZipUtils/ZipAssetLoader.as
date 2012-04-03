package com.dummyTerminal.ZipUtils 
{
	import flash.display.Loader;
		
	public class ZipAssetLoader extends Loader 
	{
		private var _filename:String = "";
		
		public function ZipAssetLoader() 
		{
			super();
			
		}
		
		public function get filename():String 
		{
			return _filename;
		}
		
		public function set filename(value:String):void 
		{
			_filename = value;
		}
		
		
		public function destroy():void
		{
			close();
			delete this;
		}
		
		
	}

}