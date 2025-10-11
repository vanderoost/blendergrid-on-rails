require "test_helper"

class QuotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:checked)
  end

  test "should create benchmark" do
    assert_difference("Project::Benchmark.count", 1) do
      post quotes_url, params: {
        quote: {
          project_uuids: [ @project.uuid ],
        },
      }, headers: root_referrer_header
    end

    assert_redirected_to root_url
  end

  test "quote creation should change the project statuses to benchmarking" do
    assert @project.checked?, "project should be checked"

    post quotes_url, params: {
      quote: {
        project_uuids: [ @project.uuid ],
      },
    }, headers: root_referrer_header

    @project.reload
    assert @project.benchmarking?, "project should be benchmarking"
  end
end
