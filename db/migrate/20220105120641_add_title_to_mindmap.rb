class AddTitleToMindmap < ActiveRecord::Migration[5.2]
  def change
    add_column :mindmaps, :title, :string, default: 'Title'
  end
end
