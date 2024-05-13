class CreateArticles < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up { execute 'CREATE SCHEMA IF NOT EXISTS idp' }
      dir.down { execute 'DROP SCHEMA IF EXISTS idp' }
    end

    create_table 'idp.articles', if_not_exists: true, id: false do |t|
      t.integer :id, primary_key: false
      t.string :title
      t.text :content

      t.timestamps
    end
  end
end
