# secrets

sops-encrypted, one yaml per host, decrypted at activation by sops-nix with the
recipients in `../.sops.yaml`. `hosts/hz2/default.nix` only declares secrets when
`secrets/hz2.yaml` exists, so evaluation and `nix flake check` work without it.

## hz2

The recipient is the laptop's `~/.ssh/id_ed25519`, the same key agenix used.
To move the two old agenix secrets over, on the laptop:

```
for s in discord-bot-token anthropic-api-key; do
  git show 1787a84~1:secrets/$s.age | age -d -i ~/.ssh/id_ed25519
  echo
done
sops secrets/hz2.yaml
```

and put the printed values in as:

```yaml
discord-bot-token: <value>
anthropic-api-key: <value>
hz2-hashed-password: <value>
```

`hz2-hashed-password` is a crypt(3) hash for console/rescue login, generated
with `mkpasswd -m sha-512` (pick your own password, don't reuse another
secret). Without it a freshly declared or renamed user has no password at
all: the account is locked, not blank, and booting an older generation
doesn't bring one back since generations don't version `/etc/shadow`.

Commit `secrets/hz2.yaml` (it's ciphertext) and rebuild. They land in
`/run/secrets/<name>`, owned by the user; `hz2-hashed-password` lands in
`/run/secrets-for-users/<name>` instead (`neededForUsers`, see
`hosts/hz2/default.nix`) because it must decrypt before user accounts are
created, not after.

## adding a recipient

Add its age key to `../.sops.yaml` (for an ssh key: `ssh-to-age < key.pub`),
then `sops updatekeys secrets/<host>.yaml`.
