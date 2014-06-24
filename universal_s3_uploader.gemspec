require File.expand_path('../lib/universal_s3_uploader/version', __FILE__)

Gem::Specification.new do |s|
	s.name        = "universal_s3_uploader"
	s.version     = UniversalS3Uploader::VERSION
	s.summary     = "the AJAX S3 Uploader working in Cross Browser"
	s.date        = "2014-06-25"
	s.description = "This library helps you to upload files to the Amazon S3 Server with AJAX techniques in almost of browser environments such as IE, FF and Chrome."
	s.authors     = ["Dohan Kim"]
	s.email       = ["hodoli2776@kaist.ac.kr"]
	s.homepage    = ""
	s.files       = Dir["lib/**/*.rb", "vendor/assets/javascripts/*", "vendor/assets/flash/*.swf"]
	s.homepage    = "http://rubygems.org/gems/universal_s3_uploader"
	s.license     = "MIT"
end