# 该类定义拷贝自Rails 4.0.0 的 lib/active_support/per_thread_registry.rb
# 因为Rails 3.x 没有该文件.
module ActiveSupport
  module PerThreadRegistry
    protected

    def method_missing(name, *args, &block) # :nodoc:
      # Caches the method definition as a singleton method of the receiver.
      define_singleton_method(name) do |*a, &b|
        per_thread_registry_instance.public_send(name, *a, &b)
      end

      send(name, *args, &block)
    end

    private

    def per_thread_registry_instance
      Thread.current[name] ||= new
    end
  end
end

module DatabaseSlave
  # This is a thread locals registry for Active Record. For example:
  #
  #   ActiveRecord::RuntimeRegistry.connection_handler
  #
  # returns the connection handler local to the current thread.
  #
  # See the documentation of <tt>ActiveSupport::PerThreadRegistry</tt>
  # for further details.
  # 该类定义拷贝自Rails 4.0.0 的 lib/active_record/runtime_registry.rb
  # 因为Rails 3.x 没有该文件.
  class RuntimeRegistry # :nodoc:
    extend ActiveSupport::PerThreadRegistry

    attr_accessor :current_slave_name
  end
end
