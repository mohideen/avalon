SecurityHandler.rewrite_url do |url, context|
  signer = AwsCfSigner.new ENV['CLOUDFRONT_KEYFILE']
  signer.sign(url, :ending => Time.now + Avalon::Configuration.lookup('streaming.stream_token_ttl').minutes.to_i)
end
