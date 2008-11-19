HoptoadNotifier.configure do |config|
  config.api_key = '6a549b75ff133030063bf912f55f0b84'
  config.ignore << ArgumentError
  config.ignore << SignalException
  config.environment_filters << "AWS_SECRET"
  config.environment_filters << "EC2_PRIVATE_KEY"
  config.environment_filters << "AWS_ACCESS"
  config.environment_filters << "EC2_CERT"
end
