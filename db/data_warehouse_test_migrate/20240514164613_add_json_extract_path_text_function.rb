class AddJsonExtractPathTextFunction < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION json_extract_path_text(json_text text, json_path text)
      RETURNS text AS $$
      DECLARE
        result text;
      BEGIN
        EXECUTE format('SELECT %L::json->>%L', json_text, json_path) INTO result;
        RETURN result;
      END;
      $$ LANGUAGE plpgsql;
    SQL
  end

  def down
    execute <<-SQL
      DROP FUNCTION IF EXISTS json_extract_path_text;
    SQL
  end
end
