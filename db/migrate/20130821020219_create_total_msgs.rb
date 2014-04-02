class CreateTotalMsgs < ActiveRecord::Migration
  def change
    create_table :total_msgs do |t|
      t.string :shop
      t.integer :msgnum
      t.string :msg1
      t.string :msg2
      t.string :msg3
      t.string :msg4
      t.string :msg5
      t.string :msg6
      t.string :msg7
      t.string :msg8
      t.string :msg9
      t.string :msg10
      t.string :msg11
      t.string :msg12
      t.string :msg13
      t.string :msg14
      t.string :msg15
      t.string :msg16
      t.string :msg17
      t.string :msg18
      t.string :msg19
      t.string :msg20
      t.string :msg21
      t.string :msg22
      t.string :msg23
      t.string :msg24
      t.string :msg25
      t.string :msg26
      t.string :msg27
      t.string :msg28
      t.string :msg29
      t.string :msg30

      t.timestamps
    end
  end
end
