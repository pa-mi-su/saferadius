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
                            sh "docker build -t ${REGISTRY}/${DOCKERHUB_USERNAME}/${svc}:${env.BRANCH_NAME} ."
                            sh "docker push ${REGISTRY}/${DOCKERHUB_USERNAME}/${svc}:${env.BRANCH_NAME}"
                        }
                    }
                }
            }
        }

        stage('Deploy to EKS via Helm') {
            when {
                anyOf {
                    branch 'main'
                    branch 'dev'
                }
            }
            steps {
                script {
                    echo "🚀 Deploying to EKS with Helm for branch: ${env.BRANCH_NAME}"
                    sh """
                        helm upgrade --install ${HELM_RELEASE_NAME} ${HELM_CHART_DIR} \
                            --namespace ${NAMESPACE} \
                            --set image.tag=${env.BRANCH_NAME} \
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
