# Creates a sample VSM with single frontend and backend controller. 
job "demo-vsm1" {

	datacenters = ["dc1"]

	# Restrict our job to only linux. We can specify multiple
	# constraints as needed.
	constraint {
		attribute = "${attr.kernel.name}"
		value = "linux"
	}

	#Declare the IP parameters generic to all controllers and replicas
	meta {
		JIVA_VOLNAME = "demo-vsm1-vol1"
		JIVA_VOLSIZE = "10g"
		JIVA_FRONTEND_VERSION = "openebs/jiva:latest"
		JIVA_FRONTEND_NETWORK = "host_static"
		JIVA_FRONTENDIP = "172.28.128.101"
		JIVA_FRONTENDSUBNET = "24"
		JIVA_FRONTENDINTERFACE = "enp0s8"
	}

	# Create a 'frontend container' group.
	group "demo-vsm1-fe" {
		# Configure the restart policy for the task group. If not provided, a
		# default is used based on the job type.
		restart {
			# The number of attempts to run the job within the specified interval.
			attempts = 3
			interval = "5m"
			delay = "25s"
			mode = "delay"
		}

		# Define the controller task to run
		task "fe" {
			# Use a docker wrapper to run the task.
			driver = "raw_exec"
			artifact {
				source = "https://raw.githubusercontent.com/openebs/jiva/master/scripts/launch-jiva-ctl-with-ip"
			}

			env {
				JIVA_CTL_NAME = "${NOMAD_JOB_NAME}-${NOMAD_TASK_NAME}"
				JIVA_CTL_VERSION = "${NOMAD_META_JIVA_FRONTEND_VERSION}"
				JIVA_CTL_VOLNAME = "${NOMAD_META_JIVA_VOLNAME}"
				JIVA_CTL_VOLSIZE = "${NOMAD_META_JIVA_VOLSIZE}"
				JIVA_CTL_IP = "${NOMAD_META_JIVA_FRONTENDIP}"
				JIVA_CTL_SUBNET = "${NOMAD_META_JIVA_FRONTENDSUBNET}"
				JIVA_CTL_IFACE = "${NOMAD_META_JIVA_FRONTENDINTERFACE}"
			}

			config {
				command = "launch-jiva-ctl-with-ip"
			}

			# We must specify the resources required for
			# this task to ensure it runs on a machine with
			# enough capacity.
			resources {
				cpu = 500 # 500 MHz
				memory = 256 # 256MB
				network {
					mbits = 100
				}
			}

		}
	}

	# Create a 'backend container' group.
	group "demo-vsm1-backend-container1" {
		# Configure the restart policy for the task group. If not provided, a
		# default is used based on the job type.
		restart {
			# The number of attempts to run the job within the specified interval.
			attempts = 3
			interval = "5m"
			delay = "25s"
			mode = "delay"
		}

		# Define the parameters for the backend container
		task "be-store1" {
			# Use a docker wrapper to run the task.
			driver = "raw_exec"
			artifact {
				source = "https://raw.githubusercontent.com/openebs/jiva/master/scripts/launch-jiva-rep-with-ip"
			}

			env {
				JIVA_REP_NAME = "${NOMAD_JOB_NAME}-${NOMAD_TASK_NAME}"
				JIVA_CTL_IP = "${NOMAD_META_JIVA_FRONTENDIP}"
				JIVA_REP_VOLNAME = "${NOMAD_META_JIVA_VOLNAME}"
				JIVA_REP_VOLSIZE = "${NOMAD_META_JIVA_VOLSIZE}"
				JIVA_REP_VOLSTORE = "/tmp/jiva/vsm1/rep1"
				JIVA_REP_VERSION = "openebs/jiva:latest"
		                JIVA_REP_NETWORK = "host_static"
				JIVA_REP_IFACE = "enp0s8"
				JIVA_REP_IP = "172.28.128.102"
				JIVA_REP_SUBNET = "24"
			}

			config {
				command = "launch-jiva-rep-with-ip"
			}

			# We must specify the resources required for
			# this task to ensure it runs on a machine with
			# enough capacity.
			resources {
				cpu = 500 # 500 MHz
				memory = 256 # 256MB
				network {
					mbits = 100
				}
			}

		}
	}
}
