require 'docker'
require_relative '../docker_operations.rb'

# To use PROCESS_ID instead of $$ to randomize the target directory for cloning
# GitLab repository. Rubocop requirement to increase readability.
require 'English'

namespace :docker do
  desc "Build Docker image"
  task :build, [:RELEASE_PACKAGE] do |_t, args|
    release_package = args['RELEASE_PACKAGE']
    location = File.absolute_path(File.join(File.dirname(File.expand_path(__FILE__)), "../../../docker"))
    DockerOperations.build(location, release_package, "latest")
  end

  desc "Build QA Docker image"
  task :build_qa, [:RELEASE_PACKAGE] do |_t, args|
    repo = args['RELEASE_PACKAGE'] == "gitlab-ce" ? "gitlabhq" : "gitlab-ee"
    type = args['RELEASE_PACKAGE'].gsub("gitlab-", "").strip

    # PROCESS_ID is appended to ensure randomness in the directory name
    # to avoid possible conflicts that may arise if the clone's destination
    # directory already exists.
    system("git clone git@dev.gitlab.org:gitlab/#{repo}.git /tmp/#{repo}.#{$PROCESS_ID}")
    location = File.absolute_path("/tmp/#{repo}.#{$PROCESS_ID}/qa")
    DockerOperations.build(location, "gitlab-qa", "#{type}-latest")
    FileUtils.rm_rf("/tmp/#{repo}.#{$PROCESS_ID}")
  end

  desc "Clean Docker stuff"
  task :clean, [:RELEASE_PACKAGE] do |_t, args|
    DockerOperations.remove_containers
    DockerOperations.remove_dangling_images
    DockerOperations.remove_existing_images(args['RELEASE_PACKAGE'])
  end

  desc "Clean QA Docker stuff"
  task :clean_qa, [:RELEASE_PACKAGE] do |_t, args|
    DockerOperations.remove_containers
    DockerOperations.remove_dangling_images
    DockerOperations.remove_existing_images("gitlab-qa")
  end

  desc "Push Docker Image to Registry"
  task :push, [:RELEASE_PACKAGE] do |_t, args|
    docker_tag = ENV["DOCKER_TAG"]
    release_package = args['RELEASE_PACKAGE']
    DockerOperations.push(release_package, "latest", docker_tag)
  end

  desc "Push QA Docker Image to Registry"
  task :push_qa, [:RELEASE_PACKAGE] do |_t, args|
    docker_tag = ENV["DOCKER_TAG"]
    type = args['RELEASE_PACKAGE'].gsub("gitlab-", "").strip
    DockerOperations.push("gitlab-qa", "#{type}-latest", "#{type}-#{docker_tag}")
  end
end
