resource "nomad_job" "o3000y" {
  jobspec = file("${path.module}/../../../projects/project1/o3000y/job.nomad.hcl")
}
