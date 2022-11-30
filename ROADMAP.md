# Cluster Provisioning - Roadmap

This document describes the current status and the upcoming milestones of the Cluster provisioning tool.

*Updated: Nov 29, 2022

## Milestone Summary

| Status | Milestone | ETA |
| :---: | :--- | :---: |
| 🟢 | **[Create repository and project](#create-repository-and-project)** | Q4 2022 |
| 🟡 | **[Basic feature set and LLM integration](#basic-feature-set-release-and-llm-integration)** | Dec 2022 |
| 🔴 | **[Advanced feature set for 10K+ support](#advanced-feature-set-for-10k-support)** | Mid Jan 2023 |
| 🔴 | **[GKE support](#gke-support)** | Q1 2023 |

### Create repository and project
> This milestone is for setting up the repository and projects for cluster provsioning tool. This milestone will be done when 
> * The repository for cluster provisioning tool is setup.
> * The cluster provisioning tool container image is released.

Setting up the repository will allow us to manage the code for the cluster provisioning tool and enable us to colaborate and do code reviews. Releasing the container image for the tool will enable integration with LLM pipeline and other usages. Most of the goals of this milestone is prerequiste for making progress on the second milestone.

| Status | Goal | Remarks | ETA |
| :---: | :--- | --- | :---: |
| 🟢 | CUJ Document | `CUJ doc created and reviewed internally`  | - |
| 🟢 | Cluster Provisioning design document | `Design doc Created and reviewed` | - |
| 🟢 | Test Plan | `Test plan created and reviewed internally` |-|
| 🟢 | Cluster provisioning release | `Approved` |-|
| 🟢 | Github repository | [GoogleClousPlatform/ai-infra-cluster-provisioning](https://github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning) |-|
| 🟢 | Create Project to release image | `gce-ai-infra project created` |-|


### Basic feature set release and LLM integration
> In this milestone we are targetting to create the MVP with basic functionality. This milestone will be done when
> * MVP for cluster provisioning tool is ready.
> * Public blogpost is released.

We will work on creating the MVP of cluster provisioning tool and work on integrating it with LLM pipeline. We will have the validations in place. We will release the container image for the tool as well.

| Status | Goal | Remarks | ETA |
| :---: | :--- | --- | :---: |
| 🟢 | MVP for cluster provisioning tool <ul><li>VM instance creation via MIG</li><li>Jupyter notebook endpoint for VMs</li><li>Ray cluster setup</li><li>Copy local script to VM and define startup script.</li><li>Flexible GPU and VM configuration</li></ul> | [Bug Tracking](https://github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning/issues) | - |
| 🟢 | Integration with LLM pipeline | `Done` | - |
| 🟡 | Integration and presubmit validations | `InProgress` | Dec 16, 2022 |
| 🟡 | Create artifact repository and release private image | `InProgress` | Dec 16, 2022 |
| 🔴 | Monitoring pipeline integration with cluster provisioning tool | `NotStarted` | - |
| 🔴 | Create artifact repository and release public image | `NotStarted` | - |


### Advanced feature set for 10K+ support
> The target of this milestone is to integrate advanced features to cluster provisioning tool required for 16K GPU support. As we validate more scenarios for 16K GPU we will find additional goals required to support it. This milestone will be done when we have adequate support for 16K GPU in cluster provisioning tool.

| Status | Goal | Remarks | ETA |
| :---: | :--- | --- | :---: |
| 🔴 | Integration with HPC toolkit | | - |
| 🔴 | Multi NIC instance support | | - |
| 🔴 | GCSFuse support | | - |
| 🔴 | Add automatic placement policy for large number of VMs | | - |
| 🔴 | Example scripts to run multinode training | | - |
| 🔴 | Multiple orchestartor support | | - |


### GKE support 
> This milestone targets supporting GKE clusters for running AI/ML workload. We will expand more on that once the requirements are clear.