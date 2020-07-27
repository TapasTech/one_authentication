require 'net/http'
require 'json'
require 'one_authentication/user'
require 'one_authentication/version'
require 'one_authentication/configuration'
require 'one_authentication/utils'

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
    include Utils

    class NotAuthorized < StandardError; end
    class UnknownRackApp < StandardError; end

    AUTHENTICATION_KEY = 'Authorization'

    def authenticate
      token = get_token_in_request
      return nil unless token

      set_token_in_resp(token)
      begin
        @current_user = get_user(token)
      rescue NotAuthorized
        nil
      end
    end

    def authenticate!
      token = get_token_in_request
      return resolve_not_authorized unless token

      set_token_in_resp(token)
      @current_user = get_user(token)
    end

    def authorize!(privilege_name)
      resolve_not_authorized unless @current_user

      owned_privileges = @current_user.privileges.map { |h| h['name'] }
      resolve_no_permission if owned_privileges.exclude?(privilege_name)
    end

    def get_user(token)
      raise NotAuthorized if token.nil?

      resp = send_request(generate_url('auth/profile', { app_key: app_key }), token)
      raise NotAuthorized unless resp.code.start_with?('2')

      data = JSON.parse(resp.body)['data'].slice('name', 'position', 'avatar', 'mobile', 'email', 'userId', 'privileges')
      data.transform_keys!{ |key| underscore(key) }
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
      resp = send_request(generate_url('api/users'), token)

      JSON.parse(resp.body)['data']
    end

    def logout(token)
      send_request(generate_url('auth/logout'), token)
    end

    def get_token
      session_id = params['sessionId'] || params['session_id']
      exchange_token(params['st'], session_id)
    end

    private
    def exchange_token(ticket, session_id)
      url = generate_url('auth/token', { st: ticket, session_id: session_id })
      resp = Net::HTTP.get(URI(url))

      return nil if JSON.parse(resp)['message'] == 'invalid session'

      JSON.parse(resp)['data']
    end

    def redirect_to_url(url)
      if respond_to?(:redirect_to)
        redirect_to url
      elsif respond_to?(:redirect)
        redirect url
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

    def resolve_no_permission
      render_response(403, 'No Permission')
    end

    def resolve_not_authorized
      if redirect_url
        login_url = generate_url('auth/login', { redirect_url: CGI.escape(redirect_url) })
        return redirect_to_url(login_url)
      end

      render_response(401, 'Not Authenticated')
    end

    def set_token_in_resp(token)
      if respond_to?(:response)
        return response.set_cookie(AUTHENTICATION_KEY, token) if redirect_url

        response.set_header(AUTHENTICATION_KEY, token)
      elsif respond_to?(:header)
        header(AUTHENTICATION_KEY, token)
      else
        raise UnknownRackApp
      end
    end

    def get_token_in_request
      session_id = params['sessionId'] || params['session_id']
      return exchange_token(params['st'], session_id) if params['st'] && session_id

      request.cookies[AUTHENTICATION_KEY] || request.headers[AUTHENTICATION_KEY]
    end

    def render_response(code, message)
      if respond_to?(:render)
        render json: message, status: code
      elsif respond_to?(:halt)
        halt message, status: code
      elsif respond_to?(:error!)
        error! message, code
      else
        raise UnknownRackApp
      end
    end
  end

end
