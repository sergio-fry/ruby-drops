class CreateDropStorages < ActiveRecord::Migration[5.0]
  def change
    create_table :drop_storages do |t|
      t.string :name
      t.text :store

      t.timestamps
    end
  end
end
