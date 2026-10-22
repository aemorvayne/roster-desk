class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |table|
      table.references :user, null: false, foreign_key: { on_delete: :cascade }
      table.timestamps
    end
  end
end
