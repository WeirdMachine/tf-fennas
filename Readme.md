#### Terraform for pi networks

Run:
`terraform apply -var-file=secrets.tfvars`


##### Minio - TODO: move do build server

Build arm image:

`docker build -t minio-arm -f Dockerfile.arm.release . `

### Docker Provider 

Pinned version 2.6 for docker provider since 2.7 have some issues with replacing container's that
haven't changed at all. 

[Forced container replacement with 2.7.0](https://github.com/terraform-providers/terraform-provider-docker/issues/242)

There are probably some fixes in the next version 2.8.0. 

Note that labels are different in version 2.6 and maybe some other
properties differ to the current documentation. 

### Backend

We use S3 as backend type. There are several ways to authenticate in AWS.

I use a default profile located in ``$HOME/.aws/credentials``.

````
[default]
region=eu-central-1
aws_access_key_id=
aws_secret_access_key=
````


### Docker Volumes Backup + Restore

##### [Docker best practices](https://docs.docker.com/develop/dev-best-practices/)

Waiting for feature in docker provider:

[Added a option to disable auto remove for volume](https://github.com/terraform-providers/terraform-provider-docker/pull/117)

##### Backup:

`docker run --rm --volumes-from yourcontainer -v $(pwd):/backup busybox tar cvf /backup/backup.tar /data`

##### Restore:

`docker run --rm --volumes-from yournewcontainer -v $(pwd):/backup busybox tar xvf /backup/backup.tar`

##### Docker Registry 

Create new user and password with: 
 `htpasswd -nbB fennas "password"`
  

Connect local docker daemon:
`` docker login -u "fennas" -p "password" https://registry.fanya.dev``

Note that **-p** is considered insecured. 