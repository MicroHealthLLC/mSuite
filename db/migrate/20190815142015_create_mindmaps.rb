class CreateMindmaps < ActiveRecord::Migration[5.2]
  def change
    create_table :mindmaps do |t|
      t.string :name
      t.timestamps
    end
  end
end
