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

        stage('Detect Branch Name') {
            steps {
                script {
                    def rawBranch = sh(script: 'git rev-parse --symbolic-full-name HEAD', returnStdout: true).trim()
                    def branchName = rawBranch.replaceFirst(/^refs\/heads\//, '')
                    echo "📌 Detected Git branch: ${branchName}"
                    env.BRANCH_NAME = branchName
                }
            }
        }

        stage('Build & Test') {
            steps {
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']
                    for (svc in services) {
                        dir(svc) {
                            echo "🔨 Building and testing ${svc}"
                            sh 'mvn clean install -DskipTests=false'
                        }
                    }
                }
            }
        }

        stage('Docker Build & Push') {
            when {
                expression { env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'dev' }
            }
            steps {
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']
                    for (svc in services) {
                        dir(svc) {
                            echo "🐳 Building Docker image for ${svc}"
                            sh "docker build -t ${REGISTRY}/${DOCKERHUB_USERNAME}/${svc}:${env.BRANCH_NAME} ."
                            echo "📤 Pushing Docker image"
                            sh "docker push ${REGISTRY}/${DOCKERHUB_USERNAME}/${svc}:${env.BRANCH_NAME}"
                        }
                    }
                }
            }
        }

        stage('Deploy to EKS via Helm') {
            when {
                expression { env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'dev' }
            }
            steps {
                script {
                    echo "🚀 Helm deploying to EKS for branch ${env.BRANCH_NAME}"
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
