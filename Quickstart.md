# Quick start Using Docker container

1. **User authentication**

    For using the Cluster Provisioning Tool(CPT) via docker container to create GPU
    clusters users need to authenticate with GCP. Authentication can happen in 2 ways

   - User authentication via gcloud and passing the authentication directory to in docker
   run command.

        ```gcloud
        gcloud auth login --update-adc
        ```

      Users can pass the authentication directory to docker run command via `-v
    ~/.config/gcloud:/root/.config/gcloud` in Linux OS and `-v
    C:\Users%username%\AppData\Roaming\gcloud:/root/.config/gcloud` in Windows OS.

   - Users can choose to prompt the CPT for authentication. They can simply skip
   providing the authentication directory in the `docker run` command and CPT will
   prompt for Authentication.

2. **Project level Access**

    Project Owner or Project Editor access is advised.
3. **Using docker image**

    - Create `terraform.tfvars` file. The sample `terraform.tfvars` for different
      cluster types can be found [here](./samples/other/).
    - Command to create/destroy Clusters. More details on different cluster types can
      be found [here](./README.md).

      > Linux

      ```Linux
      docker run -it -v ${PWD}:/root/aiinfra/input \
      -v ~/.config/gcloud:/root/.config/gcloud \
      us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
      (create|destroy) (mig|gke|gke-beta|mig-with-container)
      ```

      > Windows

      ```windows
      docker run -it -v ${PWD}:/root/aiinfra/input \
      -v C:\Users%username%\AppData\Roaming\gcloud:/root/.config/gcloud \
      us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
      (create|destroy) (mig|gke|gke-beta|mig-with-container)
      ```

# Quick start using Terraform module

1. **User authentication**

    For using the Cluster Provisioning Tool(CPT) via docker container to create GPU
    clusters users need to authenticate with GCP. Authentication can happen in 2 ways

    ```gcloud
    gcloud auth login --update-adc
    ```

1. **Project level Access**

    Project Owner or Project Editor access is advised.
1. **Using docker image**

    - Create `terraform.tfvars` file. The sample `terraform.tfvars` for different
      cluster types can be found [here](./samples/other/).
    - Create `backend.tf` file using the content below. Please make sure the
      `bucketName/foldername` GCP storage path exists before creating resources. User needs to
      have `storage object owner access` to create the GPC storage path if it does
      not exist.
      > **NOTE** The `foldername` needs to be unique for each GPU cluster. Otherwise
      > it may corrupt previously existing clusters.

      ```terraform
      terraform {
        backend "gcs" {
          // Please make sure this storage path exists
          bucket = "bucketName"
          prefix = "foldername"
        }
      }
      ```

    - Create `main.tf` file. Add a reference to the provisioning tool Terraform
      module. The reference can be added like below
      > MIG

      ```terraform
      module "aiinfra-mig" {
        source             = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//terraform/modules/cluster/mig"
      }
      ```

      > GKE

      ```terraform
      module "aiinfra-gke" {
        source             = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//terraform/modules/cluster/gke"
      }
      ```

      > SLURM

      ```terraform
      module "aiinfra-slurm" {
        source             = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//terraform/modules/cluster/slurm"
      }
      ```

    - In the `main.tf` file add a variable block for each corresponding variables in
      `terraform.tfvars`. Below is an example of `terraform .tfvars` file and the
      corresponding variable block in the `main.tf` that needs to be added.

      > `main.tf`

      ```terraform
      variable "project_id" {}
      variable "resource_prefix" {}
      variable "target_size" {}
      variable "zone" {}
      variable "machine_type" {}
      ```

      > `terraform.tfvars`

      ```terraform
      project_id      = "project-id"
      resource_prefix = "simple-mig"
      target_size     = 1
      zone            = "us-central1-a"
      machine_type    = "n1-standard-1"
      ```

    - Then run the below terraform commands
      - `terraform init` to initialize terraform
      - `terraform apply` to create the GPU cluster
      - `terraform destroy` to cleanup the GPU cluster
