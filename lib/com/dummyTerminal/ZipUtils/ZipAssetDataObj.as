package com.dummyTerminal.ZipUtils 
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.media.Sound;
	
	public class ZipAssetDataObj 
	{
		
		private var _filename:String = "";
		private var _content:DisplayObject;
		private var _type:Class;
		
		public function ZipAssetDataObj(filename:String, content:DisplayObject, type:Class = null) 
		{
			_filename = filename;
			_content = content;
			_type = type;
		}
		
		public function get filename():String 
		{
			return _filename;
		}
		
		public function get content():DisplayObject 
		{
			return _content;
		}
		
		public function get type():Class 
		{
			if (_type != null) return _type; 
			if (_filename.indexOf(".mp3") > -1 || _filename.indexOf(".wav") > -1) 										return Sound; 
			if (_filename.indexOf(".png") > -1 || _filename.indexOf(".jpg") > -1 || _filename.indexOf(".gif") > -1) 	return Bitmap; 
			if (_filename.indexOf(".swf") > -1) 																		return MovieClip; 
						
			return _type;
		}
			
		
	}

}