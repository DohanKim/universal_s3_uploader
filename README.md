universal_s3_uploader
=====================

This library helps you to upload files to the Amazon S3 Server with AJAX techniques in almost of browser environments such as IE, FF and Chrome.

It checks whether HTML5 FormData functionality is available in the given environment, and if not (usually happen in low version of IE), it loads Flash object to make multi file uploading and progess observation are still possible.
So it makes user could upload multiple files at once, and observe progess in most of the browser environments including IE 5+. It also help users to resize images directly at client-side.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'universal_s3_uploader'
```


Add require command at the `application.js` file. The jQuery plugin is necessary to use this gem.

**app/assets/javascripts/application.js**
```js
//= require jquery
//= require jquery_ujs
//= require universal_s3_uploader
```


Create `amazon.yml` file at the `config` directory and write `access_key_id` and `secret_access_key` in it. Also add upload policies which you want. These policies will be used at the next step.

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


Make sure your AWS S3 CORS settings for your bucket look something like this:
```xml
<CORSConfiguration>
    <CORSRule>
        <AllowedOrigin>http://0.0.0.0:3000</AllowedOrigin>
        <AllowedMethod>GET</AllowedMethod>
        <AllowedMethod>POST</AllowedMethod>
        <AllowedMethod>PUT</AllowedMethod>
        <MaxAgeSeconds>3000</MaxAgeSeconds>
        <AllowedHeader>*</AllowedHeader>
    </CORSRule>
</CORSConfiguration>
```


Create `crossdomain.xml` file at the root of your bucket.

**crossdomain.xml**
```xml
<cross-domain-policy>
<allow-access-from domain="*" secure="false"/>
</cross-domain-policy>
```


## Usage

Now you can use universal_s3_uploader tag helper in any view files. This helper function gets three parameters. The first one is a file's key and the next one is a policy name which specified at the previous step. And the last one is the div tag's id.

```ruby
universal_s3_uploader_tag('key', 'policy_name', 'id')
```

for example,

**app/views/users/new.html.erb**
```ruby
<%= universal_s3_uploader_tag('user_profile_images/${filename}', 'policy', 'profile_image_uploader') %>
```


Invoke `universal_s3_uploader` jQuery function to the div tag made by previous step. You can give `size` array and `onValidation, onLoadstart, onProgress, onSuccess, onResponse` callbacks as option. Each function's form is same as below.

```js
$('div.universal_s3_uploader').universal_s3_uploader({
    size: [['small', 300, -1], ['medium', 800, -1]],
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
});
```
`size`: array of sizes. According this options, additional resized images will be uploaded. A Element of this array also should be size-3-array as [postfix, width, height]. Postfix will be attatched at the end of resized file name. One attribute among width and height could be -1, and in this case width or height will be set automatically according to width/height ratio.

In every callback functions, there are `index` parameter so you can use it as identifying specific file in multiple file uploading environment.

`onValidation`: validates whether the file should be uploaded or not. If it returns false, the file will not be uploaded. This feature would be used to restrict number of files uploaded.

`onLoadstart`: invoked when uploading is starting.

`onProgress`: when uploading is ongoing, this will be invoked repeatedly. You can use `event.loaded` and `event.total` to check how much amount of a file is uploaded.

`onSuccess`: invoked when uploading is end.

`onResponse`: invoked at the last. `response` has AJAX response data.
