class AddPasswordToMindmap < ActiveRecord::Migration[5.2]
  def change
    add_column :mindmaps, :password, :string
  end
end
