class AddListAggFunction < ActiveRecord::Migration[7.2]
  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION listagg_agg(state text, value text, delimiter text)
      RETURNS text IMMUTABLE AS $$
      BEGIN
        IF state IS NULL THEN
          RETURN value;
        ELSE
          RETURN state || delimiter || value;
        END IF;
      END;
      $$ LANGUAGE plpgsql;

      CREATE OR REPLACE FUNCTION listagg_final(state text)
      RETURNS text IMMUTABLE AS $$
      BEGIN
        RETURN state;
      END;
      $$ LANGUAGE plpgsql;

      CREATE AGGREGATE listagg(text, text)
      (
        SFUNC = listagg_agg,
        STYPE = text,
        FINALFUNC = listagg_final
      );
    SQL
  end

  def down
    execute <<-SQL
      DROP AGGREGATE IF EXISTS listagg(text, text);
      DROP FUNCTION IF EXISTS listagg_agg(text, text, text);
      DROP FUNCTION IF EXISTS listagg_final(text);
    SQL
  end
end
