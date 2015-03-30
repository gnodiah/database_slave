# Database_slave
[![Gem Version](https://badge.fury.io/rb/database_slave.svg)](https://github.com/Gnodiah/database_slave)
![](http://ruby-gem-downloads-badge.herokuapp.com/database_slave?type=total&color=red)

This gem provides master and slave databases support for Rails applications. It maintains a slave database configuration in config/shards.yml, and treats config/database.yml as master database. Then, you can choose which database you want to use in your ActiveRecord::Relation clauses.

For example, you can use slave database to execute complicated and time-consuming database queries to balance the performance of master database, or separate read and write database operations.

# Requirements

* Ruby  >= 2.0.0
* Rails >= 3.2.x

# Installation

Put the following line into you Gemfile:

```bash
gem 'database_slave', '>= 0.1.0'
```

then execute:

```bash
bundle install
```

# Preparing

1. First of all, create a file named **shards.yml** in your Rails config directory,
  its content is very similar to config/database.yml:

  ```yml
  development:
    slave_database1:
      adapter: mysql2
      encoding: utf8
      reconnect: false
      port : 3306
      pool: 5
      username: root
      password: test
      host: 127.0.0.1
      database: books

    slave_database2:
      adapter: mysql2
      ...
      ...
  test:
    slave_database1:
      ...
  production:
    slave_database1:
      ...
  ```

2. Then add following to your settings.yml file:

  ```ruby
  using_slave: true
  ```

  **true** means you can use slave database, **false** means not.

# Usage

There are two ways to use slave database:

1. **Single Use**: Append `using_slave(:slave_database_name)` to each ActiveRecord::Relation clause.

  Example:

  ```ruby
  Book.where(id: 5).using_slave(:books_slave_database)
  ```

2. **With Block**: In this way, all of queries in the block will use slave_database to execute queries.
  With this you don't need to append `using_slave()` to each queries.

  Example:

  ```ruby
  Book.using_slave(:books_slave_database) do
    books1 = Book.where(id: 9)
    books2 = Book.where('id > 100')
  end
  ```

# License

See LICENSE file.
