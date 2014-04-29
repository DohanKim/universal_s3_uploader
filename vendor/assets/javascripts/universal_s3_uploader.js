(function($)
{
  $.fn.universal_s3_uploader = function(options)
  {
    if (!this.universalS3UploaderInstance)
    {
      this.universalS3UploaderInstance = new UniversalS3Uploader(this, options);
    }

    return this.universalS3UploaderInstance;
  };

  var defaultOptions =
  {
    onLoadstart: function(index, event)
    {
      console.log(index + " will be uploaded.");
    },
    onProgress: function(index, event)
    {
      var percentage = Math.round(event.loaded * 100 / event.total);
      console.log(percentage + " %");
    },
    onSuccess: function(index, event)
    {
      console.log(index + " was successfully uploaded.");
    },
    onResponse: function(index, response)
    {
      console.log(response);
    }
  };

  var supportFormData = window.FormData;

  UniversalS3Uploader = (function()
  {
    function UniversalS3Uploader(element, options)
    {
      this.element = $(element);
      this.options = $.extend({}, defaultOptions, options);

      this.init();
    }

    UniversalS3Uploader.prototype.init = function()
    {
      this.element.children('div').remove();

      if (supportFormData)  // if supports HTML5 FormData
      {
        this.element.children('object#flashUploader').remove();

        this.element.children('input[type=file]').change(function()
        {
          $(this).parent().trigger('submit');
          $(this).replaceWith($(this).clone(true));
        });

        this.element.submit($.proxy(this.submit, this));
      }

      else  // use Flash uploader
      {
        var flashObject = this.element.children('object').get(0);
        var fileField = this.element.children('input[type=file]');

        $(flashObject).css("height", fileField.height()+10 + "px").css("width", fileField.width() + "px");
        $(flashObject).css("position", "relative").css("left", "-" + fileField.width() + "px").css("top", "6px");
      }
    };

    UniversalS3Uploader.prototype.initExternalInterface = function()
    {
      if (!supportFormData)
      {
        var flashObject = this.element.children('object').get(0);

        this.element.children('input[type=hidden]').each(function ()
        {
          flashObject.sendFormData(this.name, this.value);
        });
      }
    };

    UniversalS3Uploader.prototype.submit = function()
    {
      var files = this.element.children('input[type=file]').get(0).files || [this.element.children('input[type=file]').val()];
      for (var i = 0, len = files.length; i < len; i++) this.upload(files[i], i);

      return false;
    };

    UniversalS3Uploader.prototype.upload = function(file, index)
    {
      var fd = new FormData();
      this.element.children('input[type=hidden]').each(function()
      {
        fd.append(this.name, this.value);
      });
      fd.append('file', file);

      function passIndex(func)
      {
        return function(event) { $.proxy(func, this)(index, event); }
      }

      var onResponse = this.options.onResponse;
      function callResponseHandler(event)
      {
        onResponse(index, this.response);
      }

      var xhr = new XMLHttpRequest();

      xhr.addEventListener("loadstart", passIndex(this.options.onLoadstart), false);
      xhr.upload.addEventListener("progress", passIndex(this.options.onProgress), false);
      xhr.addEventListener("load", passIndex(this.options.onSuccess), false);
      xhr.addEventListener("load", callResponseHandler, false);

      xhr.open('POST', this.element.attr('action'), true);
      xhr.send(fd);
    };

    return UniversalS3Uploader;
  })();
})(jQuery);