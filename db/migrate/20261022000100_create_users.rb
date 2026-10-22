class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table(:users) { |table| user_columns(table) }
    add_index :users, 'lower(email)', unique: true, name: 'users_email_unique'
    add_check_constraint :users, "status IN ('active', 'blocked')", name: 'users_valid_status'
  end

  def user_columns(table)
    table.string :full_name, :email, :password_digest, null: false
    table.string :job_position, null: false, default: ''
    table.string :status, null: false, default: 'active'
    table.datetime :last_login_at
    table.timestamps
  end
end
