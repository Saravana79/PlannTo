class AddPlanntoNetworkToUserQuestion < ActiveRecord::Migration
  def change
    add_column :user_questions, :plannto_network, :boolean
  end
end
