class CleanUpInvitations < ActiveRecord::Migration
  def self.up
    remove_column :invitations, :for_quiz
    
    Invitation.reset_column_information
    Invitation.delete_all
  end

  def self.down
    add_column :invitations, :for_quiz, :boolean, :default => false, :null => false
  end
end
