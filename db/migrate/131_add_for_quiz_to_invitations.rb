class AddForQuizToInvitations < ActiveRecord::Migration
  def self.up
    add_column :invitations, :for_quiz, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :invitations, :for_quiz
  end
end
