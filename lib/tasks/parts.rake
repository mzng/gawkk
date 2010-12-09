namespace "parts" do
  desc "generates part linkings"
  task :generate => :environment do
    
  page = -1
   while true do
     page += 1
    outer = Video.find(:all, :conditions => "slug like '%part-1'", :limit => 25, :offset => page * 25, :order => :id)

    outer.each do |o|
      next if o.nil?
      next unless o.slug =~ /part-1$/
      next if o.slug =~ /how-to/
      next if o.slug =~ /^part/
      
      puts o.slug
      other = Video.find(:all, :conditions => ["id <> #{o.id} AND slug like ?", o.slug.gsub(/part-1/, 'part-%')])

      next if other.empty?

      parts = [o.id]

      other.each do |v|
        parts << v.id
      end


      other.each do |v|
        v.next_videos = parts.join(' ')
        v.save
      end

      o.next_videos = parts.join(' ')
      o.save
    end
   end
  end
end
