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
```

Commit `secrets/hz2.yaml` (it's ciphertext) and rebuild. They land in
`/run/secrets/<name>`, owned by the user.

## adding a recipient

Add its age key to `../.sops.yaml` (for an ssh key: `ssh-to-age < key.pub`),
then `sops updatekeys secrets/<host>.yaml`.
