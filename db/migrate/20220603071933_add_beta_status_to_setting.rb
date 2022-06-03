class AddBetaStatusToSetting < ActiveRecord::Migration[5.2]
  def change
    add_column :settings, :beta_status, :boolean
  end
end
