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

## Hash-like Behavior & ActiveRecord Integration

Blockster objects behave like hashes and integrate seamlessly with ActiveRecord. This makes them perfect for form objects and API wrappers.

### Hash Conversion

```ruby
params = {
  'user' => {
    'username' => 'js_bach',
    'email' => {
      'address' => 'js@bach.music',
      'notifications' => 'true'
    }
  }
}

form = Blockster::Wrapper.new(UserForm).with(params) do
  root :user do
    attribute :username, :string
    nested :email do
      attribute :address, :string
      attribute :notifications, :boolean
    end
  end
end

# Convert to hash
form.to_h
# => {
#      username: "js_bach",
#      email: {
#        address: "js@bach.music",
#        notifications: true
#      }
#    }

# Use hash-like methods
form.keys           # => [:username, :email]
form.empty?         # => false
form.each_pair do |key, value|
  puts "#{key}: #{value}"
end
```

### ActiveRecord Integration

Blockster objects can be used directly with ActiveRecord methods thanks to proper hash conversion:

```ruby
# Create records
user = User.create(form)

# Update records
user.update(form)

# Mass assignment
user.assign_attributes(form)

# Form objects
class UserRegistrationForm
  include ActiveModel::Model
  include ActiveModel::Attributes
end

class UsersController < ApplicationController
  def create
    # Works seamlessly with ActiveRecord
    @user = User.new(create_params)
    
    if @user.save
      redirect_to @user
    else
      render :new
    end
  end

  private

  def create_params
    Blockster::Wrapper.new(UserRegistrationForm).with(user_params) do
      root :user do
        attribute :username, :string
        attribute :email, :string
        
        nested :profile do
          attribute :first_name, :string
          attribute :last_name, :string
        end
        
        nested :preferences do
          attribute :theme, :string
          attribute :notifications, :boolean
        end
      end
    end
  end
end
```

### Nested Forms with ActiveRecord Relations

```ruby
class OrderForm
  include ActiveModel::Model
  include ActiveModel::Attributes
end

form = Blockster::Wrapper.new(OrderForm).with(params) do
  root :order do
    attribute :number, :string
    attribute :total, :decimal
    
    nested :line_items do
      attribute :product_id, :integer
      attribute :quantity, :integer
      attribute :price, :decimal
    end
    
    nested :shipping_address do
      attribute :street, :string
      attribute :city, :string
      attribute :postal_code, :string
    end
  end
end

# Create order with nested attributes
order = Order.create(form)

# Update existing order
order.update(form)

# Use with accepts_nested_attributes_for
class Order < ApplicationRecord
  has_many :line_items
  has_one :shipping_address
  accepts_nested_attributes_for :line_items, :shipping_address
end

# Form's hash structure matches nested attributes requirements
order.assign_attributes(form)
```

### Working with APIs

The hash conversion makes it easy to work with APIs:

```ruby
class ApiWrapper
  include ActiveModel::Model
  include ActiveModel::Attributes
end

response = Blockster::Wrapper.new(ApiWrapper).with(api_response) do
  attribute :status, :string
  
  nested :data do
    attribute :id, :integer
    attribute :type, :string
    
    nested :attributes do
      attribute :title, :string
      attribute :description, :text
      attribute :published_at, :datetime
    end
  end
end

# Renders as properly formatted JSON
render json: response

# Or use directly in ActiveRecord
record = Record.create(response.data.attributes)
```

### JSON Serialization

Blockster objects work seamlessly with Rails' JSON rendering:

```ruby
class Api::UsersController < ApplicationController
  def show
    user_data = UserService.fetch(params[:id])
    
    response = Blockster::Wrapper.new(ApiResponse).with(user_data) do
      attribute :id, :integer
      attribute :username, :string
      
      nested :profile do
        attribute :first_name, :string
        attribute :last_name, :string
        attribute :avatar_url, :string
      end
      
      nested :stats do
        attribute :posts_count, :integer
        attribute :followers_count, :integer
        attribute :following_count, :integer
      end
    end

    # Works directly with render :json
    render json: response
  end
end
```

You can also explicitly convert to JSON:

```ruby
# Convert to hash first
response.as_json
# => { id: 1, username: "js_bach", profile: { first_name: "Johann", ... } }

# Convert directly to JSON string
response.to_json
# => '{"id":1,"username":"js_bach","profile":{"first_name":"Johann",...}}'

# Works with complex nested structures
form = Blockster::Wrapper.new(ComplexForm).with(data) do
  attribute :name, :string
  nested :settings do
    attribute :theme, :string
    attribute :notifications, :array
  end
  nested :permissions do
    attribute :roles, :array
    nested :features do
      attribute :enabled, :array
    end
  end
end

# Renders as properly formatted JSON
render json: form
```

The JSON serialization maintains all nested structures and array values, making it perfect for API responses and client-side consumption.


### Debugging

Blockster objects have a readable inspect output that shows their current state:

```ruby
form = Blockster::Wrapper.new(UserForm).with(params) do
  root :user do
    attribute :username, :string
    nested :email do
      attribute :address, :string
    end
  end
end

puts form.inspect
# => {:username=>"js_bach", :email=>{:address=>"js@bach.music"}}
```

This makes debugging in Rails console and logging much more convenient.

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
