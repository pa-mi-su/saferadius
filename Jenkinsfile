pipeline {
    agent any

    environment {
        REGISTRY = "docker.io"
        DOCKERHUB_USERNAME = "paumicsul"
        IMAGE_TAG = "latest"
        HELM_RELEASE_NAME = "saferadius"
        HELM_CHART_DIR = "./helm"
        NAMESPACE = "default"
    }

    stages {
        stage('Build & Test') {
            steps {
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']
                    for (svc in services) {
                        dir(svc) {
                            echo "🔨 Building and testing ${svc}"
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
                    for (svc in services) {
                        dir(svc) {
                            echo "🐳 Building Docker image for ${svc}"
                            sh "docker build -t ${REGISTRY}/${DOCKERHUB_USERNAME}/${svc}:${IMAGE_TAG} ."
                            echo "📤 Pushing image to Docker Hub"
                            sh "docker push ${REGISTRY}/${DOCKERHUB_USERNAME}/${svc}:${IMAGE_TAG}"
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
                    echo "🚀 Deploying with Helm"
                    sh """
                    helm upgrade --install ${HELM_RELEASE_NAME} ${HELM_CHART_DIR} \
                        --namespace ${NAMESPACE} \
                        --set image.tag=${IMAGE_TAG} \
                        --set image.registry=${REGISTRY} \
                        --set image.repository=${DOCKERHUB_USERNAME}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully."
        }
        failure {
            echo "❌ Pipeline failed."
        }
    }
}
