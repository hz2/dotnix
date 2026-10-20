let
  jos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKbI0qm9KuVdB2fMQhDAxYwzQdwmsiuyMeuw7VyemXVI hz2@users.noreply.github.com";
in
{
  "discord-bot-token.age".publicKeys = [ jos ];
  "anthropic-api-key.age".publicKeys = [ jos ];
}
