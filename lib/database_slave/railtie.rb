module DatabaseSlave
  class Railtie < Rails::Railtie
    # === Description
    #
    # 此处参考Rails启动时建立database.yml连接的方式, 来实现
    # 在Rails启动时就建立好所有的从库链接.
    #
    #   参考文件为 activerecord/lib/active_record/railtie.rb
    #   initializer "active_record.initialize_database"
    #
    #   在上面的initializer中Rails会调用
    #     ActiveRecord::Base.establish_connection
    #   来建立database.yml连接.
    #
    initializer 'database_slave.initialize_slave_database' do
      Rails.logger.info "Connecting to slave database specified by shards.yml"

      DatabaseSlave::ConnectionHandler.establish_connection
    end
  end
end
