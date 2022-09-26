#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = '''
---
module: kind
short_description: Manage a kind cluster.
description:
  - Manage a kind cluster.
options:
  name:
    description:
      - Name of the cluster.
    type: str
  node_image_version:
    description:
      - Version of the node image.
      - Use a version of one of the tags listed at https://hub.docker.com/r/kindest/node/tags.
    type: str
notes:
  - You can manually destroy the custer as: kind delete cluster --name=kind; docker network rm kind.
  - When there is an error creating/starting the cluster, there is no attempt to recover/destroy it.
  - This modifies your ~/.kube/config file.
  - This requires the kind binary installed in the target host.
  - This requires the kubectl binary installed in the target host.
  - This requires the docker, kubernetes and yaml python libraries installed in the target host.
author:
  - Rui Lopes (ruilopes.com)
'''

EXAMPLES = '''
- name: Create cluster
  kind:
    name: kind
    node_image_version: 1.25.2
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
import kubernetes
import subprocess
import textwrap
import time
import yaml


# see https://github.com/yaml/pyyaml/issues/234#issuecomment-765894586
class Dumper(yaml.Dumper):
  def increase_indent(self, flow=False, *args, **kwargs):
    return super().increase_indent(flow=flow, indentless=False)


class Kind(AnsibleModule):
  def __init__(self):
    super(Kind, self).__init__(
      argument_spec=dict(
        name=dict(type='str', required=True),
        node_image_version=dict(type='str', required=True)),
      supports_check_mode=False)
    self.docker_client = docker.from_env()

  def main(self):
    name = self.params['name']
    container_name = f'{name}-control-plane'
    containers = self.docker_client.containers.list(all=True, filters={'name':container_name})
    if len(containers) > 1:
      raise Exception(f'found more than one container named {container_name}')
    elif len(containers) == 1:
      changed = self._start_cluster(containers[0])
    else:
      changed = self._create_cluster()
    network = self.docker_client.networks.get(name)
    network_cidr = network.attrs['IPAM']['Config'][0]['Subnet']
    # connect the registry container to the kind network.
    # NB this is equivalent to: docker network connect kind registry
    registry_connected_to_network = False
    for container in network.containers:
      if container.name == 'registry':
        registry_connected_to_network = True
        break
    if not registry_connected_to_network:
      network.connect('registry')
      changed = True
    self.exit_json(changed=changed, network_cidr=network_cidr)

  def _start_cluster(self, container):
    if container.status == 'running':
      return False
    container.start()
    self._wait_for_kubernetes(5*60)
    return True

  def _create_cluster(self):
    name = self.params['name']
    node_image_version = self.params['node_image_version']
    # create the cluster configuration.
    # see https://kind.sigs.k8s.io/docs/user/configuration/
    # see https://kind.sigs.k8s.io/docs/user/local-registry/
    # try wget -qSO- http://localhost:5000/v2/
    # try wget -qSO- http://localhost:5000/v2/_catalog
    # try docker exec -it kind-control-plane cat /etc/containerd/config.toml
    # try docker exec -it kind-control-plane curl -v http://registry:5000/v2/
    # try docker exec -it kind-control-plane curl -v http://registry:5000/v2/_catalog
    config = textwrap.dedent(f'''\
    apiVersion: kind.x-k8s.io/v1alpha4
    kind: Cluster
    nodes:
      - role: control-plane
        image: kindest/node:v{node_image_version}
    containerdConfigPatches:
      - |
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:5000"]
          endpoint = ["http://registry:5000"]
    ''')
    # create the cluster.
    args = [
      'kind',
      'create',
      'cluster',
      f'--name={name}',
      '--config=-']
    # TODO with check=True and when there is a non-zero exit code, the raised
    #      subprocess.CalledProcessError exception does not include
    #      stdout/stderr, which makes this impossible to troubleshoot, so we
    #      need to include that in the exception/log.
    subprocess.run(args, check=True, text=True, input=config, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    self._wait_for_kubernetes(25*60)
    # document the local registry.
    # see https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
    kubernetes_client = kubernetes.client.CoreV1Api(self._create_kubernetes_api_client())
    kubernetes_client.create_namespaced_config_map(
      namespace='kube-public',
      body=kubernetes.client.V1ConfigMap(
        api_version='v1',
        kind='ConfigMap',
        metadata=dict(name='local-registry-hosting'),
        data={
          'localRegistryHosting.v1': textwrap.dedent('''\
            host: "localhost:5000"
            help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
            ''')}))
    return True

  def _create_kubernetes_api_client(self):
    context_name = f"{self.params['name']}-kind"
    contexts, active_context = kubernetes.config.list_kube_config_contexts()
    if not contexts:
      raise Exception('cannot find any cluster in kubeconfig')
    for context in contexts:
      if context['name'] == context_name:
        return kubernetes.config.new_client_from_config(context=context_name)
    raise Exception('cannot find the cluster in kubeconfig')

  def _wait_for_kubernetes(self, timeout):
    kubernetes_client = kubernetes.client.CoreApi(api_client=self._create_kubernetes_api_client())
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
    module = Kind()
    module.main()


if __name__ == '__main__':
    main()
