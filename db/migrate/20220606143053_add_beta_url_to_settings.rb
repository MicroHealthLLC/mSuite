class AddBetaUrlToSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :settings, :beta_url, :string
  end
end
