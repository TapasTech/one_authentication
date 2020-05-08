module OneAuthentication
  module RackAppAdapter
    class UnknownRackApp < StandardError; end

    def redirect_to_path(url)
      if respond_to?(:redirect_to)
        redirect_to url
      elsif respond_to?(:redirect)
        redirect url
      else
        raise UnknownRackApp
      end
    end

    def render_response
      if respond_to?(:render)
        render 'not authorized', :status => 401
      elsif respond_to?(:halt)
        halt 'not authorized', :status => 401
      else
        raise UnknownRackApp
      end
    end

  end
end
