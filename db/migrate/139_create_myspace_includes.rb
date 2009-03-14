class CreateMyspaceIncludes < ActiveRecord::Migration
  def self.up
    create_table :myspace_includes do |t|
      t.column :myspace_include_type, :string
      t.column :url, :string
    end
    
    MyspaceInclude.reset_column_information
    
    MyspaceInclude.create :myspace_include_type => 'general', :url => "http://api.msappspace.com/OpenSocial/references/gadgets003.js"
    MyspaceInclude.create :myspace_include_type => 'general', :url => "http://api.msappspace.com/OpenSocial/references/opensocialreference001.v07.js"
    MyspaceInclude.create :myspace_include_type => 'general', :url => "http://api.msappspace.com/OpenSocial/MyOpenSpace006.Util.js"
    MyspaceInclude.create :myspace_include_type => 'general', :url => "http://api.msappspace.com/OpenSocial/MyOpenSpace005.Entities.js"
    MyspaceInclude.create :myspace_include_type => 'general', :url => "http://api.msappspace.com/OpenSocial/MyOpenSpace010.Mappers.v07.js"
    MyspaceInclude.create :myspace_include_type => 'general', :url => "http://api.msappspace.com/OpenSocial/MyOpenSpace003.Enums.js"
    MyspaceInclude.create :myspace_include_type => 'general', :url => "http://api.msappspace.com/OpenSocial/MyOpenSpace020.Core.v07.js"
    MyspaceInclude.create :myspace_include_type => 'general', :url => "http://api.msappspace.com/OpenSocial/MyOpenSpace010.Engine.js"
    MyspaceInclude.create :myspace_include_type => 'general', :url => "http://api.msappspace.com/OpenSocial/references/json001.js"
    MyspaceInclude.create :myspace_include_type => 'general', :url => "http://api.msappspace.com/OpenSocial/references/ifpc002.js"
    
    MyspaceInclude.create :myspace_include_type => 'remote_relay', :url => "http://profile.myspace.com/Modules/Common/Static/js/Apps/ifpc_relay002.html"
    
    MyspaceInclude.create :myspace_include_type => 'local_relay', :url => "http://api.msappspace.com/opensocial/references/ifpc_relay002.html"
  end

  def self.down
    drop_table :myspace_includes
  end
end
