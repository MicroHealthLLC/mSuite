class CreateMindmapUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :mindmap_users do |t|
      t.bigint :user_id
      t.bigint :mindmap_id
      t.timestamps
    end

    add_column :mindmaps, :category_id, :bigint
    add_column :mindmaps, :share, :integer, default: 0
    add_column :mindmaps, :expires_at, :datetime
  end
end
