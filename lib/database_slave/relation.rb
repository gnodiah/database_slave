module DatabaseSlave
  module Relation
    attr_accessor :slave_name

    def initialize(klass, table)
      slave_name = nil
      if (slave = ActiveRecord::Relation.class_variable_get(:@@slave_block_given)).present?
        self.slave_name = slave
      end

      super
    end

    def using_slave?
      slave_name.to_s.present?
    end

    def unusing_slave
      slave_name = nil

      self
    end

    def using_slave(slave_name)
      if Settings.using_slave
        if block_given?
          name = "DatabaseSlave::ConnectionHandler::#{slave_name.to_s.strip.camelize}"
          ActiveRecord::Relation.class_variable_set(:@@slave_block_given, name)
          begin
            yield
          ensure
            ActiveRecord::Relation.class_variable_set(:@@slave_block_given, nil)
            DatabaseSlave::RuntimeRegistry.current_slave_name = nil
          end
        else
          self.slave_name = "DatabaseSlave::ConnectionHandler::#{slave_name.to_s.strip.camelize}"
          relation = clone

          if ActiveRecord::Base.slave_connections.include? self.slave_name
            relation
          else
            raise "#{slave_name} is not exist."
          end
        end
      else
        clone
      end
    end

    # alias using using_slave

    # === Description
    #
    # Rails中所有的relation最后都是调用to_a后返回最终结果.
    #
    # 这里我们重写ActiveRecord::Relation的to_a方法只是为了做一件事:
    #
    #   必须在当前relation返回后将是否使用从库的标识设置为否, 
    #   以免影响执行下一个relation时的主从库选择错误.
    #
    # 对应到代码即:
    #   DatabaseSlave::RuntimeRegistry.current_slave_name = nil
    #
    def to_a
      DatabaseSlave::RuntimeRegistry.current_slave_name = slave_name if using_slave?

      super
    ensure
      DatabaseSlave::RuntimeRegistry.current_slave_name = nil
    end if defined?(Rails)
  end

  def self.prepended(klass)
    klass.send :prepend, Relation
  end
end

ActiveRecord::Relation.send(:prepend, DatabaseSlave::Relation)
ActiveRecord::Relation.class_variable_set(:@@slave_block_given, nil)
