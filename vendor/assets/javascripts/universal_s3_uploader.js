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
      var context = this;
      var flashObject = this.element.children('object.flash_uploader').get(0);

      var interval = setInterval(function()
      {
        if (flashObject.sendFormData)
        {
          clearInterval(interval);

          flashObject.sendDivId(context.element.attr('id'));
          if (context.options.size)
          {
            flashObject.sendSize(context.options.size);
          }
          context.element.children('div').each(function ()
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
        if (this.options.onValidation(i, files[i].name) == true) this.upload(files[i], this.index++);
      }

      return false;
    };

    UniversalS3Uploader.prototype.dataUrlToBlob = function(dataUrl)
    {
      var byteString = atob(dataUrl.split(',')[1]);
      var ab = new ArrayBuffer(byteString.length);
      var ia = new Uint8Array(ab);
      var mimeString = dataUrl.split(',')[0].split(':')[1].split(';')[0];
      for (var i = 0; i < byteString.length; i++) {
        ia[i] = byteString.charCodeAt(i);
      }
      return new Blob([ab], { type: mimeString });
    };

    UniversalS3Uploader.prototype.resizeAndUpload = function(file, size)
    {
      var context = this;
      var img = document.createElement("img");
      img.src = window.URL.createObjectURL(file);
      img.onload = function()
      {
        var postfix = size[0];
        var width_desire = size[1];
        var height_desire = size[2];

        var width = img.width;
        var height = img.height;

        if (width_desire == -1 && height_desire == -1)
        {
          width_desire = width;
          height_desire = height;
        }
        else if (width_desire == -1)
        {
          width_desire = width * height_desire / height;
        }
        else if (height_desire == -1)
        {
          height_desire = height * width_desire / width;
        }

        var canvas = document.createElement('canvas');
        canvas.width = width_desire;
        canvas.height = height_desire;
        var ctx = canvas.getContext("2d");
        ctx.drawImage(img, 0, 0, width_desire, height_desire);
        var dataUrl = canvas.toDataURL("image/png");
        var blob = context.dataUrlToBlob(dataUrl);

        var fd = new FormData();
        context.element.children('div').each(function()
        {
          if (this.className == 'key' && postfix)
          {
            var new_filename = file.name.replace(/(\.[^.]+)$/, '_' + postfix + "$1");
            var key = $(this).data('value').replace(/\${filename}/, new_filename);
            fd.append('key', key);
          }
          else
          {
            fd.append(this.className, $(this).data('value'));
          }
        });
        fd.append('file', blob);

        var xhr = new XMLHttpRequest();
        xhr.open('POST', context.element.attr('action'), true);
        xhr.send(fd);
      };
    };

    UniversalS3Uploader.prototype.upload = function(file, index)
    {
      if (this.options.size)
      {
        for (var i = 0; i < this.options.size.length; i++)
        {
          this.resizeAndUpload(file, this.options.size[i]);
        }
      }

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