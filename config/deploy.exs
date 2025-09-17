use Bootleg.DSL

# Configure the following roles to match your environment.
# `build` defines what remote server your distillery release should be built on.
#
# Some available options are:
#  - `user`: ssh username to use for SSH authentication to the role's hosts
#  - `password`: password to be used for SSH authentication
#  - `identity`: local path to an identity file that will be used for SSH authentication instead of a password
#  - `workspace`: remote file system path to be used for building and deploying this Elixir project

role :build, "staging.haikuter.com",
  workspace: "/var/www/bootleg_test",
  user: "builder",
  identity: "~/.ssh/id_ed25519",
  silently_accept_hosts: true
