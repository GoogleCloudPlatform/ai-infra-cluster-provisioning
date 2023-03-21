project_id = "gce-ai-infra"
name_prefix = "ci"
region = "us-central1"
zone = "us-central1-f"
machine_type = "a2-highgpu-2g"
instance_count = 1
accelerator_type = "nvidia-tesla-a100"
gpu_per_vm = 2
instance_image = {
    family = "pytorch-1-12-gpu-debian-10"
    name = ""
    project= "ml-images"
}
labels = { aiinfra-cluster = "123456" }
metadata = {}
gcs_bucket_path = "gs://aiinfra-terraform-gce-ai-infra/ci-deployment"
