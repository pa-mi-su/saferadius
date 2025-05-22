pipeline {
    agent any

    environment {
        REGISTRY = "docker.io"
        DOCKERHUB_USERNAME = "paumicsul"
        HELM_RELEASE_NAME = "saferadius"
        HELM_CHART_DIR = "./helm"
        NAMESPACE = "default"
    }

    stages {
        stage('Get Branch Name') {
            steps {
                script {
                    // Fallback-safe way to get the real branch name
                    def branch = sh(
                        script: '''
                            BRANCH_NAME=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)
                            echo $BRANCH_NAME
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "📌 Branch: ${branch}"
                    env.BRANCH_NAME = branch
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
                expression { env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'dev' }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin ${REGISTRY}'
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
                    services.each { svc ->
                        dir(svc) {
                            def image = "${REGISTRY}/${DOCKERHUB_USERNAME}/${svc}:${env.BRANCH_NAME}"
                            echo "🐳 Building and pushing ${image}"
                            sh "docker build -t ${image} ."
                            sh "docker push ${image}"
                        }
                    }
                }
            }
        }

        stage('Helm Deploy to EKS') {
            when {
                expression { env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'dev' }
            }
            steps {
                script {
                    echo "🚀 Helm deploy for ${env.BRANCH_NAME}"
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
            echo "✅ Finished successfully on branch: ${env.BRANCH_NAME}"
        }
        failure {
            echo "❌ Pipeline failed on branch: ${env.BRANCH_NAME}"
        }
    }
}
