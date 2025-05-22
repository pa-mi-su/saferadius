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
                            echo "🔨 Building and testing $svc"
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

                    // 🐳 Log in to Docker Hub using stored credentials
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                            docker info | grep Username || echo "⚠️ Docker login might have failed"
                        '''
                    }

                    // 🛠 Build and push Docker image for each microservice
                    services.each { svc ->
                        dir(svc) {
                            echo "📦 Building Docker image for $svc"
                            sh "docker build -t $REGISTRY/${svc}:${BRANCH_NAME} ."

                            echo "📤 Pushing Docker image for $svc to $REGISTRY"
                            sh "docker push $REGISTRY/${svc}:${BRANCH_NAME}"

                            // ✅ Confirm image exists locally
                            sh "docker images | grep ${svc}"
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

                    // 🧭 Update kubeconfig so kubectl/helm work with EKS
                    sh '''
                        aws eks --region us-east-1 update-kubeconfig --name saferadius
                    '''

                    // 🛳 Deploy application using Helm
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
            echo '❌ Pipeline failed.'
        }
    }
}
