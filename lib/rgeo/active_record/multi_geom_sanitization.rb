# frozen_string_literal: true
require 'active_support/core_ext/array/wrap'

module MultiGeomSanitization
  private

  # NOTE connection and value order is swapped in Rails 8
  def replace_bind_variable(connection, value)
    if value.class.name.start_with?("RGeo::") && value.respond_to?(:map)
      super(connection, Array.wrap(value))
    else
      super
    end
  end
end

ActiveRecord::Sanitization::ClassMethods.prepend(MultiGeomSanitization)
