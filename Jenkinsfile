pipeline {
    agent any

    environment {
        REGISTRY = "docker.io"
        DOCKERHUB_USERNAME = "paumicsul"
        HELM_RELEASE_NAME = "saferadius"
        HELM_CHART_DIR = "./helm"
        NAMESPACE = "default"
        IMAGE_TAG = ""
    }

    stages {
        stage('Extract Branch Name') {
            steps {
                script {
                    def branch = env.BRANCH_NAME ?: sh(script: "git rev-parse --abbrev-ref HEAD || echo detached", returnStdout: true).trim()
                    if (branch == "HEAD" || branch == "detached") {
                        branch = sh(script: "git name-rev --name-only HEAD || echo unknown", returnStdout: true).trim()
                    }
                    echo "📌 Branch detected: ${branch}"
                    env.IMAGE_TAG = branch
                }
            }
        }

        stage('Build & Test') {
            steps {
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']
                    services.each { svc ->
                        dir(svc) {
                            echo "🔨 Building ${svc}"
                            sh "mvn clean install -DskipTests=false"
                        }
                    }
                }
            }
        }

        stage('Docker Login') {
            when {
                expression { env.IMAGE_TAG == 'main' || env.IMAGE_TAG == 'dev' }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin ${REGISTRY}'
                }
            }
        }

        stage('Docker Build & Push') {
            when {
                expression { env.IMAGE_TAG == 'main' || env.IMAGE_TAG == 'dev' }
            }
            steps {
                script {
                    def services = ['user-service', 'location-service', 'crime-service', 'api-gateway', 'discovery-server']
                    services.each { svc ->
                        dir(svc) {
                            def image = "${REGISTRY}/${DOCKERHUB_USERNAME}/${svc}:${env.IMAGE_TAG}"
                            echo "🐳 Building image: ${image}"
                            sh "docker build -t ${image} ."
                            sh "docker push ${image}"
                        }
                    }
                }
            }
        }

        stage('Helm Deploy to EKS') {
            when {
                expression { env.IMAGE_TAG == 'main' || env.IMAGE_TAG == 'dev' }
            }
            steps {
                script {
                    echo "📦 Deploying to EKS using Helm (branch: ${env.IMAGE_TAG})"
                    sh """
                        helm upgrade --install ${HELM_RELEASE_NAME} ${HELM_CHART_DIR} \
                          --namespace ${NAMESPACE} \
                          --set image.tag=${env.IMAGE_TAG} \
                          --set image.registry=${REGISTRY} \
                          --set image.repository=${DOCKERHUB_USERNAME}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully for branch: ${env.IMAGE_TAG}"
        }
        failure {
            echo "❌ Pipeline failed on branch: ${env.IMAGE_TAG}"
        }
    }
}
