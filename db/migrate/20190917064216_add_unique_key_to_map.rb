class AddUniqueKeyToMap < ActiveRecord::Migration[5.2]

  def change
    add_column  :mindmaps, :unique_key, :string
    
    Mindmap.find_each do |map|
      map.update_column('unique_key', map.id)
    end

    add_index :mindmaps, :unique_key, unique: true
  end
end
