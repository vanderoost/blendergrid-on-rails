require "test_helper"

class DuplicatesControllerTest < ActionDispatch::IntegrationTest
  test "can not duplicate a project without blend check" do
    project = projects(:checking)

    assert_difference("Project.count", 0) do
      post project_duplicates_path(project, Project::Duplicate.new)
    end

    assert_response :unprocessable_content
  end

  test "can duplicate a project with blend check" do
    project = projects(:checked)

    assert_difference("Project.count", 1) do
      post project_duplicates_path(project, Project::Duplicate.new)
    end

    assert_response :redirect
  end

  test "duplicated projects are always in the checked state" do
    project = projects(:rendering)
    existing_project_ids = Project.pluck(:id)

    assert_difference("Project.count", 1) do
      post project_duplicates_path(project, Project::Duplicate.new)
    end
    duplicate = Project.where.not(id: existing_project_ids).first

    puts "PROJECT NAME:   #{project.name} #{project.status}"
    puts "DUPLICATE NAME: #{project.name} #{duplicate.status}"

    assert_equal "rendering", project.status
    assert_equal "checked", duplicate.status
  end

  test "project duplication also duplicates blender scenes" do
    project = projects(:three_scenes)
    existing_project_ids = Project.pluck(:id)
    assert_equal 3, project.blender_scenes.count

    assert_difference -> { Project.count } => 1, -> { BlenderScene.count } => 3 do
      post project_duplicates_path(project, Project::Duplicate.new)
    end

    duplicate = Project.where.not(id: existing_project_ids).first
    assert_equal 3, duplicate.blender_scenes.count
  end
end
