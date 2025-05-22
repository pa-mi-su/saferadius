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

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Extract Branch Name') {
            steps {
                script {
                    // Safely get branch name even on detached HEAD
                    def branch = sh(
                        script: "git rev-parse --abbrev-ref HEAD",
                        returnStdout: true
                    ).trim()

                    if (branch == 'HEAD') {
                        branch = sh(
                            script: "git name-rev --name-only HEAD || echo unknown",
                            returnStdout: true
                        ).trim()
                    }

                    echo "📌 Branch detected: ${branch}"
                    env.CURRENT_BRANCH = branch
                }
            }
        }

        stage('Build & Test') {
            steps {
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']
                    for (svc in services) {
                        dir(svc) {
                            echo "🔨 Building ${svc}"
                            sh "mvn clean install -DskipTests=false"
                        }
                    }
                }
            }
        }

        stage('Docker Build & Push') {
            when {
                expression { env.CURRENT_BRANCH == 'main' || env.CURRENT_BRANCH == 'dev' }
            }
            steps {
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']
                    for (svc in services) {
                        dir(svc) {
                            echo "🐳 Building Docker image for ${svc}"
                            sh "docker build -t ${REGISTRY}/${DOCKERHUB_USERNAME}/${svc}:${env.CURRENT_BRANCH} ."
                            echo "📤 Pushing image to Docker Hub"
                            sh "docker push ${REGISTRY}/${DOCKERHUB_USERNAME}/${svc}:${env.CURRENT_BRANCH}"
                        }
                    }
                }
            }
        }

        stage('Helm Deploy to EKS') {
            when {
                expression { env.CURRENT_BRANCH == 'main' || env.CURRENT_BRANCH == 'dev' }
            }
            steps {
                script {
                    echo "🚀 Deploying to EKS using Helm for branch: ${env.CURRENT_BRANCH}"
                    sh """
                        helm upgrade --install ${HELM_RELEASE_NAME} ${HELM_CHART_DIR} \
                            --namespace ${NAMESPACE} \
                            --set image.tag=${env.CURRENT_BRANCH} \
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
