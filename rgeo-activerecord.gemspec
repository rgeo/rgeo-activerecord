require './lib/rgeo/active_record/version'

::Gem::Specification.new do |s_|
  s_.name = 'rgeo-activerecord'
  s_.summary = 'An RGeo module providing spatial extensions to ActiveRecord.'
  s_.description = "RGeo is a geospatial data library for Ruby. RGeo::ActiveRecord is an optional RGeo module providing some spatial extensions to ActiveRecord, as well as common tools used by RGeo-based spatial adapters."
  s_.version = "#{::RGeo::ActiveRecord::VERSION}"
  s_.author = 'Daniel Azuma'
  s_.email = 'dazuma@gmail.com'
  s_.homepage = "http://dazuma.github.com/rgeo-activerecord"
  s_.required_ruby_version = '>= 2.0.0'
  s_.files = ::Dir.glob("lib/**/*.rb") +
    ::Dir.glob("test/**/*.rb") +
    ::Dir.glob("*.rdoc")
  s_.extra_rdoc_files = ::Dir.glob("*.rdoc")
  s_.test_files = ::Dir.glob("test/**/tc_*.rb")
  s_.platform = ::Gem::Platform::RUBY
  s_.add_dependency 'rgeo', '>= 0.3.20'
  s_.add_dependency 'activerecord', '~> 4.1'

  s_.add_development_dependency 'minitest', '~> 5.3'
  s_.add_development_dependency 'rake', '~> 10.2'
  s_.add_development_dependency 'rdoc'
end
