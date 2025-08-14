# About

[![Build status](https://github.com/rgl/my-ubuntu-ansible-playbooks/workflows/build/badge.svg)](https://github.com/rgl/my-ubuntu-ansible-playbooks/actions?query=workflow%3Abuild)

This is My Ubuntu Ansible Playbooks Playground.

This targets Ubuntu 22.04 (Jammy Jellyfish).

## Disclaimer

* These playbooks might work only when you start from scratch, in a machine that only has a minimal installation.
  * They might seem to work in other scenarios, but that is by pure luck.
  * There is no support for upgrades, downgrades, or un-installations.

## Usage

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

Lint the `development.yml` playbook:

```bash
./ansible-lint.sh --offline --parseable development.yml || echo 'ERROR linting'
```

Run the `development.yml` playbook against the `dm1` machine:

```bash
./ansible-playbook.sh --limit=dm1 development.yml | tee ansible.log
```

Lint the code:

```bash
./mega-linter.sh
```

List this repository dependencies (and which have newer versions):

```bash
export GITHUB_COM_TOKEN='YOUR_GITHUB_PERSONAL_TOKEN'
./renovate.sh
```

At the machine where the playbook is provisioned, you can use the
applications described in the next sections.

## Kubernetes

See [roles/kind](roles/kind/README.md).
