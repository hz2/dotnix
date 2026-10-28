# secrets

sops-encrypted, one yaml per host. agenix was dropped for sops-nix; see
git history before this commit for the old agenix recipe (`secrets.nix`,
`secrets/*.age`, commit `ab0f331`).

## migrating an existing checkout

The host config now reads `secrets/hz2.yaml`, which this repo doesn't ship
(public repo, no plaintext or ciphertext secrets in history going forward).
Before pulling this change, recover the old plaintext values with your
personal ssh key:

```
age -d -i ~/.ssh/id_ed25519 secrets/discord-bot-token.age
age -d -i ~/.ssh/id_ed25519 secrets/anthropic-api-key.age
```

If you've already pulled, get the old files back from history first:

```
git show ab0f331:secrets/discord-bot-token.age > /tmp/discord-bot-token.age
git show ab0f331:secrets/anthropic-api-key.age > /tmp/anthropic-api-key.age
age -d -i ~/.ssh/id_ed25519 /tmp/discord-bot-token.age
age -d -i ~/.ssh/id_ed25519 /tmp/anthropic-api-key.age
```

## creating secrets/hz2.yaml

1. Derive your age recipient from the ssh key and put it in `.sops.yaml` in
   place of the `age1REPLACE_WITH_...` placeholder:

   ```
   ssh-to-age < ~/.ssh/id_ed25519.pub
   ```

2. Create the file (sops uses `.sops.yaml` to pick the recipient and editor):

   ```
   sops secrets/hz2.yaml
   ```

3. Add the two keys the host expects, with the values recovered above:

   ```yaml
   discord-bot-token: <value>
   anthropic-api-key: <value>
   ```

`hosts/hz2/default.nix` guards `sops.secrets` with `builtins.pathExists`, so
`nix flake check` and `nix flake show` work before this file exists; the
actual `openclaw` secrets just won't be available until it's created.
