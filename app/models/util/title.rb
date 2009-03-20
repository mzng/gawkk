class Util::Title
  def self.from_url(url)
    doc = Hpricot(open(url))
    title = (doc/"head title").inner_html
    Util::Title.scrub(title)
  end
  
  def self.scrub(title)
    Util::Scrub.title(title)
  end
end