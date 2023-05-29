module EffectiveObfuscation
  class Engine < ::Rails::Engine
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]

    # Include acts_as_addressable concern and allow any ActiveRecord object to call it
    initializer 'effective_obfuscation.active_record' do |app|
      app.config.to_prepare do
        ActiveSupport.on_load :active_record do
          ActiveRecord::Base.extend(ActsAsObfuscated::ActiveRecord)
        end
      end
    end
  end
end
