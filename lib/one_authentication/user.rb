module OneAuthentication
  class User
    attr_reader :name, :position, :avatar, :email, :mobile,
                :user_id, :privileges

    def initialize(args)
      args.each do |k,v|
        instance_variable_set("@#{k}", v) unless v.nil?
      end
    end

    def id
      @user_id
    end

  end
end
