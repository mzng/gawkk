class AWS::S3::Logging::Log
  class Line 
    class << self
      # Time.parse doesn't like %d/%B/%Y:%H:%M:%S %z so we have to transform it unfortunately
      def typecast_time(datetime) #:nodoc:
        month = datetime[/[a-z]+/i]
        datetime.sub!(%r|^(\w{2})/(\w{3})|, '\2/\1')
        datetime.sub!(month, (Date.constants.member?('ABBR_MONTHS') ? Date::ABBR_MONTHS : Date::Format::ABBR_MONTHS)[month.downcase].to_s)
        datetime.sub!(':', ' ')
        Time.parse(datetime)
      end 
    end
  end
end