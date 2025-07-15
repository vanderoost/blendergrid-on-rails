require "aws-sdk-sns"

class SwarmEngine
  def initialize
    @account_id = Rails.configuration.aws[:account_id]
    @region = Rails.configuration.aws[:region]
    @swarm_engine_env = Rails.configuration.swarm_engine[:env]
    puts "Swarm Engine env: #{@swarm_engine_env}"
  end

  def start_workflow(workflow)
    # Create the payload for the type of workflow (integrity check, price calculation,
    # render)

    # Publish the payload to SNS
    topic_arn = self.topic_arn
    puts topic_arn
    client.publish(message: { foo: "fight" }.to_json, topic_arn: topic_arn)
  end

  private
    def client
      @sns ||= Aws::SNS::Client.new
    end

    def topic_arn
      topic = "external-#{@swarm_engine_env}-topic"
      "arn:aws:sns:#{@region}:#{@account_id}:#{topic}"
    end
end
