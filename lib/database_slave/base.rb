module DatabaseSlave
  module Base
    extend ActiveSupport::Concern

    included do
      cattr_accessor :slave_connections
      self.slave_connections = []

      class << self
        delegate :using_slave, :using, to: :scoped
      end
    end

    module ClassMethods
      # 为了兼容老版本
      #   ActiveRecord::Base.using(:slave_name) do
      #   end
      # 的写法, 这里迫不得已重写了scoped方法, 目的是:
      #
      # 当使用如上方式时, 将其using()方法代理到一个继承了ActiveRecord::Base的
      # 空的具象类DatabaseSlave::NoneActiveRecord, 以便进而能够使用using方法,
      # 因为ActiveRecord::Base是一个抽象类, 不能使用using方法.
      #
      # 且此种方式只能后接block, 不能用于级联式. 使用级联式会抛出异常, 具体见
      # ActiveRecord::Relation#using_slave中的实现.
      #
      def scoped(options = nil)
        if self.equal? ActiveRecord::Base
          # Module.const_get(ActiveRecord::Base.subclasses.map(&:name).sort.first) || self
          DatabaseSlave::NoneActiveRecord
        else
          super
        end
      end
    end
  end

  class NoneActiveRecord < ActiveRecord::Base
  end
end

ActiveRecord::Base.send(:include, DatabaseSlave::Base)
