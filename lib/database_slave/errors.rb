module DatabaseSlave

  # Generic Database Slave exception class.
  class DatabaseSlaveError < StandardError
  end

  # Raised when using_slave() method used on a abstract class
  # without a block given.
  # For example: ActiveRecord::Base.using_slave().where() is not allowed.
  class AbstractClassWithoutBlockError < DatabaseSlaveError
  end

  # Raised when slave connection doesn't exists.
  class SlaveConnectionNotExists < DatabaseSlaveError
  end

  class AdapterNotFound < DatabaseSlaveError
  end
end
