# ahinh43 Homelab proxmox TF code

This repository contains Terraform code used to configure and deploy VMs/LXC containers for my homelab environment. The homelab is mostly made up of old hardware that aren't really enterprise server grade material, so their performance and specs are very low compared to enterprise server hardware that costs thousands of dollars.

This code is mostly just test/playaround code that I personally would brush up a bit more if I ever considered using it in a real production environment. It still gives a good idea of how things are kind of set up though(?)


Also there is a secret tfvars file that this codebase requires. I was too cheap to pay for AWS secretsmanager or an equivalent secret holder :)