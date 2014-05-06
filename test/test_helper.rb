require 'test/unit'
require 'rgeo/active_record'
require 'support/fake_record'

AREL_VERSION_MAJOR, AREL_VERSION_MINOR, AREL_VERSION_PATCH = ::Arel::VERSION.split('.').map { |part| part.to_i }
Arel::Visitors::PostgreSQL.send(:include, ::RGeo::ActiveRecord::SpatialToSql)
Arel::Table.engine = Arel::Sql::Engine.new(FakeRecord::Base.new)

def arel_visitor
  # The argument for constructing visitor objects depends on the version of
  # Arel.
  if(AREL_VERSION_MAJOR <= 2)
    if(AREL_VERSION_MAJOR == 2 && AREL_VERSION_MINOR == 0)
      Arel::Visitors::PostgreSQL.new(Arel::Table.engine)
    else
      Arel::Visitors::PostgreSQL.new(Arel::Table.engine.connection_pool)
    end
  else
    Arel::Visitors::PostgreSQL.new(Arel::Table.engine.connection)
  end
end
