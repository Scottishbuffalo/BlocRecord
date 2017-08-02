require 'pg'
require 'sqlite3'

module Selection
  def find(*ids)

    if ids.length == 1
      find_one(ids.first)
    else
      rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id IN (#{ids.join(",")});
      SQL

      rows_to_array(rows)
    end
  end

  def find_one(id)
    if (id < 0) || (id == nil)
      puts "That's an invalid id. It must be greater than or equal to zero. Try again."
    else
      row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{id};
      SQL
    end
    init_object_from_row(row)
  end

  def find_by(attribute, value)
    row = connection.get_first_row <<-SQL
    SELECT #{columns.join ","} FROM #{table}
    WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL

    init_object_from_row(row)
  end

  def method_missing(method_name, *arguments, &block)
    if method_name.to_s =~ /find_by_(.*)/
      find_by($1, *arguments[0])
    else
      super
    end
  end

  def find_each(query = {})
    rows = connection.execute <<-SQL
    SELECT #{columns.join ","} FROM #{table}
    LIMIT #{query[:batch_size]};
    SQL

    for row in rows_to_array(rows)
      yield(row)
    end
  end

  def find_in_batches(query = {})
    rows = connection.execute <<-SQL
    SELECT #{columns.join ","} FROM #{table}
    LIMIT #{query[:batch_size]};
    SQL

    yield(rows_to_array(rows))
  end

  def take(num=1)
    if num > 1
      rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT #{num};
      SQL

      rows_to_array(rows)
    else
      take_one
    end
  end

  def take_one
    row = connection.get_first_row <<-SQL
    SELECT #{columns.join ","} FROM #{table}
    ORDER BY random()
    LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def first
    if BlocRecord.database_type == 'pg'
      row = connection.exec <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id
      ASC LIMIT 1;
      SQL
    else
      row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id
      ASC LIMIT 1;
      SQL
    end

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<-SQL
    SELECT #{columns.join ","} FROM #{table}
    ORDER BY id
    DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
    SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  def where(*args)
    if args.count > 1
      expression = args.shift
      params = args
    else
      case args.first
      when String
        expression = args.first
      when Hash
        expression_hash = BlocRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
      end
    end

    sql = <<-SQL
    SELECT #{columns.join ","} FROM #{table}
    WHERE #{expression};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end


  def order(*args)

    if args.count > 1
      order = args.join(",")
    else
      order = args.first.to_s
    else
      order = args.first.to_s
    end
    rows = connection.execute <<-SQL
    SELECT * FROM #{table}
    ORDER BY #{order};
    SQL
    rows_to_array(rows)
    
  end

  def join(*args)
    if args.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      rows = connection.execute <<-SQL
      SELECT * FROM #{table} #{joins}
      SQL
    else
      case args.first
      when String
        rows = connection.execute <<-SQL
        SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
        SQL
      when Symbol
        rows = connection.execute <<-SQL
        SELECT * FROM #{table}
        INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
        SQL
      when Hash
        expression_hash = BlocRecord::Utility.convert_keys(args.first)
        expression = expression_hash.map { |key, value| "#{key} ON #{key}.#{table}_id = #{table}.id
        INNER JOIN #{BlocRecord::Utility.sql_strings(value)} ON #{BlocRecord::Utility.sql_strings(value)}.#{key}_id = #{key}.id"}.join(" INNER JOIN ")

        rows = connection.execute <<-SQL
        SELECT * FROM #{table}
        INNER JOIN #{expression};
        SQL
      end
    end
    rows_to_array(rows)
  end

  private
  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end

    def rows_to_array(rows)

      collection = BlocRecord::Collection.new
      rows.each { |row| collection << new(Hash[columns.zip(row)]) }
      collection
    end

  end
end
