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
    @assoc_params = @assoc_params || {}
  end

  def belongs_to(name, params = {})
    define_method(name) do
      bta = BelongsToAssocParams.new(name, params)
      self.class.assoc_params[name] = bta

      results = DBConnection.execute(<<-SQL)
      SELECT #{bta.other_table}.*
      FROM #{self.class.table_name}
      JOIN #{bta.other_table}
      ON #{bta.other_table}.#{bta.primary_key} = #{self.class.table_name}.#{bta.foreign_key}
      SQL

      bta.other_class.parse_all(results).first
    end
  end

  def has_many(name, params = {})
    define_method(name) do
      hma = HasManyAssocParams.new(name, params, self)
      self.class.assoc_params[name] = hma

      results = DBConnection.execute(<<-SQL)
      SELECT #{hma.other_table}.*
      FROM #{self.class.table_name}
      JOIN #{hma.other_table}
      ON #{self.class.table_name}.#{hma.primary_key} = #{hma.other_table}.#{hma.foreign_key}
      SQL

      hma.other_class.parse_all(results)
    end
  end

  def has_one_through(name, assoc1, assoc2)

    define_method(name) do
      params1 = self.class.assoc_params[assoc1]
      params2 = params1.other_class.assoc_params[assoc2]

      foreign_key_value = self.send(params1.foreign_key)
      results = DBConnection.execute(<<-SQL, foreign_key_value)
      SELECT #{params2.other_table}.*
      FROM #{params1.other_table}
      JOIN #{params2.other_table}
      ON #{params1.other_table}.#{params2.foreign_key} = #{params2.other_table}.#{params2.primary_key}
      WHERE #{params1.other_table}.#{params1.primary_key} = ?
      SQL

      params2.other_class.parse_all(results).first
    end
  end
end
