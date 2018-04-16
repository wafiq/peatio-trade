require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'
require 'mina/puma'

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :application_name, 'peatio'
set :domain, '108.160.142.29'
set :user, fetch(:application_name)
set :deploy_to, "/home/#{fetch(:user)}/ui"
set :repository, 'git@github.com:wafiq/peatio-trade.git'
set :branch, 'master'

# Optional settings:
#   set :user, 'foobar'          # Username in the server to SSH to.
#   set :port, '30000'           # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.

# Shared dirs and files will be symlinked into the app-folder by the 'deploy:link_shared_paths' step.
# Some plugins already add folders to shared_dirs like `mina/rails` add `public/assets`, `vendor/bundle` and many more
# run `mina -d` to see all folders and files already included in `shared_dirs` and `shared_files`
set :shared_dirs, fetch(:shared_dirs, []).push('log', 'tmp/pids', 'tmp/sockets')
set :shared_files, fetch(:shared_files, []).push('config/database.yml', 'config/secrets.yml', 'config/puma.rb')

# This task is the environment that is loaded for all remote run commands, such as
# `mina deploy` or `mina rake`.
task :remote_environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  invoke :'rbenv:load'
end

# Put any custom commands you need to run at setup
# All paths in `shared_dirs` and `shared_paths` will be created on their own.
task :setup do
  in_path(fetch(:shared_path)) do
    command %[mkdir -p config]
    command %[touch "#{fetch(:shared_path)}/config/database.yml"]
    command %[touch "#{fetch(:shared_path)}/config/secrets.yml"]
    command %[touch "#{fetch(:shared_path)}/config/puma.rb"]
    command %[chmod -R o-rwx config]
  end
end

namespace :config do
  desc "Run config init file."
  task :init do
    command %{
      echo "-----> Run config init file"
      #{echo_cmd %[bin/init_config]}
    }
  end
end

desc "Deploys the current version to the server."
task :deploy do
  # uncomment this line to make sure you pushed your local branch to the remote origin
  invoke :'git:ensure_pushed'
  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'config:init'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    on :launch do
      invoke :'puma:phased_restart'
    end
  end
end
