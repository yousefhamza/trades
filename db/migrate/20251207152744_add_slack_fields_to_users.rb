class AddSlackFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :slack_user_id, :string
    add_column :users, :slack_team_id, :string
    add_column :users, :slack_access_token, :string
    add_index :users, :slack_user_id, unique: true
  end
end
