require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  def other_class
    @other_class_name.constantize
  end

  def other_table
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  attr_reader :other_class_name, :primary_key, :foreign_key

  def initialize(name, params)
    @other_class_name = params[:class_name] || name.to_s.camelcase
    @primary_key = params[:primary_key] || "id"
    @foreign_key = params[:foreign_key] || "#{name}_id"
  end

  def type

  end

end

class HasManyAssocParams < AssocParams
  attr_reader :other_class_name, :primary_key, :foreign_key

  def initialize(name, params, self_class)
    @other_class_name = params[:class_name] || name.to_s.singularize.camelcase
    @primary_key = params[:primary_key] || "id"
    @foreign_key = params[:foreign_key] || "#{self_class.name.underscore}_id"
  end

  def type

  end
end

module Associatable
  def assoc_params

  end

  def belongs_to(name, params = {})
    define_method(name) do
      bta = BelongsToAssocParams.new(name, params)
      other_class_attributes = bta.other_class.attributes.map do |attr_name|
        "#{bta.other_table}.#{attr_name}"
      end.join(", ")

      results = DBConnection.execute(<<-SQL)
      SELECT #{other_class_attributes}
      FROM #{self.class.table_name}
      JOIN #{bta.other_table}
      ON #{bta.other_table}.#{bta.primary_key} = #{self.class.table_name}.#{bta.foreign_key}
      SQL

      bta.other_class.parse_all(results).first
    end
  end

  def has_many(name, params = {})
    define_method(name) do
      bta = HasManyAssocParams.new(name, params, self)
      other_class_attributes = bta.other_class.attributes.map do |attr_name|
        "#{bta.other_table}.#{attr_name}"
      end.join(", ")

      results = DBConnection.execute(<<-SQL)
      SELECT #{other_class_attributes}
      FROM #{self.class.table_name}
      JOIN #{bta.other_table}
      ON #{self.class.table_name}.#{bta.primary_key} = #{bta.other_table}.#{bta.foreign_key}
      SQL

      bta.other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)

  end
end
