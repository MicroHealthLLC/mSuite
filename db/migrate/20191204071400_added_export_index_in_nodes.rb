class AddedExportIndexInNodes < ActiveRecord::Migration[5.2]
  def change
    add_column :nodes, :export_index, :integer, default: nil
    Rake::Task['nodes:add_export_indexes_to_nodes'].invoke
  end
end
