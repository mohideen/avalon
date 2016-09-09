class ElasticTranscoderJob < ActiveEncode::Base
  before_create :upload_to_s3

  def upload_to_s3
    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])

    file_path = self.input.sub("file://", "")
    file_name = File.basename file_path
    output_file_name = File.basename(file_name, ".*") + ".mp4"
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
    flash_1200k_preset_id   = '1473357228814-ye0s5g';
    flash_2200k_preset_id   = '1351620000001-000010';
    flash_5400k_preset_id   = '1351620000001-000001';

    hls_low = {
      key: 'quality-low/hls/' + output_file_name,
      preset_id: hls_0400k_preset_id,
      segment_duration: segment_duration
    }

    hls_medium = {
      key: 'quality-medium/hls/' + output_file_name,
      preset_id: hls_1000k_preset_id,
      segment_duration: segment_duration
    }

    hls_high = {
      key: 'quality-high/hls/' + output_file_name,
      preset_id: hls_2000k_preset_id,
      segment_duration: segment_duration
    }

    flash_low = {
      key: 'quality-low/rtmp/' + output_file_name,
      preset_id: flash_1200k_preset_id
    }

    flash_medium = {
      key: 'quality-medium/rtmp/' + output_file_name,
      preset_id: flash_2200k_preset_id
    }

    flash_high = {
      key: 'quality-high/rtmp/' + output_file_name,
      preset_id: flash_5400k_preset_id
    }

    outputs = [ hls_low, hls_medium, hls_high, flash_low, flash_medium, flash_high ]

    extra_options = { pipeline_id: ENV['AWS_PIPELINE_ID'], outputs: outputs, output_key_prefix: "#{ENV['S3_OUTPUT_PREFIX']}/#{uuid}/" }
    self.options.merge! extra_options
  end
end
