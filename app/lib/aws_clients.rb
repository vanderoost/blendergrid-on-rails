module AwsClients
  def self.sns
    @sns ||= Aws::SNS::Client.new
  end
end
