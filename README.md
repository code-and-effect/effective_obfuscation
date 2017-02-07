# Effective Obfuscation

Display unique 10-digit numbers instead of ActiveRecord IDs.  Hides the ID param so curious website visitors are unable to determine your user or order count.

Turn a URL like:

```ruby
http://example.com/users/3
```

into something like:

```ruby
http://example.com/users/2356513904
```

Sequential ActiveRecord ids become non-sequential, random looking, numeric ids.

```ruby
# user 7000
http://example.com/users/5270192353
# user 7001
http://example.com/users/7107163820
# user 7002
http://example.com/user/3296163828
```

This is a Rails 4 compatible version of obfuscate_id (https://github.com/namick/obfuscate_id) which also adds totally automatic integration with Rails finder methods.


## Getting Started

Add to Gemfile:

```ruby
gem 'effective_obfuscation'
```

Run the bundle command to install it:

```console
bundle install
```

## Usage

### Basic

Add the mixin to an existing model:

```ruby
class User
  acts_as_obfuscated
end
```

Thats it.  Now URLs for a User will be generated as

```ruby
http://example.com/users/2356513904
```

As well, any find(), exists?(), find_by_id(), find_by(), where(:id => params[:id]) and all Arel table finder methods will be automatically translated to lookup the proper underlying ID.

You shouldn't require any changes to your view or controller code. Just Works with InherittedResources and ActiveAdmin.

### Formatting

Because of the underlying ScatterSwap algorithm, the obfuscated IDs must be exactly 10 digits in length.

However, if you'd like to add some formatting to make the 10-digit number more human readable and over-the-phone friendly

```ruby
class User
  acts_as_obfuscated :format => '###-####-###'
end
```

will generate URLs that look like

```ruby
http://example.com/users/235-6513-904
```

Any String.parameterize-able characters will work as long as there are exactly 10 # (hash symbol) characters in the format string somewhere.


### ScatterSwap Spin

The Spin value is basically a salt used by the ScatterSwap algorithm to randomize integers.

In this gem, the default spin value is set on a per-model basis.

There is really no reason to change it; however, you can specify the spin value directly if you wish

```ruby
class User
  acts_as_obfuscated :spin => 123456789
end
```

### General Obfuscation

So maybe you just want access to the underlying ScatterSwap obfuscation algorithm including the additional model-specific formatting.

To obfuscate, pass any number as a string, or an integer

```ruby
User.obfuscate(43)         # Using acts_as_obfuscated :format => '###-####-###'
  => "990-5826-174"
```

And to de-obfuscate, pass any number as a string or an integer

```ruby
User.deobfuscate("990-5826-174")
  => 43

User.deobfuscate(9905826174)
  => 43
```

### Searching by the Real (Database) ID

By default, all finder method except `find()` will work with both obfuscated and database IDs.

This means,

```ruby
User.where(:id => "990-5826-174")
  => User<id: 43>
```

returns the same User as

```ruby
User.where(:id => 43)
  => User<id: 43>
```

This behaviour is not applied to `find()` because it would allow a user to visit:

http://example.com/users/1
http://example.com/users/2
...etc...

and enumerate all users.

Please continue to use @user = User.find(params[:id]) in your controller to prevent route enumeration.

Any other internally used finder methods, `where` and `find_by_id` should respond to both obfuscated and database IDs for maximum compatibility.

## License

MIT License.  Copyright [Code and Effect Inc.](http://www.codeandeffect.com/)

## Credits

This project was inspired by

ObfuscateID (https://github.com/namick/obfuscate_id)

and uses the same (simply genius!) underlying algorithm

ScatterSwap (https://github.com/namick/scatter_swap)


## Testing

The test suite for this gem is unfortunately not yet complete.

Run tests by:

```ruby
rake spec
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Bonus points for test coverage
6. Create new Pull Request

