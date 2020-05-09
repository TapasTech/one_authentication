module OneAuthentication
  module Utils

    def underscore(term)
      string = term.to_s
      string.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
    end

    def camelize(term, uppercase_first_letter = false )
      string = term.to_s
      if uppercase_first_letter
        string = string.sub(/^[a-z\d]*/) { |match| match.capitalize }
      else
        string = string.sub(/^(?:(?=\b|[A-Z_])|\w)/) { |match| match.downcase }
      end
      string.gsub(/(?:_|(\/))([a-z\d]*)/) { "#{$1}#{$2.capitalize}" }.gsub("/", "::")
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

    def app_key
      OneAuthentication.configuration.app_key
    end

    def generate_url(path, parameters = {})
      parameters.transform_keys!{ |key| camelize(key) }
      query_string = '?' + parameters.map { |k, v| "#{k}=#{v}" }.join('&') unless parameters.blank?
      "#{host}/#{path}#{query_string}"
    end

  end
end
