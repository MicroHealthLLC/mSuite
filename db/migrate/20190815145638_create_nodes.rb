class CreateNodes < ActiveRecord::Migration[5.2]
  def change
    create_table :nodes do |t|
      t.string      :title
      t.float       :position_x
      t.float       :position_y
      t.integer     :parent_node
      t.references  :mindmap, index: true, foreign_key: true
      t.timestamps
    end
  end
end
