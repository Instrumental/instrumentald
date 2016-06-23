require 'capistrano'

if Capistrano::Configuration.instance
  Capistrano::Configuration.instance.load do
    namespace :instrumental do
      desc "restart daemonized server; also starts up if not running"
      task :restart_instrumentald do
        run "cd #{current_path} && bundle exec instrumentald -k #{instrumental_key} -d restart"
      end
    end

    after "deploy", "instrumental:restart_instrumentald"
    after "deploy:migrations", "instrumental:restart_instrumentald"
  end
end
