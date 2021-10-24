class CreateStage < ActiveRecord::Migration[5.2]
  def change
    create_table :stages do |t|
      t.string :title
      t.integer :mindmap_id
      t.timestamps
    end
  end
end
