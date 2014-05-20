(function($)
{
  $.fn.universal_s3_uploader = function(options)
  {
    var instance = $.data(this.get(0), 'universalS3UploaderInstance');

    if (!instance)
    {
      instance = $.data(this.get(0), 'universalS3UploaderInstance', new UniversalS3Uploader(this, options));
    }

    return instance;
  };

  var defaultOptions =
  {
    onValidation: function(index, filename, event)
    {
      return true;
    },
    onLoadstart: function(index, filename, event)
    {
      console.log(index + " will be uploaded.");
    },
    onProgress: function(index, filename, event)
    {
      var percentage = Math.round(event.loaded * 100 / event.total);
      console.log(percentage + " %");
    },
    onSuccess: function(index, filename, event)
    {
      console.log(index + " was successfully uploaded.");
    },
    onResponse: function(index, filename, response)
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
      this.index = 0;

      this.init();
    }

    UniversalS3Uploader.prototype.init = function()
    {
      if (supportFormData)  // if supports HTML5 FormData
      {
        this.element.children('object.flash_uploader').remove();

        this.element.children('input[type=file]').change(function()
        {
          $(this).parent().trigger('submit');
          $(this).replaceWith($(this).clone(true));
        });

        this.element.submit($.proxy(this.submit, this));
      }

      else  // use Flash uploader
      {
        var flashObject = this.element.children('object.flash_uploader').get(0);
        var fileField = this.element.children('input[type=file]');

        $(flashObject).css("height", fileField.height()+10 + "px").css("width", fileField.width() + "px");
        $(flashObject).css("position", "relative").css("left", "-" + fileField.width() + "px").css("top", "6px");

        this.initExternalInterface();
      }
    };

    UniversalS3Uploader.prototype.initExternalInterface = function()
    {
      var elem = this.element;
      var flashObject = this.element.children('object.flash_uploader').get(0);

      var interval = setInterval(function()
      {
        if (flashObject.sendFormData)
        {
          clearInterval(interval);

          flashObject.sendDivId(elem.attr('id'));
          elem.children('div').each(function ()
          {
            flashObject.sendFormData(this.className, $(this).data('value'));
          });
        }
      }, 100);
    };

    UniversalS3Uploader.prototype.submit = function()
    {
      var files = this.element.children('input[type=file]').get(0).files || [this.element.children('input[type=file]').val()];
      for (var i = 0, len = files.length; i < len; i++)
      {
        if (this.options.onValidation(i) == true) this.upload(files[i], this.index++);
      }

      return false;
    };

    UniversalS3Uploader.prototype.upload = function(file, index)
    {
      var fd = new FormData();
      this.element.children('div').each(function()
      {
        fd.append(this.className, $(this).data('value'));
      });
      fd.append('file', file);

      function passIndexFilename(func)
      {
        return function(event) { $.proxy(func, this)(index, file.name, event); }
      }

      var onResponse = this.options.onResponse;
      function callResponseHandler(event)
      {
        onResponse(index, file.name, this.response);
      }

      var xhr = new XMLHttpRequest();

      xhr.addEventListener("loadstart", passIndexFilename(this.options.onLoadstart), false);
      xhr.upload.addEventListener("progress", passIndexFilename(this.options.onProgress), false);
      xhr.addEventListener("load", passIndexFilename(this.options.onSuccess), false);
      xhr.addEventListener("load", callResponseHandler, false);

      xhr.open('POST', this.element.attr('action'), true);
      xhr.send(fd);
    };

    return UniversalS3Uploader;
  })();
})(jQuery);