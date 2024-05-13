class AddCanJsonParseFunction < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION can_json_parse(json_string text)
      RETURNS boolean AS $$
      DECLARE
        result json;
      BEGIN
        result := json_string::json;
        RETURN true;
      EXCEPTION WHEN others THEN
        RETURN false;
      END;
      $$ LANGUAGE plpgsql;
    SQL
  end

  def down
    execute <<-SQL
      DROP FUNCTION IF EXISTS can_json_parse;
    SQL
  end
end