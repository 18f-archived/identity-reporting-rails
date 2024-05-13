class CreateArticles < ActiveRecord::Migration[7.1]
  def change
    execute 'CREATE SCHEMA IF NOT EXISTS idp'

    create_table 'idp.articles', if_not_exists: true, id: false do |t|
      t.integer :id, primary_key: false
      t.string :title
      t.text :content

      t.timestamps
    end
  end
end
