module UniversalS3Uploader
	module ViewHelper
		def universal_s3_uploader_tag(key, policy_name, id)
			uh = UploaderHelper.new(policy_name)

			uh.tags(key, id).html_safe
		end

		class UploaderHelper
			def initialize(policy_name)
				@config = YAML.load_file("#{Rails.root.to_s}/config/amazon.yml")
				set_policy(policy_name)
				set_bucket
			end

			# set expiration time
			def set_policy(policy_name)
				@policy = @config[policy_name]
				@policy['conditions'] << ["starts-with", "$Filename", ""]	# for Flash upload
				if @policy['expiration'] == '' || @policy['expiration'].nil?
					@policy['expiration'] = 1.hour.from_now.gmtime.iso8601
				end
			end

			# extract bucket name
			def set_bucket
				@policy['conditions'].each do |condition|
					if condition.class == Hash && condition.keys.first == 'bucket'
						@bucket = condition.values.first
						return
					end
				end

				raise 'No bucket name in policy Exception'
			end

			def tags(key, id)
				av = ActionView::Base.new

				def div_tag(name, value)
					"<div class=#{name} data-value=#{value}></div>"
				end

				tag = "<div class='universal_s3_uploader' id='#{id}' action='#{url}'>"

				([{key: key}] + @policy['conditions']).each do |condition|
					if condition.class == Hash
						tag += div_tag condition.keys.first, condition.values.first
					elsif condition.class == Array
						if condition[0] == 'eq' || condition[0] == 'starts-with'
							tag += div_tag condition[1][1..-1], condition[2] unless condition[1] == '$key'
						end
					else
						raise 'Something in policy unexpected'
					end
				end
				tag += div_tag 'AWSAccessKeyId', @config['access_key_id']
				tag += div_tag 'Policy', policy_encoded
				tag += div_tag 'Signature', signature
				tag += av.file_field_tag :file, multiple: true, accept: 'image/*'

				object_id = 'flash_' + id
				tag += "<object id=#{'flash_' + id} class='flash_uploader' classid='clsid:d27cdb6e-ae6d-11cf-96b8-444553540000' codebase='http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=11,1,0,0'>"
				tag += '<param name="movie" value="/assets/UniversalS3Uploader.swf">'
				tag += '<param name="wmode" value="transparent">'
				tag += '</object>'
				tag += '</div>'
			end

			def bucket
				@bucket
			end

			def url
				"http://#{@bucket}.s3.amazonaws.com"
			end

			def policy_encoded
				Base64.encode64(@policy.to_json).gsub("\n","")
			end

			def signature
				Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), @config['secret_access_key'], policy_encoded)).gsub("\n","")
			end
		end
	end
end