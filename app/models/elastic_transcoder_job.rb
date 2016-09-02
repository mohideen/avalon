class ElasticTranscoderJob < ActiveEncode::Base
  before_create :upload_to_s3

  def upload_to_s3
    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])

    file_path = self.input.sub("file://", "")
    file_name = File.basename file_path
    uuid = SecureRandom.uuid
    upload_prefix = ENV['S3_UPLOAD_PREFIX']
    input_key = "#{upload_prefix}/#{uuid}/#{file_name}"

    obj = s3.bucket(ENV['S3_BUCKET']).object input_key
    obj.upload_file file_path
    self.input = obj.key

    segment_duration = '2'

    hls_64k_audio_preset_id = '1351620000001-200071';
    hls_0400k_preset_id     = '1351620000001-200050';
    hls_1000k_preset_id     = '1351620000001-200030';
    hls_2000k_preset_id     = '1351620000001-200010';
    flash_2200k_preset_id   = '1351620000001-100210';

    hls_400k = {
      key: 'quality-low/' + file_name,
      preset_id: hls_0400k_preset_id,
      segment_duration: segment_duration
    }

    hls_1000k = {
      key: 'quality-medium/' + file_name,
      preset_id: hls_1000k_preset_id,
      segment_duration: segment_duration
    }

    hls_2000k = {
      key: 'quality-high/' + file_name,
      preset_id: hls_2000k_preset_id,
      segment_duration: segment_duration
    }

    flash_2200k = {
      key: 'quality-high/' + file_name,
      preset_id: flash_2200k_preset_id,
      segment_duration: segment_duration
    }

    outputs = [ hls_400k, hls_1000k, hls_2000k, flash_2200k ]

    extra_options = { pipeline_id: ENV['AWS_PIPELINE_ID'], outputs: outputs, output_key_prefix: "#{ENV['S3_OUTPUT_PREFIX']}/#{uuid}/" }
    self.options.merge! extra_options
  end
end
