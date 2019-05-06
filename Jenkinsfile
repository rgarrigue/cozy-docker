pipeline {

  agent {
    label 'docker'
  }

  stages {

    stage ('Get latest code') {
      steps {
        checkout scm
      }
    }

    stage ('Display versions') {
      steps {
        sh '''
          docker -v
        '''
      }
    }

    stage ('Docker build production image') {
      steps {
        sh '''
          docker build --tag org/stack:latest -f Docker.production .
        '''
      }
    }

    stage ('Docker build development image') {
      steps {
        sh '''
          docker build --tag org/stack:development -f Docker.development .
        '''
      }
    }

  }

}
