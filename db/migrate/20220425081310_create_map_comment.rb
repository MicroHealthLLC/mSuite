class CreateMapComment < ActiveRecord::Migration[5.2]
  def change
    create_table :comments do |t|
      t.string :message
      t.string :feedback
      t.boolean :status
      t.integer :mindmap_id
      t.timestamps
    end
  end
end