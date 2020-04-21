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
    class NotAuthorized < StandardError; end

    AUTHENTICATION_KEY = 'Authorization'

    class << self
      def get_user(token)
        resp = request(auth_url('profile'), token)

        raise NotAuthorized if resp.code == '500'

        data = JSON.parse(resp.body)['data'].slice('name', 'position', 'avatar', 'mobile', 'email', 'userid')
        if user_table_name
          klass = Kernel.const_get(user_table_name.capitalize)
          column_names = if klass.respond_to?(:column_names)
                           klass.column_names
                         elsif klass.respond_to?(:fields)
                           klass.fields.keys
                         else
                           []
                         end

          return klass.find_by(ding_talk_id: data['userid']) if column_names.include?('ding_talk_id')
        end

        OneAuthentication::User.new(data)
      end

      def get_all_user_attributes(token)
        resp = request(api_url('users'), token)

        JSON.parse(resp.body)['data']
      end

      def exchange_token(ticket, session_id)
        uri = URI(exchange_token_url(ticket, session_id))
        resp = Net::HTTP.get(uri)

        raise NotAuthorized if JSON.parse(resp)['message'] == 'invalid session'

        JSON.parse(resp)['data']
      end

      def logout(token)
        request(auth_url('logout'), token)
      end

      private
      def host
        OneAuthentication.configuration.authentication_center_host
      end

      def user_table_name
        OneAuthentication.configuration.user_table_name
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
