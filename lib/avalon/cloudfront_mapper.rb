require 'avalon/stream_mapper'

module Avalon
  class CloudFrontMapper < DefaultStreamMapper
    def stream_details_for(path)
      p = Pathname.new(path)
      Detail.new(base_url_for(path,'rtmp'),base_url_for(path,'http'),p.dirname,p.basename(p.extname),p.extname[1..-1])
    end
  end
end

