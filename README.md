universal_s3_uploader
=====================

This library helps you to upload files to the Amazon S3 Server with AJAX techniques in almost of browser environments such as IE, FF and Chrome.

It checks whether HTML5 FormData functionality is available in the given environment, and if not, it loads Flash object to make multi file uploading and progess observation are still possible.
So it makes user could upload multiple files at once, and observe progess in the most of browser environments.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'universal_s3_uploader'
```


Add require command at the application.js file. The jQuery plugin is necessary to use this gem.

**app/assets/javascripts/application.js**
```js
//= require jquery
//= require jquery_ujs
//= require universal_s3_uploader
```


Create 'amazon.yml' file at the application's root path and write 'access_key_id' and 'secret_access_key' in it. Also add upload policies which you want. These policies will be used at the next step.

**config/amazon.yml**
```yml
access_key_id: 	    "YOUR_ACCESS_KEY_ID"
secret_access_key: 	"YOUR_SECRET_ACCESS_KEY"

policy:
  { "expiration": "",
      "conditions": [
        {"bucket": "bucket"},
        ["starts-with", "$key", ""],
        {"acl": "public-read"},
        {"success_action_status": "201"},
      ]
  }
```


Now you can use universal_s3_upload form helper in any view files. This helper function gets two parameters. The first one is a file's key and next one is a policy name which you specified at the previous step.

```ruby
universal_s3_uploader_tag('key', 'policy_name')
```

for example,

**app/views/users/new.html.erb**
```ruby
<%= universal_s3_uploader_tag('user_profile_images/${filename}', 'policy') %>
```


Invoke 'universal_s3_uploader' function to the form helper used at the previous step. You can give 'onLoadstart, onProgress, onSuccess, onResponse' callbacks as option. Each function's form is same as below.

```js
$('form.universal_s3_uploader').universal_s3_uploader({
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
});
```