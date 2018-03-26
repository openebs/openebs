#To setup_kubernetes through ansible on CentOS Platform, the following changes have been made.

Under openebs/e2e/ansible/roles/

Created 4 roles which are used to bring up kubernetes via ansible

1. k8s-localhost-centos
defaults/main.yml
-- Added k8s_cni_rpm_package repo.
-- Modified the k8s_rpm_package_alias
-- Modified the git repo link from configure_k8s_weave.sh to configure_k8s_cni.sh.
tasks/main.yml
-- Added docker,epel-release,kubernetes repos
-- Installed docker 17.03, jq-devel, python-pip after identifying the equivalents for CentOS.
-- Download the kubeadm, kubelet, kubectl rpm packages.
-- Start and enable the related services.

2. kubernetes-centos
defaults/main.yml
-- Modified the k8s_rpm_package_alias
-- Added entry for k8s.conf required for iptable setting.
tasks/main.yml
-- Added tasks to disable swap and make an entry in /etc/fstab.
-- Disable firewall.
-- cgroup configuration required for kubeadm init/join.
-- Configure Iptables.
-- Reload the systemd services, etc.

3. k8s-master-centos
defaults/main.yml
-- Modified the k8s_rpm_package_alias.
-- Modified the git repo link from configure_k8s_weave.sh to configure_k8s_cni.sh.
tasks/main.yml
-- Configured cgroup driver from systemd to cgroupfs.
-- Modified the ~/.profile to ~/.bash_profile

4. k8s-host-centos
defaults/main.yml
-- Modified the k8s_rpm_package_alias.
-- Modified the git repo link from configure_k8s_weave.sh to configure_k8s_cni.sh.
tasks/main.yml
-- Added a task to fetch the token sha from master.
-- Modified the task to join the nodes to master.
-- Configured cgroup driver from systemd to cgroupfs.
-- Modified the ~/.profile to ~/.bash_profile

Notes:

Added a Vagrantfile to bring 3 vanila centos boxes and placed under ansible/templates.
Enhanced the setup_kubernetes.yml file to pick and run roles with ENV(ubuntu or centos) specific.
