module DatabaseSlave
  class ConnectionHandler
    # === Description
    #
    # 该方法根据 DatabaseSSlave::Configuration 的配置建立所有的数据库从库链接.
    #
    # Rails在启动时会调用 ActiveRecord::Base.establish_connection 来建立database.yml连接,
    # 以上方法定义在 active_record/connection_adapters/abstract/connection_specification.rb
    #
    # 故该方法的设计参考了以上方法, 遵循了以上方法的设计逻辑.
    #
    # 注意下面方法中 **klass** 的实现:
    #   因为remove_connection方法需要一个类名作为参数, 然后会在该类名上调用name方法.
    #   查看源码可知原方法传入的是self, 即当前调用类; 类自带了name方法.
    #
    #   同理, 这里我们也应该传入一个类名, 但self不是所期望的, 于是这里使用了
    #   
    #     self.const_set(slave_name.to_s.strip.camelize, Class.new)
    #
    #   的方式动态地创建了一个类.
    #
    #   此外, 还可以通过定义一个代理类Proxy然后实现name方法的方式来达到目的.
    #
    def self.establish_connection
      ActiveRecord::Base.slave_connections ||= []

      DatabaseSlave.configurations.each do |slave_name, config|
        adapter_method = "#{config['adapter']}_connection"
        spec           = ActiveRecord::Base::ConnectionSpecification.new(config, adapter_method)
        klass          = self.const_set(slave_name.to_s.strip.camelize, Class.new)

        unless ActiveRecord::Base.respond_to?(spec.adapter_method)
          raise "AdapterNotFound: database configuration specifies nonexistent #{config['adapter']} adapter"
        end

        ActiveRecord::Base.slave_connections << klass.name
        ActiveRecord::Base.remove_connection klass
        ActiveRecord::Base.connection_handler.establish_connection klass.name, spec
      end
    end
  end

  # === Description
  # 
  # 当真正要执行一条SQL语句的时候, Rails会调用
  #   ActiveRecord::Base.connection
  #
  # 方法到连接池中获取一个数据库连接. 以上方法定义在:
  #   activerecord/lib/active_record/connection_adapters/abstract/connection_specification.rb
  #
  # 而ActiveRecord::Base.connection则调用的是:
  #   ActiveRecord::Base.connection_handler.retrieve_connection(klass)
  #
  # 由此可知, 要想获取到的是从库连接而非主库连接, 那么上述方法的klass就需要
  # 传入之前建立的从库连接的class名而不是默认的self.
  #
  # 因此, 我们在这里重写了ActiveRecord::Base.connection方法, 在其中增加了在什么时候应该使用
  # 从库连接的判断, 并用Module#prepend方法将我们重写后的connection方法加载到ActiveRecord::Base
  # 的前面, 以便我们重写后的connection方法比ActiveRecord::Base.connection方法先执行.
  #
  module Connection
    def self.prepended(base)
      class << base
        prepend ClassMethods
      end
    end

    module ClassMethods
      def connection
        klass = self

        if Settings.using_slave && slave_connection_exists?
          slave_name = DatabaseSlave::RuntimeRegistry.current_slave_name
          klass      = DatabaseSlave.const_get(slave_name)
        end

        ActiveRecord::Base.connection_handler.retrieve_connection(klass)
      end

      private

      def slave_connection_exists?
        slave_name = DatabaseSlave::RuntimeRegistry.current_slave_name
        slave_name && ActiveRecord::Base.slave_connections.include?(slave_name)
      end
    end
  end
end

ActiveRecord::Base.send(:prepend, DatabaseSlave::Connection)
