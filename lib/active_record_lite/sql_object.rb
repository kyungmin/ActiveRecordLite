require 'active_support/inflector'
require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'

class SQLObject < MassObject
  extend Searchable
  extend Associatable

  def self.set_table_name(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.name.underscore
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT *
      FROM #{table_name}
    SQL

    results.first.map { |result| self.new(result) }
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT *
      FROM #{table_name}
      WHERE id = ?
    SQL

    self.new(results.first) || nil
  end

  def save
    if self.id.nil?
      create
    else
      update
    end
  end

  private

  def create
    columns = self.class.attributes.join(", ")
    attr_values = self.class.attributes.map { |attr_name| self.send("#{attr_name}") }
    question_marks = (['?'] * 10).join(", ")

    results = DBConnection.execute(<<-SQL, *attr_values)
      INSERT INTO #{table_name}
      (#{columns})
      VALUES
      (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    attr_values = self.class.attributes.map { |attr_name| self.send("#{attr_name}") }

    results = DBConnection.execute(<<-SQL, *attr_values, id)
      UPDATE #{self.class.table_name}
      SET #{attribute_values}
      WHERE id = ?
    SQL
  end

  def attribute_values

    self.class.attributes.map do |attr_name|
      "#{attr_name} = ?"
    end.join(", ")
  end
end
