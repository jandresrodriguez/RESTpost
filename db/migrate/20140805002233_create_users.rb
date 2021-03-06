class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :username
      t.string :email
      t.string :first_name
      t.string :last_name
      t.string :facebook_id
      t.string :twitter_id
      t.string :city
      t.string :country
      t.string :password

      t.timestamps
    end
  end
end
