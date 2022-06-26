#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = '''
---
module: talos_cluster_docker
short_description: Manage a talos cluster in docker
description:
  - Manage a talos cluster in docker.
options:
  name:
    description:
      - Name of the cluster.
    type: str
  exposed_ports:
    description:
      - List of exposed ports.
      - Ports 0.0.0.0:6443->6443/tcp and 0.0.0.0:50000->50000/tcp are always exposed by talos regardless of what is defined in this property.
    type: list
    elements: str
notes:
  - When there is an error creating/starting the cluster, there is no attempt to recover/destroy it.
  - This modifies your ~/.talos/config and ~/.kube/config files.
  - This requires the talosctl binary installed in the target host.
  - This requires the kubectl binary installed in the target host.
  - This requires the docker, kubernetes and yaml python libraries installed in the target host.
author:
  - Rui Lopes (ruilopes.com)
'''

EXAMPLES = '''
- name: Create cluster
  talos_cluster_docker:
    name: talos
    exposed_ports:
      - 32443:32443/tcp
'''

RETURN = '''
network_cidr:
  description:
    - The network CIDR.
  returned: success
  type: str
'''


from ansible.module_utils.basic import AnsibleModule
import docker
import io
import kubernetes
import os.path
import subprocess
import time
import yaml


# see https://github.com/yaml/pyyaml/issues/234#issuecomment-765894586
class Dumper(yaml.Dumper):
  def increase_indent(self, flow=False, *args, **kwargs):
    return super().increase_indent(flow=flow, indentless=False)


class TalosClusterDocker(AnsibleModule):
  def __init__(self):
    super(TalosClusterDocker, self).__init__(
      argument_spec=dict(
        name=dict(type='str', required=True),
        exposed_ports=dict(type='list', elements='str')),
      supports_check_mode=False)
    self.docker_client = docker.from_env()

  def main(self):
    name = self.params['name']
    container_name = f'{name}-master-1'
    containers = self.docker_client.containers.list(all=True, filters={'name':container_name})
    if len(containers) > 1:
      raise Exception(f'found more than one container named {container_name}')
    elif len(containers) == 1:
      changed = self._start_cluster(containers[0])
    else:
      changed = self._create_cluster()
    network_cidr = self.docker_client.networks.get(name).attrs['IPAM']['Config'][0]['Subnet']
    self.exit_json(changed=changed, network_cidr=network_cidr)

  def _start_cluster(self, container):
    if container.status == 'running':
      # TODO reconfigure the container when it does not have the expected exposed_ports configuration.
      return False
    container.start()
    self._wait_for_kubernetes(5*60)
    return True

  def _create_cluster(self):
    name = self.params['name']
    exposed_ports = self.params['exposed_ports'] or []
    # delete the cluster from config.
    # NB when it exists, talosctl will create a new context called, e.g.,
    #    admin@<name>-<index>, which goes against our expectation of
    #    admin@<name>.
    self._delete_cluster_from_config()
    # create the cluster.
    args = [
      'talosctl',
      'cluster',
      'create',
      f'--name={name}',
      f'--exposed-ports={",".join(exposed_ports)}',
      '--workers=0',
      '--with-kubespan=false',
      '--with-cluster-discovery=false']
    # TODO with check=True and when there is a non-zero exit code, the raised
    #      subprocess.CalledProcessError exception does not include
    #      stdout/stderr, which makes this impossible to troubleshoot, so we
    #      need to include that in the exception/log.
    subprocess.run(args, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    self._wait_for_kubernetes(25*60)
    return True

  def _delete_cluster_from_config(self):
    changed = False
    cluster_name = self.params['name'] # used in ~/.talos/config
    context_name = f"admin@{cluster_name}" # used in ~/.kube/config
    # delete context from ~/.talos/config
    # NB there is no talosctl config delete-context command.
    config_path = os.path.expanduser('~/.talos/config')
    if os.path.exists(config_path):
      config_orig = open(config_path, 'r', encoding='utf-8').read()
      document = yaml.load(config_orig, Loader=yaml.FullLoader)
      context = document['contexts'].get(cluster_name)
      if context:
        del document['contexts'][cluster_name]
        config_stream = io.StringIO()
        yaml.dump(document, config_stream, Dumper=Dumper, default_flow_style=False, indent=4)
        config = config_stream.getvalue()
        open(config_path, 'w', encoding='utf-8').write(config)
        changed = True
    # delete the cluster, user and context from ~/.kube/config
    config_path = os.path.expanduser('~/.kube/config')
    if os.path.exists(config_path):
      contexts, active_context = kubernetes.config.list_kube_config_contexts()
      for context in contexts:
        name = context['name']
        if name == context_name:
          subprocess.run(
            ['kubectl', 'config', 'delete-cluster', cluster_name],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)
          subprocess.run(
            ['kubectl', 'config', 'delete-user', name],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)
          subprocess.run(
            ['kubectl', 'config', 'delete-context', name],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)
          changed = True
          break
    return changed

  def _create_kubernetes_client(self):
    context_name = f"admin@{self.params['name']}"
    contexts, active_context = kubernetes.config.list_kube_config_contexts()
    if not contexts:
      raise Exception('cannot find any cluster in kubeconfig')
    for context in contexts:
      if context['name'] == context_name:
        return kubernetes.client.CoreApi(api_client=kubernetes.config.new_client_from_config(context=context_name))
    raise Exception('cannot find the cluster in kubeconfig')

  def _wait_for_kubernetes(self, timeout):
    kubernetes_client = self._create_kubernetes_client()
    start = time.monotonic()
    while True:
      if time.monotonic() - start > timeout:
        raise Exception('timeout while waiting for kubernetes to be available')
      try:
        kubernetes_client.get_api_versions()
        break
      except:
        # TODO to troubleshoot, log the exception to ansible.
        time.sleep(3)


def main():
    module = TalosClusterDocker()
    module.main()


if __name__ == '__main__':
    main()
