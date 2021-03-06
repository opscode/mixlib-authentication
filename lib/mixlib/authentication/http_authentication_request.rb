#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) 2010-2018 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative "../authentication"

module Mixlib
  module Authentication
    class HTTPAuthenticationRequest

      MANDATORY_HEADERS = %i{x_ops_sign x_ops_userid x_ops_timestamp host x_ops_content_hash}.freeze

      attr_reader :request

      def initialize(request)
        @request = request
        @request_signature = nil
        validate_headers!
      end

      def headers
        @headers ||= @request.env.inject({}) { |memo, kv| memo[$2.tr("-", "_").downcase.to_sym] = kv[1] if kv[0] =~ /^(HTTP_)(.*)/; memo }
      end

      def http_method
        @request.method.to_s
      end

      def path
        @request.path.to_s
      end

      def signing_description
        headers[:x_ops_sign].chomp
      end

      def user_id
        headers[:x_ops_userid].chomp
      end

      def timestamp
        headers[:x_ops_timestamp].chomp
      end

      def host
        headers[:host].chomp
      end

      def content_hash
        headers[:x_ops_content_hash].chomp
      end

      def server_api_version
        (headers[:x_ops_server_api_version] || DEFAULT_SERVER_API_VERSION).chomp
      end

      def request_signature
        unless @request_signature
          @request_signature = headers.find_all { |h| h[0].to_s =~ /^x_ops_authorization_/ }
            .sort { |x, y| x.to_s[/\d+/].to_i <=> y.to_s[/\d+/].to_i }.map { |i| i[1] }.join("\n")
          Mixlib::Authentication::Log.trace "Reconstituted (user-supplied) request signature: #{@request_signature}"
        end
        @request_signature
      end

      def validate_headers!
        missing_headers = MANDATORY_HEADERS - headers.keys
        unless missing_headers.empty?
          missing_headers.map! { |h| h.to_s.upcase }
          raise MissingAuthenticationHeader, "missing required authentication header(s) '#{missing_headers.join("', '")}'"
        end
      end
    end
  end
end
