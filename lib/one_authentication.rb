require 'net/http'
require 'json'
require 'one_authentication/user'
require 'one_authentication/version'
require 'one_authentication/configuration'

module OneAuthentication
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end

  class Service
    class Error < StandardError; end

    AUTHENTICATION_KEY = 'Authorization'

    class << self
      def get_user(token)
        resp = request(auth_url('profile'), token)

        data = JSON.parse(resp.body)['data'].slice('name', 'position', 'avatar', 'mobile', 'email')
        OneAuthentication::User.new(data)
      end

      def get_all_user_attributes(token)
        resp = request(api_url('users'), token)

        JSON.parse(resp.body)['data']
      end

      def exchange_token(ticket, session_id)
        uri = URI(exchange_token_url(ticket, session_id))

        resp = Net::HTTP.get(uri)
        JSON.parse(resp)['data']
      end

      def logout(token)
        request(auth_url('logout'), token)
      end

      private
      def host
        OneAuthentication.configuration.authentication_host
      end

      def api_url(path)
        "#{host}/api/#{path}"
      end

      def auth_url(path)
        "#{host}/auth/#{path}"
      end

      def exchange_token_url(ticket, session_id)
        "#{host}/auth/token?st=#{ticket}&sessionId=#{session_id}"
      end

      def request(route ,token)
        uri = URI(route)
        req = Net::HTTP::Get.new(uri)
        req[AUTHENTICATION_KEY] = token
        Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') {|http| http.request(req) }
      end
    end
  end
end
