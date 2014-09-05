require 'minitest/autorun'
require 'rgeo/active_record'
require 'support/fake_record'

MINITEST_CLASS = if defined?(::Minitest::Test)
                   ::Minitest::Test
                 else
                   ::Minitest::Unit::TestCase
                 end

Arel::Visitors::PostgreSQL.send(:include, ::RGeo::ActiveRecord::SpatialToSql)
Arel::Table.engine = FakeRecord::Base.new
