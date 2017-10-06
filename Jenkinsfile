pipeline {
  agent any
  options { skipDefaultCheckout() }

  stages {
    stage('Setup project workspace') {
      steps {
        dir('influxdata-docker') {
          checkout scm
        }
      }
    }

    stage('Build docker files') {
      parallel {
        stage('Chronograf') {
          steps {
            dir('influxdata-docker') {
              sh './circle-test.sh chronograf'
            }
          }
        }
        stage('InfluxDB') {
          steps {
            dir('influxdata-docker') {
              sh './circle-test.sh influxdb'
            }
          }
        }
        stage('Kapacitor') {
          steps {
            dir('influxdata-docker') {
              sh './circle-test.sh kapacitor'
            }
          }
        }
        stage('Telegraf') {
          steps {
            dir('influxdata-docker') {
              sh './circle-test.sh telegraf'
            }
          }
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
          sh 'git checkout master'
        }

        withDockerContainer(image: "golang:1.9.1-stretch") {
          sh 'cd influxdata-docker; go run update.go -n'
        }

        dir('official-images') {
          sh """
            if ! git diff --quiet; then
              git commit -am "Update influxdata images"
              git push origin master
            fi
          """
        }
      }
    }
  }
}
