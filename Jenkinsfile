@Library('socrata-pipeline-library@9.0.0')

def isPr = env.CHANGE_ID != null
def lastStage

pipeline {
    options {
        timeout(time: 100, unit: 'MINUTES')
        ansiColor('xterm')
        buildDiscarder(logRotator(numToKeepStr: '50'))
        disableConcurrentBuilds(abortPrevious: true)
    }
    parameters {
        string(name: 'BRANCH_SPECIFIER', defaultValue: 'origin/main', description: 'Use this branch for building the artifact')
    }
    agent { label params.AGENT }
    environment {
        SERVICE = 'exsoda'
        WEBHOOK_ID = 'WORKFLOW_INGRESS_NOTIFICATIONS'
        DOCKER_PATH='.'
    }
    stages {
        stage('Generate Leaked Secrets Report') {
        steps {
            script {
            lastStage = env.STAGE_NAME
            assert isInstalled('gitleaks'): 'gitleaks is missing.'
            String secretsReportFileName = 'gitleaks-report.json'
            String gitleaksCommand = getGitleaksCommand secretsReportFileName
            assert sh (script: gitleaksCommand, returnStatus: true) == 0: \
                'Attempt to run gitleaks failed.'
            echo "Generated report ${secretsReportFileName}."
            archiveArtifacts artifacts: secretsReportFileName, fingerprint: true
            }
        }
        }
        // For PRs, we run the tests
        stage('Test') {
            when {
                expression { isPr }
            }
            environment {
                SERVICE_VERSION='dsmapi_test'
            }
            steps {
                script {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'tyler-artifactory-write',
                            usernameVariable: 'ARTIFACTORY_USERNAME',
                            passwordVariable: 'ARTIFACTORY_PASSWORD'
                        )
                    ]) {
                        sh '''#!/bin/bash
                            mix deps.get
                        '''
                    }
                }
            }
        }
        // build and release off main
        stage ('Release') {
            when {
                not { expression { isPr } }
            }
            steps {
                script {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'tyler-artifactory-write',
                            usernameVariable: 'ARTIFACTORY_USERNAME',
                            passwordVariable: 'ARTIFACTORY_PASSWORD'
                        )
                    ]) {
                        sh '''#!/bin/bash
                            mix deps.get
                        '''
                    }
                }
            }
        }
    }
    post {
        failure {
            script {
                boolean buildingMain = env.JOB_NAME == "${service}/main"
                if (buildingMain) {
                teamsWorkflowMessage(
                    message: "[${currentBuild.fullDisplayName}](${env.BUILD_URL}) has failed in stage ${lastStage}",
                    workflowCredentialID: WEBHOOK_ID
                )
                }
            }
        }
    }
}
