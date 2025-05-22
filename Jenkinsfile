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
                echo '📥 Checking out source code...'
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                echo '🔨 Building and testing all microservices...'
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']
                    services.each { svc ->
                        dir(svc) {
                            echo "▶ Building: ${svc}"
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
                echo '🐳 Building and pushing Docker images to Docker Hub...'
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']

                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        '''
                    }

                    services.each { svc ->
                        dir(svc) {
                            echo "📦 Building Docker image for: ${svc}"
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
                echo '🚀 Deploying to EKS using Helm...'
                script {
                    def namespace = (env.BRANCH_NAME == 'main') ? PROD_NAMESPACE : STAGING_NAMESPACE

                    // Ensure kubeconfig is up to date
                    sh "aws eks --region us-east-1 update-kubeconfig --name saferadius"

                    // Dry-run and debug first
                    echo '🔍 Running Helm dry-run for validation...'
                    sh "helm upgrade --install saferadius ./helm -n ${namespace} --create-namespace --dry-run --debug"

                    // Actual deployment
                    echo '🚀 Running actual Helm deployment...'
                    sh "helm upgrade --install saferadius ./helm -n ${namespace} --create-namespace --debug"
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully.'
        }
        failure {
            echo '❌ Pipeline failed. Check the logs above for details.'
        }
    }
}
