require 'net/http'
require 'json'
require 'one_authentication/user'
require 'one_authentication/version'
require 'one_authentication/configuration'
require 'one_authentication/rack_app_adapter'

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

  module Plugin
    class NotAuthorized < StandardError; end

    AUTHENTICATION_KEY = 'Authorization'

    def authenticate
      token = request.cookies[AUTHENTICATION_KEY] || request.headers[AUTHENTICATION_KEY]
      session_id = params['sessionId'] || params['session_id']
      if token.nil? && params['st'] && session_id
        token = exchange_token(params['st'], session_id)
      end
      return resolve_not_authorized unless token

      set_token_in_resp(token)
      begin
        @current_user = get_user(token)
      rescue NotAuthorized
        resolve_not_authorized
      end
    end

    def get_user(token)
      resp = send_request(auth_url('profile'), token)

      raise NotAuthorized if resp.code == '500'

      data = JSON.parse(resp.body)['data'].slice('name', 'position', 'avatar', 'mobile', 'email', 'userId')
      if user_table_name
        klass = Kernel.const_get(user_table_name.capitalize)
        column_names = if klass.respond_to?(:column_names)
                         klass.column_names
                       elsif klass.respond_to?(:fields)
                         klass.fields.keys
                       else
                         []
                       end

        return klass.find_by(ding_talk_id: data['userId']) if column_names.include?('ding_talk_id')
      else
        OneAuthentication::User.new(data)
      end
    end

    def get_all_user_attributes(token)
      resp = send_request(api_url('users'), token)

      JSON.parse(resp.body)['data']
    end

    def logout(token)
      send_request(auth_url('logout'), token)
    end

    private
    def exchange_token(ticket, session_id)
      uri = URI(exchange_token_url(ticket, session_id))
      resp = Net::HTTP.get(uri)

      return nil if JSON.parse(resp)['message'] == 'invalid session'

      JSON.parse(resp)['data']
    end

    def host
      OneAuthentication.configuration.authentication_center_host
    end

    def redirect_url
      OneAuthentication.configuration.redirect_url
    end

    def user_table_name
      OneAuthentication.configuration.app_user_table_name
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

    def redirect_to_auth_center
      auth_center_url = "#{host}/auth/login?redirect_url=#{CGI.escape(redirect_url)}"
      if respond_to?(:redirect_to)
        redirect_to auth_center_url
      elsif respond_to?(:redirect)
        redirect auth_center_url
      else
        raise UnknownRackApp
      end
    end

    def send_request(route ,token)
      uri = URI(route)
      req = Net::HTTP::Get.new(uri)
      req[AUTHENTICATION_KEY] = token
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') {|http| http.request(req) }
    end

    def resolve_not_authorized
      return redirect_to_auth_center if redirect_url

      message = 'Not Authorized'
      if respond_to?(:render)
        render message, :status => 401
      elsif respond_to?(:halt)
        halt message, :status => 401
      elsif respond_to?(:error!)
        error! message, :unauthorized
      else
        raise UnknownRackApp
      end
    end

    def set_token_in_resp(token)
      if redirect_url
        response.set_cookie(AUTHENTICATION_KEY, token)
      else
        response.set_header(AUTHENTICATION_KEY, token)
      end
    end
  end

end
