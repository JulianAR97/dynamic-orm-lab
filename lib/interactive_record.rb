require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

    def initialize(options={})
        options.each do |attribute, value|
            self.send("#{attribute}=", value) 
        end 
    end 

    def self.table_name 
        self.to_s.downcase.pluralize
    end
    
    def self.column_names 
        sql = <<-SQL
        PRAGMA table_info(#{self.table_name})
        SQL

        DB[:conn].execute(sql).map do |column_info|
            column_info["name"]
        end 
    end

    def self.find_by_name(name)
        sql = "SELECT * FROM #{table_name} WHERE name = ?"
        DB[:conn].execute(sql, name)
    end 

    def self.find_by(attribute)
        value = attribute.values.first
        f_value = value.class == Integer ? value : "'#{value}'"
        sql = "SELECT * FROM #{table_name} WHERE #{attribute.keys.first} = #{f_value}"
      
        DB[:conn].execute(sql)
    end

    def table_name_for_insert
        self.class.table_name
    end 

    def col_names_for_insert 
        self.class.column_names.select {|column_name| column_name != "id"}.join(', ')
    end 

    def values_for_insert 
        values = [] 
        self.class.column_names.each do |column_name| 
            values << "'#{self.send(column_name)}'" unless self.send(column_name).nil? 
        end 

        values.join(', ')
    end 

    def save 
        sql = <<-SQL
        INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
        VALUES (#{values_for_insert})
        SQL
        
        DB[:conn].execute(sql)
        @id = DB[:conn].execute("SELECT id FROM #{self.class.table_name} ORDER BY id DESC LIMIT 1")[0][0]
    end 

 

end