use Bootleg.DSL

# Configure the following roles to match your environment.
# `build` defines what remote server your distillery release should be built on.
#
# Some available options are:
#  - `user`: ssh username to use for SSH authentication to the role's hosts
#  - `password`: password to be used for SSH authentication
#  - `identity`: local path to an identity file that will be used for SSH authentication instead of a password
#  - `workspace`: remote file system path to be used for building and deploying this Elixir project
use Bootleg.DSL
alias Bootleg.{Config, UI}

role :build, "localhost", workspace: "/home/builder/build",
                          user: "builder",
                          identity: "~/.ssh/id_ed25519",
                          silently_accept_hosts: true

task :run_phoenix_tasks do
  mix_env = config({:mix_env, "prod"})
  source_path = config({:ex_path, ""})

  UI.info("Running Phoenix Tasks..")

  remote :build, cd: source_path do
    "MIX_ENV=#{mix_env} mix assets.deploy"
    "MIX_ENV=#{mix_env} mix phx.gen.release"
  end
end

before_task(:remote_generate_release, :run_phoenix_tasks)

