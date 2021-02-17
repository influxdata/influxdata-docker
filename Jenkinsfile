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

    stage('Build docker images') {
      parallel {
        stage('chronograf') {
          steps {
            dir('influxdata-docker') {
              sh './circle-test.sh chronograf'
            }
          }
        }

        stage('influxdb') {
          steps {
            dir('influxdata-docker') {
              sh './circle-test.sh influxdb'
            }
          }
        }

        stage('kapacitor') {
          steps {
            dir('influxdata-docker') {
              sh './circle-test.sh kapacitor'
            }
          }
        }

        stage('telegraf') {
          steps {
            dir('influxdata-docker') {
              sh './circle-test.sh telegraf'
            }
          }
        }
      }
    }

    stage('Update official images') {
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

          // Reset master to the value at origin.
          sh "git checkout master && git reset --hard origin/master"
        }

        dir('influxdata-docker') {
          sh "docker build -t influxdata/dockerlib:build-${BUILD_NUMBER} dockerlib"
        }

        withDockerContainer(image: "influxdata/dockerlib:build-${BUILD_NUMBER}") {
          sh "cd influxdata-docker; dockerlib update"
        }
      }

      post {
        always {
          sh "docker rmi -f influxdata/dockerlib:build-${BUILD_NUMBER}"
        }
      }
    }

    stage('Push changes to GitHub') {
      when {
        expression {
          return sh(returnStatus: true, script: 'cd official-images; git diff --quiet') != 0
        }
      }

      steps {
        dir('official-images') {
          sshagent(credentials: ['jenkins-hercules-ssh']) {
            sh """
              git -c user.name="Jonathan A. Sternberg" -c user.email="jonathan@influxdb.com" commit -am "Update influxdata images"
              git push origin master
            """
          }

          sh """
            desired_remote_url=git://github.com/docker-library/official-images.git
            if current_remote_url=\$(git remote get-url upstream 2> /dev/null); then
              if [ "\$current_remote_url" != "\$desired_remote_url" ]; then
                git remote set-url upstream "\$desired_remote_url"
              fi
            else
              git remote add upstream "\$desired_remote_url"
            fi
          """

          sh "docker pull jsternberg/hub"
          withEnv(["GITHUB_USER=${DOCKER_MAINTAINER_USR}", "GITHUB_TOKEN=${DOCKER_MAINTAINER_PSW}"]) {
            withDockerContainer(image: "jsternberg/hub") {
              sh """
                if ! hub pr show; then
                  hub pull-request -m "Update influxdata images"
                fi
              """
            }
          }
        }
      }
    }
  }

  post {
    changed {
      script {
        if ( currentBuild.currentResult == 'SUCCESS' ) {
          slackSend(channel: '#docker-builds', color: '#00FF00', message: '@channel the docker build has returned back to normal.')
        } else {
          slackSend(channel: '#docker-builds', color: '#FF0000', message: '@channel the docker build has failed!')
        }
      }
    }
  }
}
