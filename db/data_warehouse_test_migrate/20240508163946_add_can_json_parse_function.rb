class AddCanJsonParseFunction < ActiveRecord::Migration[7.1]
  def change
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
end
