require "test_helper"

class Upload::ZipCheckTest < ActiveSupport::TestCase
  test "handle_completion reads zip_contents from the workflow result" do
    zip_check = upload_zip_checks(:result_present_check)
    silence_zip_check_done(zip_check)

    zip_check.handle_completion

    assert_equal [ "from_result/scene.blend" ], zip_check.reload.zip_contents
  end

  test "handle_completion falls back to S3 when the workflow result is blank" do
    zip_check = upload_zip_checks(:blank_result_check)
    assert zip_check.workflow.result.blank?
    silence_zip_check_done(zip_check)

    contents = [ "archive/", "archive/scene.blend" ]
    stub_bucket(zip_check, body: contents.to_json)

    zip_check.handle_completion

    assert_equal contents, zip_check.reload.zip_contents
  end

  test "handle_completion leaves zip_contents nil when the S3 object is missing" do
    zip_check = upload_zip_checks(:blank_result_check)
    silence_zip_check_done(zip_check)
    stub_bucket(zip_check, error: "NoSuchKey")

    zip_check.handle_completion

    assert_nil zip_check.reload.zip_contents
  end

  private
    # Override the callback that fans out to attached files, which the fixtures
    # don't provide. The memoized association returns the same instance we patch.
    def silence_zip_check_done(zip_check)
      zip_check.upload.define_singleton_method(:zip_check_done) { |_| nil }
    end

    def stub_bucket(zip_check, body: nil, error: nil)
      stub = error ? { get_object: error } : { get_object: { body: body } }
      client = Aws::S3::Client.new(stub_responses: stub)
      bucket = Aws::S3::Resource.new(client: client).bucket("test-bucket")
      zip_check.define_singleton_method(:bucket) { bucket }
    end
end
