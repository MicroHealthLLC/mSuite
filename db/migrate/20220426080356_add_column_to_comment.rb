class AddColumnToComment < ActiveRecord::Migration[5.2]
  def change
    add_column  :comments, :parent_comment, :integer
  end
end