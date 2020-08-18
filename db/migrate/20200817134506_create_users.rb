class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :line_id
      t.string :address
      t.decimal :lat, precision: 10, scale: 6
      t.decimal :lon, precision: 10, scale: 6
      t.datetime :info_time
      t.timestamps
    end
  end
end
