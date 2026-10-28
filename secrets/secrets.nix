let
  hz2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKbI0qm9KuVdB2fMQhDAxYwzQdwmsiuyMeuw7VyemXVI";
in
{
  "discord-bot-token.age".publicKeys = [ hz2 ];
  "anthropic-api-key.age".publicKeys = [ hz2 ];
}
