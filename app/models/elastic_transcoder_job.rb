class ElasticTranscoderJob < ActiveEncode::Base
  before_create :upload_to_s3

  def upload_to_s3
    puts encode.inspect
  end
end
