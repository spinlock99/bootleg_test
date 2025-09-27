use Bootleg.DSL
alias Bootleg.{Config, UI}

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
                          identity: "~/.ssh/id_ed25519",
                          silently_accept_hosts: true

task :init_systemd do
  require EEx
  require System

  UI.info("Initalizing SystemD...")

  description = Mix.Project.config()[:description]
  port = 4002
  app_name = Mix.Project.config()[:app]
  mix_env = config({:mix_env, "prod"})
  build_role = Config.get_role(:app).hosts |> Enum.at(0)
  host_name = build_role.host.name
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
                                              port: port,
                                              mix_env: mix_env,
                                              host_name: host_name,
                                              secret_key_base: secret_key_base,
                                              database_url: database_url
  File.write!("releases/#{app_name}.service", service)

  remote_path = "#{app_name}.service"
  local_archive_folder = "#{File.cwd!()}/releases"
  local_path = Path.join(local_archive_folder, "#{app_name}.service")
  UI.info("Upload SystemD Service Definition")
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
end
