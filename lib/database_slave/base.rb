module DatabaseSlave
  module Base
    extend ActiveSupport::Concern

    included do
      cattr_accessor :slave_connections
      self.slave_connections = []

      class << self
        delegate :using_slave, to: :scoped
      end
    end
  end
end

ActiveRecord::Base.send(:include, DatabaseSlave::Base)
