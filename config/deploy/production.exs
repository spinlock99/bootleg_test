use Bootleg.DSL
alias Bootleg.{Config, UI}
require EEx
require System

# Configure the following roles to match your environment.
# `app` defines what remote servers your distillery release should be deployed and managed on.
#
# Some available options are:
#  - `user`: ssh username to use for SSH authentication to the role's hosts
#  - `password`: password to be used for SSH authentication
#  - `identity`: local path to an identity file that will be used for SSH authentication instead of a password
#  - `workspace`: remote file system path to be used for building and deploying this Elixir project

role :app, ["localhost"], workspace: "/var/www/bootleg",
                          user: "builder",
                          app_port: 4002,
                          identity: "~/.ssh/id_ed25519",
                          silently_accept_hosts: true

task :init_systemd do
  UI.info(IO.ANSI.magenta() <> "Generating SystemD Unit File..." <> IO.ANSI.reset())

  description = Mix.Project.config()[:description]
  app_name = Mix.Project.config()[:app]
  mix_env = config({:mix_env, "prod"})
  build_role = Config.get_role(:app).hosts |> Enum.at(0)
  host_name = build_role.host.name
  app_port = build_role.options[:app_port]
  user = Config.get_role(:app).user
  workspace = Config.get_role(:app).options[:workspace]
  {output, _} = System.cmd("mix", ["phx.gen.secret"])
  secret_key_base = String.split(output, "\n", trim: true) |> Enum.at(-1)
  database_url = "ecto://postgres:postgres@#{host_name}/#{app_name}_#{mix_env}"

  unit_file_template = "config/systemd/application.service.eex"
  service = EEx.eval_file unit_file_template, app_name: app_name,
                                              description: description,
                                              workspace: workspace,
                                              user: user,
                                              app_port: app_port,
                                              mix_env: mix_env,
                                              host_name: host_name,
                                              secret_key_base: secret_key_base,
                                              database_url: database_url
  File.write!("releases/#{app_name}.service", service)

  UI.info(IO.ANSI.magenta() <> "Uploading SystemD Unit File..." <> IO.ANSI.reset())
  remote_path = "#{app_name}.service"
  local_archive_folder = "#{File.cwd!()}/releases"
  local_path = Path.join(local_archive_folder, "#{app_name}.service")
  upload(:app, local_path, remote_path)

  message = """

    You should now create a link in /etc/systemd/system/
    to allow systemd to manage the #{app_name} service.
    Then, enable the service.
  """
  command = """
      sudo ln -s #{workspace}/#{app_name}.service \\
                 /etc/systemd/system/#{app_name}.service
      systemctl enable #{app_name}
      systemctl start #{app_name}
  """
  UI.info(IO.ANSI.magenta() <> message)
  UI.info(IO.ANSI.cyan() <> command <> IO.ANSI.reset())

  message = """

    If you alread have configured the #{app_name} service, you can just reload
    the system deamons with systemctl.
  """

  command = """
      sudo systemctl daemon-reload
  """
  UI.info(IO.ANSI.magenta() <> message)
  UI.info(IO.ANSI.cyan() <> command <> IO.ANSI.reset())
end

task :init_nginx do
  UI.info(IO.ANSI.magenta() <> "Generating Nginx Configuration File..." <> IO.ANSI.reset())

  nginx_config_template = "config/nginx/application.conf.eex"
  app_name = Mix.Project.config()[:app]
  build_role = Config.get_role(:app).hosts |> Enum.at(0)
  host_name = build_role.host.name
  app_port = build_role.options[:app_port]
  workspace = Config.get_role(:app).options[:workspace]

  nginx_config = EEx.eval_file nginx_config_template, app_name: app_name,
                                                      app_port: app_port,
                                                      host_name: host_name
  File.write!("releases/#{app_name}.conf", nginx_config)

  UI.info(IO.ANSI.magenta() <> "Uploading Nginx Unit File..." <> IO.ANSI.reset())

  remote_path = "#{app_name}.conf"
  local_archive_folder = "#{File.cwd!()}/releases"
  local_path = Path.join(local_archive_folder, "#{app_name}.conf")

  upload(:app, local_path, remote_path)

  message = """

    You now need to link the sites-enabled directory to the configuration file
    and signal Nginx to reload its configuration.
  """

  command = """
      sudo ln -s #{workspace}/#{app_name}.conf \\
                 /etc/nginx/sites-enabled/#{app_name}.conf
      sudo nginx -s reload
  """
  UI.info(IO.ANSI.magenta() <> message)
  UI.info(IO.ANSI.cyan() <> command <> IO.ANSI.reset())
end
