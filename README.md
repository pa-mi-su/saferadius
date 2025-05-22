# 🛡️ SafeRadius

**SafeRadius** is a production-ready Java Spring Boot microservices platform with centralized Helm/Kubernetes deployment. It features secure authentication, service discovery, and modular REST APIs — designed for cloud-native apps and rapid scaling.

---

## 🧰 What is Inside

- 🔐 `user-service` — JWT auth (register/login)
- 🌐 `api-gateway` — central entry point, routes traffic securely
- 🔍 `discovery-server` — Eureka service registry
- 📥 `location-service` — reverse-geocodes GPS coordinates
- 🚨 `crime-service` — queries crime stats by coordinates + radius
- ☸️ Central `helm/` folder — deploys everything

---

## 🗂️ Project Structure

```
saferadius/
├── user-service/
├── api-gateway/
├── discovery-server/
├── location-service/
├── crime-service/
├── helm/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── user-service.yaml
│       ├── api-gateway.yaml
│       └── ...
```

---

## 🧪 How to Use

### 1️⃣ Build All Microservices

```bash
mvn clean install
```

### 2️⃣ Build and Push Docker Images

```bash
docker build -t paumicsul/user-service ./user-service
docker push paumicsul/user-service

# Repeat for each service...
```

### 3️⃣ Deploy to Kubernetes with Helm

```bash
helm upgrade --install saferadius ./helm -n saferadius --create-namespace
```

---

## 🔐 Security

- JWT-based auth via `user-service`
- Gateway protects downstream APIs
- Secrets injected via Kubernetes
- PostgreSQL managed externally but used by services

---

## 📚 API Documentation

Swagger UI is enabled on each service:

```
http://<service-ip>/swagger-ui.html
```

Access locally using `kubectl port-forward` or expose via ingress.

---

## 🔀 Branching & Release Strategy

SafeRadius follows a GitFlow-inspired branching model:

| Branch         | Purpose                            |
|----------------|-------------------------------------|
| `main`         | Production-ready code, auto-deployed via CI/CD |
| `dev`          | Integration/testing branch for features |
| `feature/*`    | New feature branches (e.g., `feature/login-endpoint`) |
| `bugfix/*`     | Bug fixes (e.g., `bugfix/token-expiry`) |
| `release/*`    | Release stabilization branches (e.g., `release/1.0.0`) |

### CI/CD Pipeline Integration

- `main` branch → deploys to **production**
- `dev` branch → deploys to **staging**
- `feature/*` and `bugfix/*` → run build/test pipelines only

---

## 🤖 Future Additions

- Kafka support
- Observability stack (Prometheus + Grafana)
- Rate limiting & circuit breakers

---

## 📄 License

MIT — open for extension, sharing, and learning 🚀

---

## 🧭 What is SafeRadius?

**SafeRadius** helps users assess crime risk in their current location. A user clicks “Locate Me,” and the system:

1. Captures GPS coordinates
2. Reverse-geocodes the coordinates into a real address
3. Searches recent crime data within a 1, 2, or 5-mile radius
4. Returns a list of nearby crime incidents and their types

The system is built as a scalable, cloud-native platform with separate microservices for user management, geolocation, crime intelligence, and secure API routing.

---

## 🧱 Architecture Overview

```
[ User (Web / iOS) ]
        │
        ▼
 [ API Gateway ]
        │
 ┌──────┼─────────────┬────────────┐
 ▼      ▼             ▼            ▼
User  Location     Crime     Discovery
Svc     Svc        Svc         Svc
```

- **user-service**: handles registration, login, and JWT issuance
- **location-service**: takes lat/lng and returns the real address
- **crime-service**: searches nearby crime data and returns results
- **api-gateway**: central entrypoint for all services
- **discovery-server**: Eureka registry for service discovery

