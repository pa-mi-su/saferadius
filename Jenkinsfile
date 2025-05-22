pipeline {
    agent any

    environment {
        REGISTRY = "docker.io/paumicsul"
        PROD_NAMESPACE = "saferadius-prod"
        STAGING_NAMESPACE = "saferadius-staging"
        MAVEN_OPTS = "-Dmaven.repo.local=.m2/repository"
    }

    options {
        skipDefaultCheckout true
        timestamps()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']
                    services.each { svc ->
                        dir(svc) {
                            sh "mvn clean install -DskipTests=false"
                        }
                    }
                }
            }
        }

        stage('Docker Build & Push') {
            when {
                anyOf {
                    branch 'main'
                    branch 'dev'
                }
            }
            steps {
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']

                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        '''
                    }

                    services.each { svc ->
                        dir(svc) {
                            sh "docker build -t $REGISTRY/${svc}:${BRANCH_NAME} ."
                            sh "docker push $REGISTRY/${svc}:${BRANCH_NAME}"
                        }
                    }
                }
            }
        }

        stage('Helm Deploy') {
            when {
                anyOf {
                    branch 'main'
                    branch 'dev'
                }
            }
            steps {
                script {
                    def namespace = (env.BRANCH_NAME == 'main') ? PROD_NAMESPACE : STAGING_NAMESPACE

                    sh '''
                        aws eks --region us-east-1 update-kubeconfig --name saferadius
                    '''

                    sh "helm upgrade --install saferadius ./helm -n ${namespace} --create-namespace"
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully.'
        }
        failure {
            echo '❌ Pipeline failed.'
        }
    }
}
