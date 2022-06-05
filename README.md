# About

This is My Ubuntu Ansible Playbooks Playground.

This targets Ubuntu 22.04 (Jammy Jellyfish).

# Disclaimer

* These playbooks might work only when you start from scratch, in a machine that only has a minimal installation.
  * They might seem to work in other scenarios, but that is by pure luck.
  * There is no support for upgrades, downgrades, or un-installations.

# Usage

Add your machines into the Ansible [`inventory.yml` file](inventory.yml).

Review the [`development.yml` playbook](development.yml).

See the facts about the `dm1` machine:

```bash
./ansible.sh dm1 -m ansible.builtin.setup
```

Run an ad-hoc command in the `dm1` machine:

```bash
./ansible.sh dm1 -a 'id'
```

Run the [`development.yml` playbook](development.yml) against the `dm1` machine:

```bash
./ansible-playbook.sh --limit=dm1 development.yml
```
