require 'base64'
require 'openssl'
require 'digest/sha1'
require 'action_view'
require 'rails'

require 'universal_s3_uploader/engine'
require 'universal_s3_uploader/view_helper'

class ActionView::Base
	include UniversalS3Uploader::ViewHelper
end