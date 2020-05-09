# OneAuthentication

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/one_authentication`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'one_authentication'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install one_authentication

## Usage

配置
```ruby
# @required authentication_center_host，staging 和 production 环境的地址都可以
# @optional app_key, 当需要权限管理功能时需要设置, 访问 #{authentication_center_host}/api/apps 创建当前的 app, 生成的 app_id 即 app_key
# @optional redirect_url 当前系统前后端不分离需要设置, redirect_url 设置为当前系统的地址
# @optional app_user_table_name, 映射当前系统用户表需要设置, 确保当前系统用户表有 ding_talk_id 列, 值为钉钉用户 id
OneAuthentication.configure do |config|
  config.authentication_center_host = 'https://staging-auth.cbndata.org'
  config.redirect_url = 'xxxxx'
  config.app_key = '5eb641ea58b428d95c92f4c3'
  config.app_user_table_name = 'user'
end
```

用户认证
```ruby
class BaseApi < Grape::API
  include OneAuthentication::Plugin

  before { authenticate }  
   
  get 'profile' do
    @current_user 
  end

  namespace :users do
    before { authorize('用户管理') }     

    get do
      # to return all users
    end 
  end

end
```
当用户登陆失败或者没有所需权限时返回 status code 401

可获取的用户属性
```
- avatar
- name
- email
- id(钉钉用户 id)
- position
- mobile
```

支持 Sinatra, Rails, Grape

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/one_authentication.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
