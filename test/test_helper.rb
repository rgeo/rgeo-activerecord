require 'minitest/autorun'
require 'rgeo/active_record'
require 'support/fake_record'

Arel::Visitors::PostgreSQL.send(:include, ::RGeo::ActiveRecord::SpatialToSql)
Arel::Table.engine = Arel::Sql::Engine.new(FakeRecord::Base.new)

def arel_visitor
  Arel::Visitors::PostgreSQL.new(Arel::Table.engine.connection)
end
