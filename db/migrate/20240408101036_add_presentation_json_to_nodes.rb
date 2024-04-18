class AddPresentationJsonToNodes < ActiveRecord::Migration[7.0]
  def change
    add_column :nodes, :presentation_html, :text
  end
end
