pipeline {
  agent any
  options { skipDefaultCheckout() }

  environment {
    DOCKER_MAINTAINER = credentials("INFLUXDATA_DOCKER_MAINTAINER")
  }

  stages {
    stage('Setup project workspace') {
      steps {
        dir('influxdata-docker') {
          checkout scm
        }
      }
    }

    stage('Build chronograf') {
      steps {
        dir('influxdata-docker') {
          sh './circle-test.sh chronograf'
        }
      }
    }

    stage('Build influxdb') {
      steps {
        dir('influxdata-docker') {
          sh './circle-test.sh influxdb'
        }
      }
    }

    stage('Build kapacitor') {
      steps {
        dir('influxdata-docker') {
          sh './circle-test.sh kapacitor'
        }
      }
    }

    stage('Build telegraf') {
      steps {
        dir('influxdata-docker') {
          sh './circle-test.sh telegraf'
        }
      }
    }

    stage('Update official images') {
      when {
        branch 'master'
      }

      steps {
        dir('official-images') {
          checkout(
            scm: [
              $class: 'GitSCM',
              branches: [[name: '*/master' ]],
              userRemoteConfigs: [[
                credentialsId: 'jenkins-hercules-ssh',
                url: 'git@github.com:influxdata/official-images.git',
              ]],
            ],
            poll: false,
          )
          sh """git checkout master
          if ! git remote | grep upstream; then
            git remote add upstream git://github.com/docker-library/official-images.git
          else
            git remote set-url upstream git://github.com/docker-library/official-images.git
          fi
          """
        }

        withDockerContainer(image: "golang:1.9.1-stretch") {
          sh 'cd influxdata-docker; go run update.go -n'
        }

        dir('official-images') {
          withEnv(["GITHUB_USER=${DOCKER_MAINTAINER_USR}", "GITHUB_TOKEN=${DOCKER_MAINTAINER_PSW}"]) {
            withDockerContainer(image: "jsternberg/hub") {
              sh """
                if ! git diff --quiet; then
                  git commit -am "Update influxdata images"
                  git push origin master
                  if ! hub pr show &> /dev/null; then
                    hub pull-request -m "Update influxdata images"
                  fi
                fi
              """
            }
          }
        }
      }
    }
  }
}
