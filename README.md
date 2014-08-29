# Effective Obfuscation

Use a unique 10-digit number instead of ActiveRecord IDs

Turn a URL like

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
gem 'effective_obfuscation', :git => 'https://github.com/code-and-effect/effective_obfuscation.git'
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

As well, any find(), exists?(), find_by_id(), or where(:id => params[:id]) methods will be automatically translated to lookup the proper underlying ID.

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

Any String.parameterize-able characters will work as long as there are exactly 10 # characters in the format string somewhere.


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

## License

MIT License.  Copyright Code and Effect Inc. http://www.codeandeffect.com

You are not granted rights or licenses to the trademarks of Code and Effect


## Credits

This project was inspired by

ObfuscateID (https://github.com/namick/obfuscate_id)

and uses the same (simply genius!) underlying algorithm

ScatterSwap (https://github.com/namick/scatter_swap)


### Testing

The test suite for this gem is unfortunately not yet complete.

Run tests by:

```ruby
rake spec
```
