#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = '''
---
module: k3d
short_description: Manage a k3d cluster.
description:
  - Manage a k3d cluster.
options:
  name:
    description:
      - Name of the cluster.
    type: str
  k3s_args:
    description:
      - k3s arguments.
    type: list
    elements: str
notes:
  - You can manually destroy the custer as: k3d cluster delete k3d.
  - When there is an error creating/starting the cluster, there is no attempt to recover/destroy it.
  - This modifies your ~/.kube/config file.
  - This requires the k3d binary installed in the target host.
  - This requires the kubectl binary installed in the target host.
  - This requires the docker, kubernetes and yaml python libraries installed in the target host.
author:
  - Rui Lopes (ruilopes.com)
'''

EXAMPLES = '''
- name: Create cluster
  k3d:
    name: k3d
    k3s_args:
      - --disable=traefik
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
import json
import kubernetes
import subprocess
import time
import yaml


# see https://github.com/yaml/pyyaml/issues/234#issuecomment-765894586
class Dumper(yaml.Dumper):
  def increase_indent(self, flow=False, *args, **kwargs):
    return super().increase_indent(flow=flow, indentless=False)


class K3d(AnsibleModule):
  def __init__(self):
    # TODO add support for --config https://k3d.io/v5.4.7/usage/configfile/
    super(K3d, self).__init__(
      argument_spec=dict(
        name=dict(type='str', required=True),
        k3s_args=dict(type='list', elements='str')),
      supports_check_mode=False)
    self.docker_client = docker.from_env()

  def main(self):
    name = self.params['name']
    cluster = self._get_cluster(name)
    if cluster:
      changed = self._start_cluster(cluster)
    else:
      changed = self._create_cluster()
    network_cidr = self.docker_client.networks.get(f'k3d-{name}').attrs['IPAM']['Config'][0]['Subnet']
    self.exit_json(changed=changed, network_cidr=network_cidr)

  def _get_cluster(self, name):
    args = [
      'k3d',
      'cluster',
      'ls',
      '-o=json',
      name]
    result = subprocess.run(args, check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode == 0:
      clusters = json.loads(result.stdout)
      if len(clusters) > 1:
        raise Exception(f'found more than one cluster named {name}')
      elif len(clusters) == 1 and clusters[0]['name'] == name:
        return clusters[0]
    return None

  def _start_cluster(self, cluster):
    for node in cluster['nodes']:
      if not node['State']['Running']:
        args = [
          'k3d',
          'cluster',
          'start',
          cluster['name']]
        subprocess.run(args, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self._wait_for_kubernetes(5*60)
        return True
    return False

  def _create_cluster(self):
    name = self.params['name']
    k3s_args = self.params['k3s_args']
    # create the cluster.
    args = [
      'k3d',
      'cluster',
      'create',
      name,
      '--no-lb']
    for value in k3s_args:
      args.append('--k3s-arg')
      args.append(value)
    # TODO with check=True and when there is a non-zero exit code, the raised
    #      subprocess.CalledProcessError exception does not include
    #      stdout/stderr, which makes this impossible to troubleshoot, so we
    #      need to include that in the exception/log.
    subprocess.run(args, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return True

  def _create_kubernetes_client(self):
    context_name = f"k3d-{self.params['name']}"
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
      except Exception as e:
        # TODO to troubleshoot, log the exception to ansible.
        time.sleep(3)


def main():
    module = K3d()
    module.main()


if __name__ == '__main__':
    main()
