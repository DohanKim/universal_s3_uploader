package  
{	
	import flash.display.Sprite; 
	import flash.events.MouseEvent;
	import flash.net.FileReferenceList;
	import flash.events.Event;
	import flash.net.FileReference;
	import flash.external.ExternalInterface;
	import flash.net.URLVariables;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.FileFilter;
	import flash.events.ProgressEvent;
	import flash.display.Stage;
	import flash.events.DataEvent;
	import flash.display.Loader;
	import flash.display.Bitmap;
	import flash.utils.ByteArray;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import JPEGEncoder;
	import mx.utils.Base64Encoder;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import UploadPostHelper;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequestHeader;

	public class UniversalS3Uploader extends Sprite
	{
		private var button;
		private var files;
		private var id;
		private var size;
		private var params;
		private	var index;
		
		private function log(str:*):void
		{
			ExternalInterface.call("console.log", str);
		}
		
		public function UniversalS3Uploader() 
		{
			index = 0;
			getDataFromJavascript();
			makeButton();
		}
		
		private function getDataFromJavascript()
		{
			if (ExternalInterface.available)
			{
				params = new URLVariables();
				
				ExternalInterface.addCallback("sendDivId", receiveDivId);
				ExternalInterface.addCallback("sendSize", receiveSize);
				ExternalInterface.addCallback("sendFormData", receiveFormData);
			}
		}
		
		private function receiveDivId(id:String):void
		{
			this.id = id;
		}
		
		private function receiveSize(size:Array):void
		{
			this.size = size;
			size[size.length] = ['', -1, -1];
		}
		
		private function receiveFormData(name:String, value:String):void
		{
			params[name] = value;
		}
		
		private function makeButton():void
		{
			button = new Sprite();
			button.graphics.beginFill(0x0000ff, 0);
			button.graphics.drawRect(0,0,100,100);
			button.graphics.endFill();
			button.buttonMode = true;
			button.addEventListener(MouseEvent.CLICK, clickHandler);
			
			addChild(button);
		}
		
		private function clickHandler(evt:MouseEvent):void
		{
			files = new FileReferenceList();
			files.addEventListener(Event.SELECT, selectHandler);
			var imageTypes:FileFilter = new FileFilter("Images (*.jpg, *.jpeg, *.gif, *.png)", "*.jpg; *.jpeg; *.gif; *.png"); 
			files.browse(new Array(imageTypes));
		}
		
		private function instanceSelector():String
		{
			return "$('div#" + id + "').universal_s3_uploader()";
		}
		
		private function selectHandler(evt:Event):void
		{
			for each (var file in files.fileList)
			{
				var validation:Boolean = ExternalInterface.call(instanceSelector() + ".options.onValidation", index, file.name);
				if (validation == true) 
				{
					resizeAndUpload(file, index);
				}
				index++;
			}
		}
		
		private function resizeAndUpload(file:FileReference, index:int):void
		{			
			file.addEventListener(Event.COMPLETE, onFileLoaded);
			file.load();
		
			function onFileLoaded(evt:Event):void
			{
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onContentLoaderComplete);
				loader.loadBytes(evt.target.data);
			}
		
			function onContentLoaderComplete(evt:Event):void
			{
				var loader:Loader = evt.target.loader;
				var bitmapData:BitmapData = evt.target.content.bitmapData;
				var originalKey = params.key;
				
				for (var i = 0; i < size.length; i++)
				{
					var postfix = size[i][0];
					var width_desire = size[i][1];
					var height_desire = size[i][2];
				
					if (width_desire == -1 && height_desire == -1)
					{
						width_desire = bitmapData.width;
						height_desire = bitmapData.height;
					}
					else if (width_desire == -1)
					{
						width_desire = bitmapData.width * height_desire / bitmapData.height;
					}
					else if (height_desire == -1)
					{
						height_desire = bitmapData.height * width_desire / bitmapData.width;
					}
					
					var newBitmapData:BitmapData = new BitmapData(width_desire, height_desire);
					var matrix:Matrix = new Matrix();
					matrix.scale(newBitmapData.width / bitmapData.width, newBitmapData.height / bitmapData.height);
					newBitmapData.draw(bitmapData, matrix);
					var newImage:ByteArray = new JPEGEncoder().encode(newBitmapData);
									
					if (postfix == '')
					{
						params.key = originalKey;
					}
					else
					{
						var new_filename = file.name.replace(/(\.[^.]+)$/, '_' + postfix + "$1");
						params.key = originalKey.replace(/\${filename}/, new_filename);
					}
										
					var request:URLRequest = new URLRequest('http://' + params["bucket"] + '.s3.amazonaws.com');
					request.requestHeaders.push(new URLRequestHeader('Content-type', 'multipart/form-data; boundary=' + UploadPostHelper.getBoundary()));
					request.method = URLRequestMethod.POST;
					request.data = UploadPostHelper.getPostData(file.name, newImage, params);
					
					function passIndexFilename(func:Function):Function
					{
						return function handler(evt:Event):void { func(index, file.name, evt); }
					}
	
					var urlLoader = new URLLoader();
					if (i == 0)
					{
						urlLoader.addEventListener(Event.OPEN, passIndexFilename(openHandler));
					}
					if (i == size.length - 1)
					{
						
						urlLoader.addEventListener(ProgressEvent.PROGRESS, passIndexFilename(progressHandler));
						urlLoader.addEventListener(Event.COMPLETE, passIndexFilename(completeHandler));
					}
					urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
					urlLoader.load(request);
				}
			}
		}
				
		private function openHandler(index:int, filename:String, evt:Event):void
		{
			ExternalInterface.call(instanceSelector() + ".options.onLoadstart", index, filename);
		}
		
		private function progressHandler(index:int, filename:String, evt:ProgressEvent):void
		{
			var event = new Object();
			event.loaded = evt.bytesLoaded;
			event.total = evt.bytesTotal;
			ExternalInterface.call(instanceSelector() + ".options.onProgress", index, filename, event);
		}
		
		private function completeHandler(index:int, filename:String, evt:Event):void
		{
			ExternalInterface.call(instanceSelector() + ".options.onSuccess", index, filename);
			ExternalInterface.call(instanceSelector() + ".options.onResponse", index, filename, evt.target.data);
		}
	}
}