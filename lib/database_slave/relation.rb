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

    alias using using_slave

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
      # 该if语句的作用是: 确保在一条使用从库的查询中存在的其他先决条件的
      # 查询也使用从库。例如:
      #
      #   class Book < ActiveRecord::Base
      #     default_scope lambda { where(:tag_id => Tag.published.pluck(:id)) }
      #   end
      #
      # 当我们使用如下查询
      #
      #   Book.order('id DESC').limit(2).pluck(:id)
      #
      # 时, default_scope中的Tag需要被先查询出来. 为了Book和Tag的查询都使用从库,
      # 避免查询Tag后便释放了从库连接而导致Book的查询使用的还是主库. 故在这里
      # 加了条件判断: 如果父查询已经设置了使用从库, 那么内部的所有查询都使用从库,
      # 直到父查询返回.
      #
      # Supports ActiveRecord::QueryMethods:
      #   select, group, order, reorder, joins, where, having,
      #   limit, offset, uniq
      #
      # And ActiveRecord::FinderMethods:
      #   first, first!, last, last!, find, all
      #
      # And ActiveRecord::Batches:
      #   find_each, find_in_batches
      #
      if !DatabaseSlave::RuntimeRegistry.current_slave_name
        begin
          DatabaseSlave::RuntimeRegistry.current_slave_name = slave_name if using_slave?
          super
        ensure
          DatabaseSlave::RuntimeRegistry.current_slave_name = nil
        end
      else
        super
      end
    end if defined?(Rails)

    # Supports ActiveRecord::FinderMethods:
    #   exists?
    #
    def exists?(id = false)
      if !DatabaseSlave::RuntimeRegistry.current_slave_name
        begin
          DatabaseSlave::RuntimeRegistry.current_slave_name = slave_name if using_slave?
          super
        ensure
          DatabaseSlave::RuntimeRegistry.current_slave_name = nil
        end
      else
        super
      end
    end if defined?(Rails)

    # Supports ActiveRecord::Calculations:
    #   pluck
    #
    def pluck(column_name)
      if !DatabaseSlave::RuntimeRegistry.current_slave_name
        begin
          DatabaseSlave::RuntimeRegistry.current_slave_name = slave_name if using_slave?
          super
        ensure
          DatabaseSlave::RuntimeRegistry.current_slave_name = nil
        end
      else
        super
      end
    end if defined?(Rails)

    # Supports ActiveRecord::Calculations:
    #   count, average, minimun, maximum, sum, calculate
    #
    def calculate(operation, column_name, options = {})
      if !DatabaseSlave::RuntimeRegistry.current_slave_name
        begin
          DatabaseSlave::RuntimeRegistry.current_slave_name = slave_name if using_slave?
          super
        ensure
          DatabaseSlave::RuntimeRegistry.current_slave_name = nil
        end
      else
        super
      end
    end if defined?(Rails)
  end

  def self.prepended(klass)
    klass.send :prepend, Relation
  end
end

ActiveRecord::Relation.send(:prepend, DatabaseSlave::Relation)
ActiveRecord::Relation.class_variable_set(:@@slave_block_given, nil)
