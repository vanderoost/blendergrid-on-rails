require "test_helper"

class Project::IntakeTest < ActiveSupport::TestCase
  setup do
    @upload = uploads(:guest_upload)
  end

  test "should be valid with upload and blend_files" do
    intake = Project::Intake.new(
      upload: @upload,
      blend_files: [ "file1.blend", "file2.blend" ]
    )
    assert intake.save
  end

  test "should be invalid without upload" do
    intake = Project::Intake.new(blend_files: [ "file1.blend" ])
    assert_not intake.save
  end

  test "should be invalid without blend_files" do
    intake = Project::Intake.new(upload: @upload)
    assert_not intake.save
  end

  test "should be inalid for empty blend_files array" do
    intake = Project::Intake.new(upload: @upload, blend_files: [])
    assert_not intake.save
  end
end
