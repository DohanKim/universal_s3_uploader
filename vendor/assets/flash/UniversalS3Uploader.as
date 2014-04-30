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

	public class UniversalS3Uploader extends Sprite
	{
		private var button;
		private var files;
		private var id;
		private var params;
		
		private function log(str:*):void
		{
			ExternalInterface.call("console.log", str);
		}
		
		public function UniversalS3Uploader() 
		{
			getRequestData();
			makeButton();
		}
		
		private function getRequestData()
		{
			if (ExternalInterface.available)
			{
				params = new URLVariables();
				
				ExternalInterface.addCallback("sendDivId", receiveDivId);
				ExternalInterface.addCallback("sendFormData", receiveFormData);
				ExternalInterface.call("$('div.universal_s3_uploader').universal_s3_uploader().initExternalInterface");
			}
		}
		
		private function receiveDivId(id:String):void
		{
			this.id = id;
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
			var index = 0;
			for each (var file in files.fileList)
			{
				var validation:Boolean = ExternalInterface.call(instanceSelector() + ".options.onValidation", index);
				if (validation == true) upload(file, index);
				index++;
			}
		}
		
		private function upload(file:FileReference, index:int):void
		{
			var request:URLRequest = new URLRequest('http://' + params["bucket"] + '.s3.amazonaws.com');
			request.method = URLRequestMethod.POST;
			request.data = params;
			
			function passIndex(func:Function):Function
			{
				return function handler(evt:Event):void { func(index, evt); }
			}
			
			file.addEventListener(Event.OPEN, passIndex(openHandler));
			file.addEventListener(ProgressEvent.PROGRESS, passIndex(progressHandler));
			file.addEventListener(Event.COMPLETE, passIndex(completeHandler));
			file.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, passIndex(uploadCompleteDataHandler));
			
			file.upload(request, 'file');
		}
		
		private function openHandler(index:int, evt:Event):void
		{
			ExternalInterface.call(instanceSelector() + ".options.onLoadstart", index);
		}
		
		private function progressHandler(index:int, evt:ProgressEvent):void
		{
			var event = new Object();
			event.loaded = evt.bytesLoaded;
			event.total = evt.bytesTotal;
			ExternalInterface.call(instanceSelector() + ".options.onProgress", index, event);
		}
		
		private function completeHandler(index:int, evt:Event):void
		{
			ExternalInterface.call(instanceSelector() + ".options.onSuccess", index);
		}
		
		private function uploadCompleteDataHandler(index:int, evt:DataEvent):void
		{
			ExternalInterface.call(instanceSelector() + ".options.onResponse", index, evt.data);
		}
	}
}