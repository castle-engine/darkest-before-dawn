/* -*- mode: groovy -*-
  Confgure how to run our job in Jenkins.
  See https://github.com/castle-engine/castle-engine/wiki/Cloud-Builds-(Jenkins) .
*/

pipeline {
  triggers {
    pollSCM('H/4 * * * *')
    upstream(upstreamProjects: 'castle_game_engine_organization/castle-engine-cloud-builds-tools/master', threshold: hudson.model.Result.SUCCESS)
  }
  agent {
    docker {
      image 'kambi/castle-engine-cloud-builds-tools:cge-unstable'
    }
  }
  stages {
    stage('Build Desktop') {
      steps {
        sh 'castle-engine package --os=win64 --cpu=x86_64 --verbose'
        sh 'castle-engine package --os=win32 --cpu=i386 --verbose'
        sh 'castle-engine package --os=linux --cpu=x86_64 --verbose'
      }
    }
    // TODO: Fix Jenkins + Docker to enable building
    // on Android with Heyzap and related (e.g. FB) SDKs.
    // stage('Build Mobile') {
    //   steps {
    //     sh 'castle-engine package --os=android --cpu=arm --verbose'
    //   }
    // }
  }
  post {
    success {
      archiveArtifacts artifacts: 'darkest_before_dawn-*.tar.gz,darkest_before_dawn-*.zip,darkest_before_dawn*.apk'
    }
    regression {
      mail to: 'michalis@castle-engine.io',
        subject: "[jenkins] Build started failing: ${currentBuild.fullDisplayName}",
        body: "See the build details on ${env.BUILD_URL}"
    }
    failure {
      mail to: 'michalis@castle-engine.io',
        subject: "[jenkins] Build failed: ${currentBuild.fullDisplayName}",
        body: "See the build details on ${env.BUILD_URL}"
    }
    fixed {
      mail to: 'michalis@castle-engine.io',
        subject: "[jenkins] Build is again successfull: ${currentBuild.fullDisplayName}",
        body: "See the build details on ${env.BUILD_URL}"
    }
  }
}
