require_relative './db_connection'

module Searchable
  def where(params)
    attr_values = []
    where_query = []
    params.each do |key, value|
      where_query << "#{key} = ?"
      attr_values << value
    end
    where_query = where_query.join(" AND ")

    results = DBConnection.execute(<<-SQL, *attr_values)
      SELECT *
      FROM #{table_name}
      WHERE #{where_query}
    SQL

    [self.new(results.first)]
  end
end