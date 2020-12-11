# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  add_filter "/test/"
end

require "minitest/autorun"
require "rgeo-activerecord"
require "support/fake_record"

Arel::Visitors::PostgreSQL.send(:include, RGeo::ActiveRecord::SpatialToSql)
Arel::Table.engine = FakeRecord::Base.new

begin
  require "byebug"
rescue LoadError
  # ignore
end
