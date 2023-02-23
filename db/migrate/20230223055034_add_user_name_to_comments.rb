class AddUserNameToComments < ActiveRecord::Migration[6.1]
  def change
    add_column :comments, :user_name, :string
  end
end
