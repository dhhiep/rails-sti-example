class CreateSpreeBanners < ActiveRecord::Migration
  def change
    create_table :banners do |t|
      t.string :name
      t.string :type
      t.attachment :attachment
      t.integer :position
      t.boolean :active, :defaut => true
      t.text :data
      
      t.timestamps
    end
  end
end
