pipeline {
    agent any

    environment {
        REGISTRY = "docker.io"
        DOCKERHUB_USERNAME = "paumicsul"
        IMAGE_TAG = "${env.BRANCH_NAME}"
        HELM_RELEASE_NAME = "saferadius"
        HELM_CHART_DIR = "./helm"
        NAMESPACE = "default"
        KUBECONFIG = "/var/lib/jenkins/.kube/config"
        PATH = "/usr/local/bin:/var/lib/jenkins/.local/bin:$PATH"
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
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                        for (svc in services) {
                            dir(svc) {
                                def image = "${REGISTRY}/${DOCKERHUB_USERNAME}/${svc}:${IMAGE_TAG}"
                                echo "🐳 Building Docker image for ${svc}"
                                sh "docker build -t ${image} ."
                                sh "docker push ${image}"
                            }
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
                    echo "🚀 Deploying to EKS with Helm (branch: ${env.BRANCH_NAME})"

                    sh '''
                        echo "⛓ Updating kubeconfig"
                        aws eks update-kubeconfig \
                          --region us-east-1 \
                          --name saferadius \
                          --kubeconfig "$KUBECONFIG"

                        echo "📦 Running Helm upgrade"
                        helm upgrade --install "$HELM_RELEASE_NAME" "$HELM_CHART_DIR" \
                            --namespace "$NAMESPACE" \
                            --kubeconfig "$KUBECONFIG" \
                            --set image.tag="$IMAGE_TAG" \
                            --set image.registry="$REGISTRY" \
                            --set image.repository="$DOCKERHUB_USERNAME"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully."
        }
        failure {
            echo "❌ Pipeline failed. Check the logs above for details."
        }
    }
}
