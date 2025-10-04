# frozen_string_literal: true

# From https://github.com/rails/arel/master/test/support/fake_record.rb
module FakeRecord
  Column = Struct.new(:name, :type)

  class Connection
    attr_reader :tables
    attr_accessor :visitor

    def initialize(visitor = nil)
      @tables = %w[users photos developers products]
      @columns = {
        "users" => [
          Column.new("id", :integer),
          Column.new("name", :string),
          Column.new("bool", :boolean),
          Column.new("created_at", :date)
        ],
        "products" => [
          Column.new("id", :integer),
          Column.new("price", :decimal)
        ]
      }
      @columns_hash = {
        "users" => Hash[@columns["users"].map { |x| [x.name, x] }],
        "products" => Hash[@columns["products"].map { |x| [x.name, x] }]
      }
      @primary_keys = {
        "users" => "id",
        "products" => "id"
      }
      @visitor = visitor
    end

    def columns_hash(table_name)
      @columns_hash[table_name]
    end

    def primary_key(name)
      @primary_keys[name.to_s]
    end

    def table_exists?(name)
      @tables.include? name.to_s
    end

    def columns(name, message = nil)
      @columns[name.to_s]
    end

    def quote_table_name(name)
      %("#{name}")
    end

    def quote_column_name(name)
      %("#{name}")
    end

    def schema_cache
      self
    end

    def quote(thing, column = nil)
      if column && !thing.nil?
        case column.type
        when :integer
          thing = thing.to_i
        when :string
          thing = thing.to_s
        end
      end

      case thing
      when DateTime
        "'#{thing.strftime('%Y-%m-%d %H:%M:%S')}'"
      when Date
        "'#{thing.strftime('%Y-%m-%d')}'"
      when true
        "'t'"
      when false
        "'f'"
      when nil
        "NULL"
      when Numeric
        thing
      else
        "'#{thing.to_s.gsub("'", "\\\\'")}'"
      end
    end

    def cast_bound_value(value)
      value.to_s
    end
  end

  class ConnectionPool
    Spec = Struct.new(:config, :adapter)

    attr_reader :spec, :connection

    def initialize
      @spec = Spec.new({ adapter: "america" })
      @connection = Connection.new
      @connection.visitor = Arel::Visitors::ToSql.new(connection)
    end

    def with_connection
      yield connection
    end

    def table_exists?(name)
      connection.tables.include? name.to_s
    end

    def columns_hash
      connection.columns_hash
    end

    def schema_cache
      connection
    end

    def quote(thing, column = nil)
      connection.quote thing, column
    end
  end

  class Base
    include ActiveRecord::Sanitization

    attr_accessor :connection_pool

    def self.with_connection
      yield new.connection
    end

    def initialize
      @connection_pool = ConnectionPool.new
    end

    def connection
      connection_pool.connection
    end
  end
end
