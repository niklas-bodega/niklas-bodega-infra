# niklas-bodega-infra

Infrastruktur för **Niklas Bodega**, ett vandrarhemsbokningssystem uppdelat i mikroservices. Det här repot innehåller Docker Compose (lokal körning) och Kubernetes-manifest.

Alla tjänsterepon (`user`, `booking`, `review-service`, `frontend`) ska ligga som syskonmappar till den här mappen:

```
niklas-bodega/
├── niklas-bodega-infra/   ← du är här
├── user/
├── booking/
├── review-service/
└── frontend/
```

Compose-filen bygger tjänsterna från `../user`, `../booking`, `../review-service` och `../frontend`.

## Vad varje tjänst gör

| Tjänst | Repo | Port | Databas | Ansvar |
|--------|------|------|---------|--------|
| **user-service** | `user` | 8084 | MySQL `db-user` (värdport 3308) | Registrering, inloggning, OAuth (Google/GitHub), JWT-cookie, användarprofil |
| **booking-service** | `booking` | 8083 | MySQL `db-booking` (värdport 3309) | Rumstyper, rum, tillgänglighet, skapa/ändra/avboka bokningar |
| **review-service** | `review-service` | 8086 | MySQL `db-review` (värdport 3310) | Recensioner, betyg per rumstyp, showcase på startsidan |
| **frontend** | `frontend` | 8087 | — | React-SPA (Vite + nginx). Visar rum, sök, bokning, recensioner och konto |

Varje backend har **egen MySQL-databas**. Det finns ingen gemensam databas mellan tjänsterna.

## Hur tjänsterna pratar med varandra

Frontend pratar **aldrig** med databaserna. Webbläsaren anropar backend-API:erna över HTTP (Axios, `withCredentials: true` så att JWT-cookien följer med).

Backend-tjänsterna pratar med varandra via Spring `RestClient` på det interna Docker-nätverket `bodega`.

```
Webbläsare
    │
    │  HTTP + cookie "jwt"
    ├──────────────────────► user-service:8084      /api/auth, /api/user
    ├──────────────────────► booking-service:8083   /api/bookings, /api/rooms
    └──────────────────────► review-service:8086    /api/review

user-service  ──GET /api/bookings/active──►  booking-service
                 (stopp för radering om användaren har aktiva bokningar)

booking-service ──GET /api/user──────────►  user-service
                 (kontrollera att användaren finns innan bokning skapas)

review-service ──GET /api/user───────────►  user-service
                 (hämta visningsnamn när en recension skapas)
```

### Autentisering

1. Användaren loggar in mot **user-service**.
2. User-service sätter en httpOnly-cookie `jwt` (samma `JWT_SECRET` i alla backends).
3. Booking- och review-service validerar tokenen lokalt — de anropar inte user-service för varje request.
4. Internt skickas JWT vidare i `Authorization`-headern när en tjänst behöver verifiera användaren.

### Interna adresser i Docker

Tjänsterna hittar varandra via Compose-servicenamn:

- `http://user-service:8084`
- `http://booking-service:8083`
- `http://review-service:8086`

Databaserna nås inuti nätverket som `db-user:3306`, `db-booking:3306` och `db-review:3306`.

Frontend byggs med publika API-URL:er (`VITE_*`). I lokal Docker är det värdmaskinens portar, t.ex. `http://localhost:8084`.

## Starta hela systemet

### Förutsättningar

- Docker Desktop (eller Docker Engine + Compose)
- Syskonmapparna `user`, `booking`, `review-service` och `frontend` cloned bredvid det här repot

### 1. Skapa det externa nätverket

Compose förväntar sig ett redan skapat nätverk `proxy-network` (används t.ex. mot en reverse proxy):

```bash
docker network create proxy-network
```

Hoppa över kommandot om nätverket redan finns.

### 2. Konfigurera miljövariabler

```bash
cp .env.example .env
```

Fyll i `.env`. För lokal körning räcker ungefär:

```env
DB_ROOT_PASSWORD=root_password_123
DB_USER=bodega_user
DB_PASSWORD=bodega_password_123
DB_USER_NAME=user_db
DB_BOOKING_NAME=booking_db
DB_REVIEW_NAME=review_db

JWT_SECRET=en_superhemlig_nyckel_som_ar_minst_32_tecken

USER_INTERNAL_ADDRESS=http://user-service:8084
BOOKING_INTERNAL_ADDRESS=http://booking-service:8083
REVIEW_INTERNAL_ADDRESS=http://review-service:8086

VITE_USER_API_URL=http://localhost:8084
VITE_BOOKING_API_URL=http://localhost:8083
VITE_REVIEW_API_URL=http://localhost:8086
```

OAuth-nycklar (`GOOGLECLIENTID`, `GITHUBCLIENTID` m.fl.) är valfria. Utan dem fungerar e-post/lösenord, men inte Google-/GitHub-inloggning.

### 3. Starta allt

Från den här mappen (`niklas-bodega-infra`):

```bash
docker compose up --build
```

Första gången tar bygget en stund (Maven + npm). När containrarna är uppe:

| Yta | URL |
|-----|-----|
| Frontend | http://localhost:8087 |
| User API | http://localhost:8084 |
| Booking API | http://localhost:8083 |
| Review API | http://localhost:8086 |

Stoppa med `Ctrl+C`, eller i bakgrunden:

```bash
docker compose up --build -d
docker compose down
```

Volymerna `db_user_data`, `db_booking_data` och `db_review_data` behåller data mellan omstarter. `docker compose down -v` tar bort databaserna också.

## Kubernetes

Mappen `k8s/` innehåller deployments, services och PVC:er för samma tjänster. Det är tänkt för klusterkörning (t.ex. minikube) och ersätter inte `docker compose up` för lokal utveckling.
