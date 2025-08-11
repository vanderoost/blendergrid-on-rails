require "test_helper"

class QuotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:checked_project)
  end

  test "should create quote" do
    assert_difference("Project::Benchmark.count", 1) do
      post quotes_url, params: {
        quote: {
          project_settings: { @project.uuid => { "frame_range_type" => "image" } },
        },
      }, headers: root_referrer_header
    end
    assert_redirected_to root_url
  end
end
