require "test_helper"

class UploadTest < ActiveSupport::TestCase
  test "should be able to save a valid guest upload" do
    assert @guest_upload.save
  end

  test "should be able to save a valid user upload" do
    assert @user_upload.save
  end

  test "guest upload should have files" do
    @guest_upload.files = []
    assert_not @guest_upload.save
    assert @guest_upload.errors.key?(:files)
  end

  test "user upload should have files" do
    @user_upload.files = []
    assert_not @user_upload.save
    assert @user_upload.errors.key?(:files)
  end

  test "guest upload should have a guest email address" do
    @guest_upload.guest_email_address = ""
    assert_not @guest_upload.save
    assert @guest_upload.errors.key?(:guest_email_address)
  end

  test "guest upload should reject invalid guest email addresses" do
    valid_addresses = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org
      first.last@foo.jp alice+bob@baz.cn foo@bar.fighters]

    valid_addresses.each do |valid_address|
      @guest_upload.guest_email_address = valid_address
      assert @guest_upload.save, "#{valid_address.inspect} should be valid"
    end
  end

  test "email address validation should reject invalid addresses" do
    invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
      foo@bar_baz.com foo@bar+baz.com]

    invalid_addresses.each do |invalid_address|
      @guest_upload.guest_email_address = invalid_address
      assert_not @guest_upload.save, "#{invalid_address.inspect} should be invalid"
      assert @guest_upload.errors.key?(:guest_email_address)
    end
  end

  test "guest upload should have a guest session id" do
    @guest_upload.guest_session_id = nil
    assert_not @guest_upload.save
    assert @guest_upload.errors.key?(:guest_session_id)
  end

  test "single blend upload should return all blend filepaths" do
    upload = Upload.new(user: users(:verified_user))
    attach_blend_file(upload)

    assert_equal [ "cube-1.blend" ], upload.blend_filepaths
  end

  test "multiple blend upload should return all blend filepaths" do
    upload = Upload.new(user: users(:verified_user))
    attach_blend_file(upload, count: 3)

    assert_equal [ "cube-1.blend", "cube-2.blend", "cube-3.blend" ],
      upload.blend_filepaths
  end

  test "single zip without blends upload should return empty blend filepaths" do
    upload = Upload.new(user: users(:verified_user))
    attach_zip_file(upload)

    assert_equal [], upload.blend_filepaths
  end

  test "single zip with blends upload should return all blend filepaths" do
    upload = Upload.new(user: users(:verified_user))
    attach_zip_file(upload)
    upload.files.first.metadata[:blend_filepaths] = [ "orange.blend", "apple.blend" ]

    assert_equal [ "orange.blend", "apple.blend" ], upload.blend_filepaths
  end

  private
    def setup
      @guest_upload = Upload.new(
        guest_email_address: "test@example.com",
        guest_session_id: "1234"
      )
      attach_blend_file(@guest_upload)

      @user_upload = Upload.new(user: users(:verified_user))
      attach_blend_file(@user_upload)

      @zip_upload = Upload.new(user: users(:verified_user))
      attach_zip_file(@user_upload)
    end

    def attach_blend_file(upload, count: 1)
      count.times do |i|
        upload.files.attach(
          io: File.open(Rails.root.join("test/fixtures/files/cube.blend")),
          filename: "cube-#{i+1}.blend",
          content_type: "application/octet-stream"
        )
      end
    end

    def attach_zip_file(upload, count: 1)
      count.times do |i|
        upload.files.attach(
          io: File.open(Rails.root.join("test/fixtures/files/2-blends.zip")),
          filename: "2-blends-#{i+1}.zip",
          content_type: "application/zip"
        )
      end
    end
end
