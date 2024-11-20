# Blockster

Blockster is a flexible Ruby gem that provides a clean DSL for defining and initializing objects with nested attributes. It's particularly useful when working with params from complex form objects, API wrappers, or any scenario where you need to dynamically define object attributes.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'blockster'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install blockster
```

## Usage

### Basic Usage

```ruby
class UserForm
  include ActiveModel::Model
  include ActiveModel::Attributes
end

wrapper = Blockster::Wrapper.new(UserForm)
user = wrapper.with(username: 'js_bach', email: 'js@bach.music') do
  attribute :username, :string
  attribute :email, :string
end

user.username # => 'js_bach'
user.email    # => 'js@bach.music'
```

### Root Node and Nested Attributes

```ruby
params = {
  'user' => {
    'username' => 'js_bach',
    'email' => {
      'address' => 'js@bach.music',
      'notifications' => true
    },
    'preferences' => {
      'theme' => 'dark',
      'language' => 'en'
    }
  }
}

user = wrapper.with(params) do
  root :user do
    attribute :username, :string
    
    nested :email do
      attribute :address, :string
      attribute :notifications, :boolean
    end
    
    nested :preferences do
      attribute :theme, :string
      attribute :language, :string
    end
  end
end

user.username                 # => 'js_bach'
user.email.address           # => 'js@bach.music'
user.preferences.theme       # => 'dark'
```

### Configuration

You can configure a default class to be used when initializing wrappers, if you are using rails, this would be a great way to configure, since the attributes api is part of rails:

```ruby
# config/initializers/blockster.rb (in Rails)
Blockster.configure do |config|
  config.default_class = Class.new do
    include ActiveModel::Model
    include ActiveModel::Attributes
  end
end

# Now you can initialize wrappers without providing a class
wrapper = Blockster::Wrapper.new
```

Or use an existing class:

```ruby
class DefaultFormObject
  include ActiveModel::Model
  include ActiveModel::Attributes
  
  # Your default setup here
end

Blockster.configure do |config|
  config.default_class = DefaultFormObject
end
```

When initializing a wrapper, you can still override the default class:

```ruby
# Uses default class
wrapper = Blockster::Wrapper.new

# Overrides default class
wrapper = Blockster::Wrapper.new(CustomClass)
```

Note: Either a class must be provided to the wrapper or a default class must be configured.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/blockster.

## License

The gem is available as open source under the terms of the MIT License.
